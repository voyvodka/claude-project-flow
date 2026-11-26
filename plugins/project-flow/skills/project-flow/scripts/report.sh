#!/usr/bin/env bash
# Defect report: clone | prepare | preview | send. Flow: references/defect-report.md.
# Only the issue-link route exists: the pull-request route is withheld until its consent gate holds.
set -euo pipefail
export LC_ALL=C

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PLUGIN_ROOT=$(cd "$SCRIPT_DIR/../../.." && pwd)
MANIFEST="$PLUGIN_ROOT/.claude-plugin/plugin.json"

die() { echo "report: $*" >&2; exit 2; }
blocked() { echo "report: BLOCKED — $*" >&2; exit 3; }

manifest_field() {
  sed -n "s/^[[:space:]]*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$MANIFEST" | head -n1
}

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum | cut -c1-64
  else shasum -a 256 | cut -c1-64; fi
}

ISSUE_ROUTE="Route: issue link — you open it in your browser and submit it yourself; no diff is sent"

meta_get() { sed -n "s/^$2=//p" "$1/meta" | head -n1; }

# --- argument parsing -------------------------------------------------------------------
CMD=${1:-}; [ -n "$CMD" ] || die "usage: report.sh clone|prepare|preview|send ..."
shift || true
WORKDIR=""; PROJECT=""; ROUTE=""; DIGEST=""
while [ $# -gt 0 ]; do
  case "$1" in
    --workdir) WORKDIR=${2:-}; shift 2 ;;
    --project) PROJECT=${2:-}; shift 2 ;;
    --route)   ROUTE=${2:-}; shift 2 ;;
    --digest)  DIGEST=${2:-}; shift 2 ;;
    *) die "unknown argument: $1" ;;
  esac
done

need_workdir() {
  [ -n "$WORKDIR" ] && [ -f "$WORKDIR/meta" ] || die "--workdir must name a directory made by 'report.sh clone'"
  WORKDIR=$(cd "$WORKDIR" && pwd)
}
need_project() {
  [ -n "$PROJECT" ] && [ -d "$PROJECT" ] || die "--project must name the user's project directory (it is scanned, never sent)"
  PROJECT=$(cd "$PROJECT" && pwd)
}

# --- scrub ------------------------------------------------------------------------------
# Words that are tool vocabulary rather than identifying: every token in the plugin's own
# public source. A project file called README.md says nothing about the project.
vocabulary() {
  local plugin_path; plugin_path=$(meta_get "$WORKDIR" plugin)
  find "$WORKDIR/src/$plugin_path" -type f -print0 2>/dev/null | xargs -0 cat 2>/dev/null \
    | tr -cs 'A-Za-z0-9._-' '\n' | tr '[:upper:]' '[:lower:]' \
    | sed 's/^[._-]*//; s/[._-]*$//' \
    | awk 'length($0) { print; while (sub(/\.[^.]*$/, "")) print }' | sort -u
}

GENERIC_ACCOUNTS='^(root|admin|administrator|user|users|runner|ubuntu|guest|test|home|local|localhost|macbook|macbook-air|macbook-pro|imac|mac|pc|desktop|laptop|computer|owner|default)$'

personal_terms() {
  {
    id -un 2>/dev/null || true
    id -F 2>/dev/null || true
    hostname 2>/dev/null || true
    hostname -s 2>/dev/null || true
    scutil --get ComputerName 2>/dev/null || true
    scutil --get LocalHostName 2>/dev/null || true
    git config --global user.name 2>/dev/null || true
    git config --global user.email 2>/dev/null | sed 's/@.*//' || true
    git -C "$PROJECT" config user.name 2>/dev/null || true
    git -C "$PROJECT" config user.email 2>/dev/null | sed 's/@.*//' || true
  } | while IFS= read -r line; do
    [ -n "$line" ] || continue
    printf '%s\n' "$line"
    printf '%s\n' "$line" | tr -cs 'A-Za-z0-9._-' '\n'
  done | tr '[:upper:]' '[:lower:]' | sed 's/^[._-]*//; s/[._-]*$//' | awk 'length($0) >= 3' \
    | grep -Ev "$GENERIC_ACCOUNTS" | sort -u
}

