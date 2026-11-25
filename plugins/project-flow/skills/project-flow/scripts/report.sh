#!/usr/bin/env bash
# Defect report: clone | prepare | preview | send. Flow and consent rules: references/defect-report.md.
set -euo pipefail
export LC_ALL=C

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PLUGIN_ROOT=$(cd "$SCRIPT_DIR/../../.." && pwd)
MANIFEST="$PLUGIN_ROOT/.claude-plugin/plugin.json"

die() { echo "report: $*" >&2; exit 2; }
blocked() { echo "report: BLOCKED — $*" >&2; exit 3; }
broken() { echo "report: SCRUB FAILED — $* Nothing was shown or sent; rewording will not help." >&2; exit 4; }

manifest_field() {
  sed -n "s/^[[:space:]]*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$MANIFEST" | head -n1
}

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum | cut -c1-64
  else shasum -a 256 | cut -c1-64; fi
}

# User git config (noprefix, colour, diff drivers) would make send's rebuilt diff differ from the preview.
plain_git() {
  git -c diff.noprefix=false -c diff.mnemonicPrefix=false -c color.ui=false \
      -c core.hooksPath=/dev/null -c commit.gpgsign=false -c core.autocrlf=false "$@"
}
plain_diff() { plain_git -C "$1" diff --no-ext-diff --no-textconv --no-renames "${@:2}"; }

meta_get() { sed -n "s/^$1=//p" "$WORKDIR/meta" | head -n1; }
header() { sed -n "1,/^Title: /s/^$1: //p" "$WORKDIR/payload.txt" | head -n1; }

CMD=${1:-}; [ -n "$CMD" ] || die "usage: report.sh clone|prepare|preview|send ..."
shift || true
WORKDIR=""; PROJECT=""; PROJECT_GIVEN=""; ROUTE=""; DIGEST=""
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
  WORKDIR=$(cd "$WORKDIR" && pwd -P)
}
# The project is scanned, never sent. prepare records it so preview and send cannot scan a different one.
# Inside a git repository the whole repository is scanned, whichever directory was named.
need_project() {
  [ -n "$PROJECT" ] && [ -d "$PROJECT" ] || die "--project must name the user's project directory"
  PROJECT=$(cd "$PROJECT" && pwd -P)
  PROJECT_GIVEN=$PROJECT
  local top; top=$(git -C "$PROJECT" rev-parse --show-toplevel 2>/dev/null) && [ -n "$top" ] && PROJECT=$(cd "$top" && pwd -P)
  if [ "$1" = record ]; then printf '%s\n' "$PROJECT" > "$WORKDIR/project"
  else [ "$PROJECT" = "$(cat "$WORKDIR/project" 2>/dev/null)" ] || die "--project differs from the one prepare scanned; run prepare again"; fi
}

# --- scrub ------------------------------------------------------------------------------
lower() { tr '[:upper:]' '[:lower:]'; }
squash() { lower | tr -cd 'a-z0-9\n'; }

# Tool vocabulary is read from the base commit, not the working tree: a name the fix adds must not
# whitelist itself.
vocabulary() {
  { plain_git -C "$WORKDIR/src" archive --format=tar "$(meta_get base)" -- "$(meta_get plugin)" | tar -xOf -
    plain_git -C "$WORKDIR/src" ls-tree -r --name-only "$(meta_get base)" -- "$(meta_get plugin)" | tr '/' '\n'
  } \
    | tr -cs 'A-Za-z0-9._-' '\n' | lower | sed 's/^[._-]*//; s/[._-]*$//' \
    | awk 'length($0) { print; n = split($0, part, /[-_.]+/); for (i = 1; i <= n; i++) print part[i]
                        while (sub(/\.[^.]*$/, "")) print }' | sort -u
}

GENERIC_ACCOUNTS='^(root|admin|administrator|user|users|runner|ubuntu|guest|test|home|local|localhost|macbook|macbook-air|macbook-pro|imac|mac|pc|desktop|laptop|computer|owner|default)$'