project_terms() {
  {
    basename "$PROJECT"
    if git -C "$PROJECT" rev-parse --git-dir >/dev/null 2>&1; then
      git -C "$PROJECT" ls-files 2>/dev/null | head -n 20000
    else
      (cd "$PROJECT" && find . -maxdepth 5 \( -name .git -o -name node_modules \) -prune -o -print 2>/dev/null | head -n 20000)
    fi
  } | tr '/' '\n' | sed 's/^\.\{1,2\}$//' | while IFS= read -r part; do
    [ -n "$part" ] || continue
    printf '%s\n' "$part"
    case "$part" in *.*) printf '%s\n' "${part%.*}" ;; esac
  done | tr '[:upper:]' '[:lower:]' | awk 'length($0) >= 3' | sort -u
}

# Callers run this under `if !`, where set -e is ignored, so each step checks itself (fail closed).
scrub() {
  local payload=$1 tmp
  tmp=$(mktemp -d "${TMPDIR:-/tmp}/pf-scrub.XXXXXX" 2>/dev/null) && [ -d "$tmp" ] \
    || { echo "scrub could not run: no temporary directory (set TMPDIR to a writable directory)"; return 2; }
  local findings="$tmp/findings" err="$tmp/errors"
  { : > "$findings" && : > "$err"; } || { echo "scrub could not run: temporary directory is not writable"; rm -rf "$tmp"; return 2; }
  hits() { local rc; "$@"; rc=$?; [ $rc -le 1 ] || echo "grep failed ($rc)" >> "$err"; return 0; }

  local plugin_path login target
  plugin_path=$(meta_get "$WORKDIR" plugin)
  [ -n "$plugin_path" ] || echo "meta has no plugin path" >> "$err"
  login=$(sed -n 's/^Login: //p' "$WORKDIR/meta.route" 2>/dev/null | tr '[:upper:]' '[:lower:]')
  target=$(meta_get "$WORKDIR" target | tr '[:upper:]' '[:lower:]')

  # Diff context and removed lines are already public in the source repo; only added lines are new.
  awk '/^=== Diff ===$/{d=1; next} !d{print; next}
       /^diff --git /{h=1; next} /^@@/{h=0; next} h{next} /^\+/{print}' "$payload" > "$tmp/scan" \
    && [ -s "$tmp/scan" ] || echo "could not read the payload" >> "$err"
  awk '/^=== Diff ===$/{d=1; next} d' "$payload" > "$tmp/diff" || echo "could not read the diff" >> "$err"

  hits grep -Eno '/Users/[^/[:space:]]+|/home/[^/[:space:]]+|[A-Za-z]:\\+Users\\+[^\\[:space:]]*|/root/|/var/folders/|/private/(var|tmp)/|~/[^.[:space:]]' "$tmp/scan" > "$tmp/h1"
  sed 's/^/home path: line /' "$tmp/h1" >> "$findings"

  hits grep -Eno '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' "$tmp/scan" > "$tmp/h2"
  hits grep -Eiv '@(example\.(com|org|net)|users\.noreply\.github\.com)$' "$tmp/h2" > "$tmp/h2b"
  sed 's/^/e-mail address: line /' "$tmp/h2b" >> "$findings"

  hits grep -Eno 'gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]+|sk-ant-[A-Za-z0-9_-]+|sk-[A-Za-z0-9]{32,}|AKIA[0-9A-Z]{16}|xox[abpr]-[A-Za-z0-9-]+|-----BEGIN [A-Z ]*PRIVATE KEY' "$tmp/scan" > "$tmp/h3"
  sed 's/^\([0-9]*\):.*/secret-shaped string: line \1 (value withheld)/' "$tmp/h3" >> "$findings"

  # The sending account and target repo are public by design and named in the header lines.
  personal_terms > "$tmp/personal-all" || echo "could not list user and machine names" >> "$err"
  hits grep -Fvx -e "$login" -e "${target%%/*}" -e "${target#*/}" "$tmp/personal-all" > "$tmp/personal"
  # A user name can be part of the public login ("dana" in "dana-ops"); mask those strings first.
  awk -v a="$login" -v b="$target" '
    function mask(line, w,   i, out) { if (w == "") return line; out = ""
      while ((i = index(tolower(line), w)) > 0) { out = out substr(line, 1, i - 1) "_"; line = substr(line, i + length(w)) }
      return out line }
    { print mask(mask($0, b), a) }' "$tmp/scan" > "$tmp/scan-personal" || echo "could not mask the account name" >> "$err"
  if [ -s "$tmp/personal" ]; then
    hits grep -Fiwno -f "$tmp/personal" "$tmp/scan-personal" > "$tmp/h4"
    sed 's/^/user or machine name: line /' "$tmp/h4" >> "$findings"
  fi

  vocabulary > "$tmp/vocab" && [ -s "$tmp/vocab" ] || echo "could not read the plugin source in the workdir" >> "$err"
  project_terms > "$tmp/project-all" || echo "could not list the project's files" >> "$err"
  comm -23 "$tmp/project-all" "$tmp/vocab" > "$tmp/project" || echo "could not compare project names" >> "$err"
  if [ -s "$tmp/project" ]; then
    hits grep -Fiwno -f "$tmp/project" "$tmp/scan" > "$tmp/h5"
    sed 's/^/project name or file name: line /' "$tmp/h5" >> "$findings"
  fi

  awk '
    /^diff --git / { h=1; a=$3; b=$4; sub(/^a\//, "", a); sub(/^b\//, "", b); print a; print b; next }
    /^@@/ { h=0; next }
    h && /^(\+\+\+|---) / { p=substr($0, 5); if (p != "/dev/null") { sub(/^[ab]\//, "", p); print p }; next }
    h && /^(rename|copy) (from|to) / { print substr($0, index($0, $3)) }
  ' "$tmp/diff" | sort -u > "$tmp/paths" || echo "could not read the diff's paths" >> "$err"
  while IFS= read -r p; do
    case "$p" in
      "$plugin_path"/*) case "$p" in *..*) echo "path outside the plugin: $p" ;; esac ;;
      *) echo "path outside the plugin: $p" ;;
    esac
  done < "$tmp/paths" >> "$findings"
  if grep -Eq '^(GIT binary patch|Binary files )' "$tmp/diff"; then echo "binary change: not allowed in a report" >> "$findings"; fi

  local rc=0
  if [ -s "$err" ]; then sed 's/^/scrub could not run: /' "$err" | sort -u; rc=2
  elif [ -s "$findings" ]; then sort -u "$findings"; rc=1; fi
  rm -rf "$tmp"
  return $rc
}

# --- commands ---------------------------------------------------------------------------
cmd_clone() {
  local repo; repo=$(manifest_field repository)
  repo=${repo%/}; repo=${repo%.git}
  case "$repo" in https://github.com/*/*) ;; *) die "plugin.json repository is not a GitHub URL: $repo" ;; esac
  local source="$repo.git" target=${repo#https://github.com/}
  local w; w=$(mktemp -d "${TMPDIR:-/tmp}/pf-report.XXXXXX")
  git clone -q --template= "$source" "$w/src" || die "could not clone $source"
  # The background agent works in this clone and must not be able to push.
  git -C "$w/src" remote set-url --push origin "push-disabled-use-report-send"
  local base_branch; base_branch=$(git -C "$w/src" symbolic-ref --short HEAD)
  {
    echo "source=$source"
    echo "target=$target"
    echo "base=$(git -C "$w/src" rev-parse HEAD)"
    echo "base_branch=$base_branch"
    echo "plugin=plugins/$(manifest_field name)"
  } > "$w/meta"
  echo "$w"
}

field() { sed -n "s/^$1:[[:space:]]*//p" "$WORKDIR/fields" | head -n1; }

cmd_prepare() {
  need_workdir; need_project
  [ -f "$WORKDIR/fields" ] || die "write $WORKDIR/fields first (title, class, instruction, what-happened, proposed-change)"
  local k v
  for k in title class instruction what-happened proposed-change; do
    v=$(field "$k")
    [ -n "$v" ] || die "fields: '$k:' is missing or empty"
    [ "$(grep -c "^$k:" "$WORKDIR/fields")" = 1 ] || die "fields: '$k:' appears more than once"
    case "$v" in *===*|*'`'*'`'*'`'*) die "fields: '$k' may not contain '===' or code fences" ;; esac
    if [ "$k" = title ]; then [ ${#v} -le 80 ] || die "fields: title is longer than 80 characters"
    else [ ${#v} -le 500 ] || die "fields: '$k' is longer than 500 characters — keep it abstract"; fi
  done
  [ "$(grep -cv '^[[:space:]]*$' "$WORKDIR/fields")" = 5 ] || die "fields: only the five 'key: value' lines are allowed"

  local target; target=$(meta_get "$WORKDIR" target)
  [ -z "$ROUTE" ] || [ "$ROUTE" = issue ] || die "--route $ROUTE is not available in this release; the report is an issue link"
  ROUTE=issue

  local title; title=$(field title)
  local p="$WORKDIR/payload.txt"

  {
    echo "project-flow defect report"
    echo "Target: ${target:-none (sending disabled)}"
    echo "Base: $(meta_get "$WORKDIR" base_branch) @ $(meta_get "$WORKDIR" base | cut -c1-12)"
  } > "$p"

  echo "$ISSUE_ROUTE" >> "$p"

  {
    echo "Title: $title"
    echo
    echo "=== Body ==="
    echo "**Failure class:** $(field class)"
    echo
    echo "**Instruction involved:** $(field instruction)"
    echo
    echo "**What happened:** $(field what-happened)"
    echo
    echo "**Proposed change:** $(field proposed-change)"
    echo
    echo "_Sent from a project-flow install after its user saw this exact text. It carries no project files, names or paths._"
  } >> "$p"

  local findings
  if ! findings=$(scrub "$p"); then
    printf '%s\n' "$findings" >&2
    blocked "the payload names something personal or project-specific (listed above). Rewrite the fields or the change in abstract terms and run prepare again."
  fi
  echo "prepared: $p (route: $ROUTE). Run preview to show it."
}

payload_digest() { sha256 < "$WORKDIR/payload.txt" | cut -c1-16; }

checked_payload() {
  [ -f "$WORKDIR/payload.txt" ] || die "no payload — run prepare first"
  local findings
  if ! findings=$(scrub "$WORKDIR/payload.txt"); then
    printf '%s\n' "$findings" >&2
    blocked "the payload names something personal or project-specific (listed above); nothing was shown or sent."
  fi
}

cmd_preview() {
  need_workdir; need_project; checked_payload
  echo "----- BEGIN PREVIEW: this is exactly what will be sent -----"
  cat "$WORKDIR/payload.txt"
  echo "----- END PREVIEW -----"
  echo "Digest: $(payload_digest)"
}

urlencode() {
  local s c out="" i
  s=$(cat)
  for (( i=0; i<${#s}; i++ )); do
    c=${s:i:1}
    case "$c" in
      [A-Za-z0-9._~-]) out+="$c" ;;
      *) out+=$(printf '%s' "$c" | od -An -tx1 | tr -d ' \n' | sed 's/\(..\)/%\1/g' | tr 'a-f' 'A-F') ;;
    esac
  done
  printf '%s' "$out"
}

cmd_send() {
  need_workdir; need_project; checked_payload
  [ -n "$DIGEST" ] || die "--digest is required: the one printed by the preview the user approved"
  [ "$DIGEST" = "$(payload_digest)" ] || die "the payload changed since that preview (digest mismatch) — run preview again and show it to the user"

  local p="$WORKDIR/payload.txt" target; target=$(meta_get "$WORKDIR" target)
  [ -n "$target" ] || die "this workdir has no GitHub target; sending is disabled"
  local title; title=$(sed -n 's/^Title: //p' "$p" | head -n1)
  awk '/^=== Body ===$/{b=1; next} /^=== Diff ===$/{exit} b' "$p" > "$WORKDIR/body.md"

  grep -qxF "$ISSUE_ROUTE" "$p" || die "only the issue link is available in this release; run prepare again"
  echo "Open this link, check it and submit it yourself:"
  echo "https://github.com/$target/issues/new?title=$(printf '%s' "$title" | urlencode)&body=$(urlencode < "$WORKDIR/body.md")"
}

case "$CMD" in
  clone) cmd_clone ;;
  prepare) cmd_prepare ;;
  preview) cmd_preview ;;
  send) cmd_send ;;
  *) die "unknown command: $CMD" ;;
esac