personal_terms() {
  {
    id -un 2>/dev/null || true
    id -F 2>/dev/null || true
    hostname 2>/dev/null || true
    scutil --get ComputerName 2>/dev/null || true
    scutil --get LocalHostName 2>/dev/null || true
    git config --global user.name 2>/dev/null || true
    git config --global user.email 2>/dev/null || true
    git -C "$PROJECT" config user.name 2>/dev/null || true
    git -C "$PROJECT" config user.email 2>/dev/null || true
  } | awk '{ print; n = split($0, w, /[^A-Za-z0-9._-]+|@/); for (i = 1; i <= n; i++) print w[i]
             n = split($0, w, /[^A-Za-z0-9]+/); for (i = 1; i <= n; i++) if (length(w[i]) >= 4) print w[i] }' \
    | lower | sed 's/^[._-]*//; s/[._-]*$//' | awk 'length($0) >= 3' \
    | { grep -Ev "$GENERIC_ACCOUNTS" || true; } | sort -u
}

project_terms() {
  {
    basename "$PROJECT"
    basename "$(dirname "$PROJECT")"
    basename "$PROJECT_GIVEN"
    basename "$(dirname "$PROJECT_GIVEN")"
    git -C "$PROJECT" remote -v 2>/dev/null | awk '{ print $2 }' | tr ':/' '\n' | sed 's/\.git$//'
    if git -C "$PROJECT" rev-parse --git-dir >/dev/null 2>&1; then
      # quotePath=false: names outside ASCII would otherwise come out as octal escapes.
      git -C "$PROJECT" -c core.quotePath=false ls-files -z --cached --others --exclude-standard 2>/dev/null \
        | tr '\0' '\n' | grep -Ev '(^|/)pf-report\.[^/]*/'
    else
      (cd "$PROJECT" && find . \( -name .git -o -name node_modules -o -name 'pf-report.*' \) -prune -o -print 2>/dev/null)
    fi
  } | tr '/' '\n' | awk 'length($0) && $0 != "." && $0 != ".."' \
    | sed -E 'p; s/([a-z0-9])([A-Z])/\1 \2/g; s/([A-Z]+)([A-Z][a-z])/\1 \2/g' | awk '
      { print; s = $0
        while (sub(/\.[^.]*$/, "", s)) print s
        n = split($0, part, /[-_. ]+/); if (n > 1) for (i = 1; i <= n; i++) if (length(part[i]) >= 4) print part[i] }' \
    | lower | awk 'length($0) >= 3' | sort -u
}

# Lines before "Title:" are generated by prepare; each must match its fixed shape exactly, so they
# can carry the public account and target without being scanned as free text.
check_header() {
  awk -v target="$(meta_get target)" -v base="$(meta_get base)" '
    /^Title: / { exit }
    NR == 1 { if ($0 != "project-flow defect report") bad(); next }
    /^Target: / { if ($0 != "Target: " target) bad(); next }
    /^Base: / { if ($0 !~ /^Base: [A-Za-z0-9._\/-]+ @ [0-9a-f]+$/ || $NF != base) bad(); next }
    /^Route: / { if ($0 != "Route: pull request from a fork under the account below (public)" &&
                     $0 != "Route: pull request from a branch on " target ", opened by the account below (public)" &&
                     $0 != "Route: issue link that you open and submit yourself (no diff is sent)") bad(); next }
    /^Account: / { if ($0 !~ /^Account: [A-Za-z0-9-]+ \(GitHub id [0-9]+\)$/) bad(); acct = $2; id = $5; sub(/\)$/, "", id); next }
    /^Commit: / { if ($0 != "Commit: author and committer " acct " <" id "+" acct "@users.noreply.github.com>, date in UTC, message = title") bad(); next }
    /^Branch: / { if ($0 !~ /^Branch: report\/[a-z0-9-]+$/) bad(); next }
    { bad() }
    function bad() { print "header line " NR " is not in the form prepare writes"; }
  ' "$1"
}

# Callers run this under `if !`, where set -e is ignored, so each step checks itself (fail closed).
scrub() {
  local payload=$1 tmp
  tmp=$(mktemp -d "${TMPDIR:-/tmp}/pf-scrub.XXXXXX" 2>/dev/null) && [ -d "$tmp" ] \
    || { echo "no temporary directory (set TMPDIR to a writable directory)"; return 2; }
  local findings="$tmp/findings" err="$tmp/errors"
  { : > "$findings" && : > "$err"; } || { echo "temporary directory is not writable"; rm -rf "$tmp"; return 2; }
  hits() { local rc; "$@"; rc=$?; [ $rc -le 1 ] || echo "grep failed ($rc)" >> "$err"; return 0; }
  ok() { "$@" || echo "step failed: $*" >> "$err"; }

  local plugin_path; plugin_path=$(meta_get plugin)
  [ -n "$plugin_path" ] && [ -n "$(meta_get base)" ] || echo "meta is incomplete" >> "$err"

  ok check_header "$payload" >> "$findings"
  awk '/^=== Diff ===$/{d=1; next} d' "$payload" > "$tmp/diff" || echo "could not read the diff" >> "$err"
  awk '
    /^diff --git / { h=1; a=$3; b=$4; sub(/^a\//, "", a); sub(/^b\//, "", b); print a; print b; next }
    /^@@/ { h=0; next }
    h && /^(\+\+\+|---) / { p=substr($0, 5); if (p != "/dev/null") { sub(/^[ab]\//, "", p); print p }; next }
    h && /^(rename|copy) (from|to) / { print substr($0, index($0, $3)) }
  ' "$tmp/diff" | sort -u > "$tmp/paths" || echo "could not read the diff's paths" >> "$err"

  # Free text that leaves: title, branch, body, the diff's file paths and added lines. Diff context
  # and removed lines are already public in the source repository.
  { awk '/^Title: /{t=1} /^Branch: report\//{print substr($0, 16); next} t && !/^=== Diff ===$/{print} /^=== Diff ===$/{exit}' "$payload"
    sed 's/^/path: /' "$tmp/paths"
    awk '/^=== Diff ===$/{d=1; next} !d{next} /^diff --git /{h=1; next} /^@@/{h=0; next} h{next} /^\+/{print}' "$payload"
  } > "$tmp/scan" && [ -s "$tmp/scan" ] || echo "could not read the payload" >> "$err"
  squash < "$tmp/scan" > "$tmp/scan-squashed" || echo "could not normalise the payload" >> "$err"

  hits grep -Eino '/users/[^/[:space:]]+|/home/[^/[:space:]]+|(^|[^a-z0-9])users\\+[^\\[:space:]]+|%2f(users|home)%2f|(^|[^a-z0-9])-(users|home)-[^-[:space:]]+|/root/|/var/folders/|/private/(var|tmp)/|~[a-z0-9._-]*/' "$tmp/scan" > "$tmp/h1"
  sed 's/^/home path: line /' "$tmp/h1" >> "$findings"

  hits grep -Eno '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' "$tmp/scan" > "$tmp/h2"
  hits grep -Eiv '@(example\.(com|org|net)|users\.noreply\.github\.com)$' "$tmp/h2" > "$tmp/h2b"
  sed 's/^/e-mail address: line /' "$tmp/h2b" >> "$findings"

  hits grep -Eno 'gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]+|glpat-[A-Za-z0-9_-]{16,}|sk-ant-[A-Za-z0-9_-]+|sk-[A-Za-z0-9_-]{32,}|[sr]k_(live|test)_[A-Za-z0-9]{16,}|AKIA[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{30,}|npm_[A-Za-z0-9]{30,}|xox[abpr]-[A-Za-z0-9-]+|eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}|-----BEGIN [A-Z ]*PRIVATE KEY' "$tmp/scan" > "$tmp/h3"
  sed 's/^\([0-9]*\):.*/secret-shaped string: line \1 (value withheld)/' "$tmp/h3" >> "$findings"

  hits grep -Eno '([0-9]{1,3}\.){3}[0-9]{1,3}' "$tmp/scan" > "$tmp/h6"
  hits grep -Ev ':(127\.0\.0\.1|0\.0\.0\.0|192\.0\.2\.[0-9]+|198\.51\.100\.[0-9]+|203\.0\.113\.[0-9]+)$' "$tmp/h6" > "$tmp/h6b"
  sed 's/^/IP address: line /' "$tmp/h6b" >> "$findings"
  hits grep -Eino '[a-z0-9-]+\.(local|internal|lan|corp|intranet|home\.arpa)([^a-z0-9-]|$)' "$tmp/scan" > "$tmp/h7"
  sed 's/^/internal host name: line /' "$tmp/h7" >> "$findings"

  # Names match as whole words and, when longer, with separators removed (spaced or joined spellings).
  vocabulary > "$tmp/vocab" && [ -s "$tmp/vocab" ] || echo "could not read the plugin source at the base commit" >> "$err"
  squash < "$tmp/vocab" | sort -u > "$tmp/vocab-squashed"
  personal_terms > "$tmp/personal-all" || echo "could not list user and machine names" >> "$err"
  comm -23 "$tmp/personal-all" "$tmp/vocab" > "$tmp/personal" || echo "could not compare user and machine names" >> "$err"
  project_terms > "$tmp/project-all" || echo "could not list the project's files" >> "$err"
  comm -23 "$tmp/project-all" "$tmp/vocab" > "$tmp/project" || echo "could not compare project names" >> "$err"
  local kind list
  for kind in personal project; do
    list="$tmp/$kind"
    [ "$kind" = personal ] && label="user or machine name" || label="project name or file name"
    if [ -s "$list" ]; then
      hits grep -Fiwno -f "$list" "$tmp/scan" > "$tmp/w-$kind"
      sed "s/^/$label: line /" "$tmp/w-$kind" >> "$findings"
      squash < "$list" | awk 'length($0) >= 6' | sort -u | comm -23 - "$tmp/vocab-squashed" > "$list-squashed"
      if [ -s "$list-squashed" ]; then
        hits grep -Fno -f "$list-squashed" "$tmp/scan-squashed" > "$tmp/s-$kind"
        sed "s/^/$label (run together): line /" "$tmp/s-$kind" >> "$findings"
      fi
    fi
  done

  while IFS= read -r p; do
    case "$p" in
      "$plugin_path"/*) ;;
      *) echo "path outside the plugin: $p"; continue ;;
    esac
    case "$p" in *..*|*[!A-Za-z0-9._/-]*) echo "path with unexpected characters: $p" ;; esac
  done < "$tmp/paths" >> "$findings"
  # The hook compares the payload with the transcript's JSON text, which escapes control characters.
  if [ -n "$(tr -d '\t\n\040-\176\200-\377' < "$payload")" ]; then echo "control character (only tab is allowed)" >> "$findings"; fi
  if grep -Eq '^(GIT binary patch|Binary files )' "$tmp/diff"; then echo "binary change: not allowed in a report" >> "$findings"; fi

  local rc=0
  if [ -s "$err" ]; then sort -u "$err"; rc=2
  elif [ -s "$findings" ]; then sort -u "$findings"; rc=1; fi
  rm -rf "$tmp"
  return $rc
}

# A preview longer than one tool output would reach the user cut short.
MAX_PAYLOAD=20000
check_size() {
  local n; n=$(wc -c < "$WORKDIR/payload.txt" | tr -d ' ')
  [ "$n" -le $MAX_PAYLOAD ] || die "the payload is $n bytes; a preview must fit in $MAX_PAYLOAD. Make the change smaller or split it into separate reports."
}

run_scrub() {
  local out rc=0
  out=$(scrub "$WORKDIR/payload.txt") || rc=$?
  [ $rc = 0 ] && return 0
  printf '%s\n' "$out" >&2
  [ $rc = 1 ] || broken "the privacy scrub could not run (listed above)."
  blocked "$1"
}

# --- commands ---------------------------------------------------------------------------
cmd_clone() {
  local repo; repo=$(manifest_field repository)
  repo=${repo%/}; repo=${repo%.git}
  case "$repo" in https://github.com/*/*) ;; *) die "plugin.json repository is not a GitHub URL: $repo" ;; esac
  local source="$repo.git" target=${repo#https://github.com/}
  local w; w=$(mktemp -d "${TMPDIR:-/tmp}/pf-report.XXXXXX")
  git clone -q --template= "$source" "$w/src" || die "could not clone $source"
  # The background agent works in this clone; push URLs are rewritten and a pre-push hook refuses.
  local prefix
  for prefix in https:// http:// ssh:// git@ git:// file:// /; do
    git -C "$w/src" config --add url."push-disabled-use-report-send:".pushInsteadOf "$prefix"
  done
  mkdir -p "$w/src/.git/hooks"
  printf '#!/bin/sh\necho "pushing from a report clone is disabled; report.sh send pushes" >&2\nexit 1\n' > "$w/src/.git/hooks/pre-push"
  chmod +x "$w/src/.git/hooks/pre-push"
  {
    echo "source=$source"
    echo "target=$target"
    echo "base=$(git -C "$w/src" rev-parse HEAD)"
    echo "base_branch=$(git -C "$w/src" symbolic-ref --short HEAD)"
    echo "plugin=plugins/$(manifest_field name)"
  } > "$w/meta"
  echo "$w"
}

field() { sed -n "s/^$1:[[:space:]]*//p" "$WORKDIR/fields" | head -n1; }

cmd_prepare() {
  need_workdir; need_project record
  rm -f "$WORKDIR/previewed"
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

  local target; target=$(meta_get target)
  if [ -z "$ROUTE" ]; then
    if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then ROUTE="pr"; else ROUTE="issue"; fi
  fi
  case "$ROUTE" in pr|issue) ;; *) die "--route is pr or issue" ;; esac

  local title; title=$(field title)
  local slug; slug=$(printf '%s' "$title" | lower | tr -cs 'a-z0-9' '-' | sed 's/^-*//; s/-*$//' | cut -c1-40 | sed 's/-*$//')
  local p="$WORKDIR/payload.txt" diff=""
  {
    echo "project-flow defect report"
    echo "Target: $target"
    echo "Base: $(meta_get base_branch) @ $(meta_get base)"
  } > "$p"

  if [ "$ROUTE" = pr ]; then
    plain_git -C "$WORKDIR/src" add -A
    diff=$(plain_diff "$WORKDIR/src" --cached "$(meta_get base)")
    [ -n "$diff" ] || die "no change in $WORKDIR/src — make the fix there, or use --route issue for a finding with no change yet"
    local who; who=$(gh api user --jq '.login + " " + (.id|tostring)') || die "gh could not read the signed-in account"
    local login=${who% *} uid=${who#* }
    if [ "$(gh api "repos/$target" --jq '.permissions.push' 2>/dev/null || echo false)" = true ]; then
      echo "Route: pull request from a branch on $target, opened by the account below (public)"
    else
      echo "Route: pull request from a fork under the account below (public)"
    fi >> "$p"
    {
      echo "Account: $login (GitHub id $uid)"
      echo "Commit: author and committer $login <$uid+$login@users.noreply.github.com>, date in UTC, message = title"
      echo "Branch: report/$slug"
    } >> "$p"
  else
    echo "Route: issue link that you open and submit yourself (no diff is sent)" >> "$p"
  fi

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
    echo "_Sent from a project-flow install after its user saw this exact text$( [ "$ROUTE" = pr ] && echo ' and diff'). It carries no project files, names or paths._"
  } >> "$p"
  [ "$ROUTE" = issue ] || { echo "=== Diff ==="; printf '%s\n' "$diff"; } >> "$p"

  check_size
  run_scrub "the payload names something personal or project-specific (listed above). Rewrite the fields or the change in more general terms and run prepare again."
  echo "prepared: $p (route: $ROUTE). Run preview to show it."
}

payload_digest() { sha256 < "$WORKDIR/payload.txt" | cut -c1-16; }

cmd_preview() {
  need_workdir; need_project check
  [ -f "$WORKDIR/payload.txt" ] || die "no payload — run prepare first"
  check_size
  run_scrub "the payload names something personal or project-specific (listed above); nothing was shown or sent."
  local d; d=$(payload_digest)
  rm -f "$WORKDIR/consent" "$WORKDIR/consent-refused"
  printf '%s\n' "$d" > "$WORKDIR/previewed"
  echo "----- BEGIN PREVIEW: this is exactly what will be sent -----"
  cat "$WORKDIR/payload.txt"
  echo "----- END PREVIEW -----"
  echo "Digest: $d"
  echo "Workdir: $WORKDIR"
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
  need_workdir; need_project check
  [ -f "$WORKDIR/payload.txt" ] || die "no payload — run prepare first"
  [ -n "$DIGEST" ] || die "--digest is required: the one printed by the preview the user approved"
  [ -f "$WORKDIR/previewed" ] || die "this payload was never previewed — run preview and show it to the user"
  [ "$DIGEST" = "$(cat "$WORKDIR/previewed")" ] && [ "$DIGEST" = "$(payload_digest)" ] \
    || die "the payload is not the one last previewed (digest mismatch) — run preview again and show it to the user"
  run_scrub "the payload names something personal or project-specific (listed above); nothing was sent."

  local p="$WORKDIR/payload.txt" target route title
  target=$(header Target); route=$(header Route); title=$(sed -n 's/^Title: //p' "$p" | head -n1)
  awk '/^=== Body ===$/{b=1; next} /^=== Diff ===$/{exit} b' "$p" > "$WORKDIR/body.md"

  # "<digest> <epoch>", written by hooks/report-guard.sh when the user typed a message right after a
  # reply holding this preview, and removed by the hook at the next prompt.
  if [ "$route" != "issue link that you open and submit yourself (no diff is sent)" ]; then
    if [ ! -f "$WORKDIR/consent" ]; then
      [ -f "$WORKDIR/consent-refused" ] \
        && die "the user's reply was not recorded as consent: $(head -n1 "$WORKDIR/consent-refused"). Run preview again."
      die "no reply from the user is recorded since this preview. End the reply with the preview and the yes/no question; send only after the user answers yes."
    fi
    local c_digest c_time age
    read -r c_digest c_time < "$WORKDIR/consent" || true
    rm -f "$WORKDIR/consent"
    case "$c_time" in ''|*[!0-9]*) die "the consent record is malformed; run preview again" ;; esac
    [ "$c_digest" = "$DIGEST" ] || die "the recorded reply is for another preview; run preview again"
    age=$(( $(date +%s) - c_time ))
    [ "$age" -ge 0 ] && [ "$age" -le 3600 ] || die "the recorded reply is more than an hour old; run preview again"
  fi

  case "$route" in
    "issue link"*)
      echo "Open this link, check it and submit it yourself:"
      echo "https://github.com/$target/issues/new?title=$(printf '%s' "$title" | urlencode)&body=$(urlencode < "$WORKDIR/body.md")"
      return 0 ;;
  esac

  local source; source=$(meta_get source)
  [ "$source" = "https://github.com/$target.git" ] || die "source and target disagree; refusing to send"
  local account login uid base base_branch branch
  account=$(header Account); login=${account%% *}; uid=${account##* }; uid=${uid%)}
  base=$(header Base); base_branch=${base%% @ *}; base=${base##* @ }
  branch=$(header Branch)
  local now; now=$(gh api user --jq .login) || die "gh is not signed in"
  [ "$now" = "$login" ] || die "the signed-in GitHub account is not the one in the preview; run prepare and preview again"

  # Rebuilt from the previewed diff, never from the agent's working tree.
  awk '/^=== Diff ===$/{d=1; next} d' "$p" > "$WORKDIR/send.patch"
  rm -rf "$WORKDIR/send"
  git clone -q --template= "$source" "$WORKDIR/send"
  plain_git -C "$WORKDIR/send" checkout -q -b "$branch" "$base"
  plain_git -C "$WORKDIR/send" apply --index "$WORKDIR/send.patch" || die "the previewed diff does not apply to $base"
  local email="$uid+$login@users.noreply.github.com" date; date=$(date -u +%Y-%m-%dT%H:%M:%S+0000)
  GIT_AUTHOR_NAME="$login" GIT_AUTHOR_EMAIL="$email" GIT_AUTHOR_DATE="$date" \
  GIT_COMMITTER_NAME="$login" GIT_COMMITTER_EMAIL="$email" GIT_COMMITTER_DATE="$date" \
    plain_git -C "$WORKDIR/send" commit -q --no-verify -m "$title"
  plain_diff "$WORKDIR/send" "$base" HEAD > "$WORKDIR/sent.diff"
  cmp -s "$WORKDIR/sent.diff" "$WORKDIR/send.patch" || die "the commit differs from the previewed diff; nothing was sent"

  local remote_url head_owner repo_name=${target#*/}
  case "$route" in
    "pull request from a branch on"*) remote_url=$source; head_owner=${target%%/*} ;;
    *)
      gh repo fork "$target" --clone=false --default-branch-only >/dev/null 2>&1 || true
      [ "$(gh repo view "$login/$repo_name" --json parent --jq '.parent.owner.login + "/" + .parent.name' 2>/dev/null)" = "$target" ] \
        || die "$login/$repo_name is not a fork of $target; nothing was pushed"
      remote_url="https://github.com/$login/$repo_name.git"; head_owner=$login ;;
  esac
  plain_git -C "$WORKDIR/send" -c credential.helper= -c 'credential.helper=!gh auth git-credential' \
    push -q "$remote_url" "HEAD:refs/heads/$branch" || die "push to $remote_url failed"
  gh pr create --repo "$target" --base "$base_branch" --head "$head_owner:$branch" \
    --title "$title" --body-file "$WORKDIR/body.md"
}

case "$CMD" in
  clone) cmd_clone ;;
  prepare) cmd_prepare ;;
  preview) cmd_preview ;;
  send) cmd_send ;;
  *) die "unknown command: $CMD" ;;
esac
