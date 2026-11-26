#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034  # check() evaluates its condition strings later
# No network: github.com URLs resolve to local bare repos via a private git config, and gh is a stub.
# Every name, path and address below is invented.
set -uo pipefail
export LC_ALL=C
ROOT=$(cd "$(dirname "$0")/.." && pwd)
PLUGIN="$ROOT/plugins/project-flow"
REPORT="$PLUGIN/skills/project-flow/scripts/report.sh"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "ok   $1"; }
bad() { fail=$((fail+1)); echo "FAIL $1"; }
check() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }

export HOME="$T/home"; mkdir -p "$HOME"
export GIT_CONFIG_GLOBAL="$T/gitconfig" GIT_CONFIG_NOSYSTEM=1 TMPDIR="$T/tmp"; mkdir -p "$TMPDIR"
git config --global user.name "Dana Quillfeather"
git config --global user.email "dana.quillfeather@mailbox.test"
git config --global init.defaultBranch main
git config --global url."file://$T/gh/".insteadOf "https://github.com/"

mkdir -p "$T/seed/plugins" && cp -R "$PLUGIN" "$T/seed/plugins/project-flow"
rm -rf "$T/seed/plugins/project-flow/evals/results"
git -C "$T/seed" init -q && git -C "$T/seed" add -A && git -C "$T/seed" commit -qm seed
mkdir -p "$T/gh/voyvodka" "$T/gh/tester"
git clone -q --bare "$T/seed" "$T/gh/voyvodka/claude-project-flow.git"

mkdir -p "$T/bin"
cat > "$T/bin/gh" <<'GH'
#!/usr/bin/env bash
echo "gh $*" >> "$GH_LOG"
case "$1 $2" in
  "auth status") [ "${GH_AUTHED:-1}" = 1 ] ;;
  "api user") [[ "$*" == *"(.id"* ]] && echo "${GH_LOGIN:-tester} 4242" || echo "${GH_LOGIN:-tester}" ;;
  "api repos/"*) echo "${PUSH_PERM:-false}" ;;
  "repo fork") git clone -q --bare "$GH_ROOT/voyvodka/claude-project-flow.git" "$GH_ROOT/tester/claude-project-flow.git" 2>/dev/null; true ;;
  "repo view") [ -d "$GH_ROOT/tester/claude-project-flow.git" ] ;;
  "pr create") shift 2; while [ $# -gt 0 ]; do case "$1" in --body-file) cp "$2" "$GH_LOG.body"; shift 2;; --title) echo "$2" > "$GH_LOG.title"; shift 2;; --head) echo "$2" > "$GH_LOG.head"; shift 2;; *) shift;; esac; done; echo "https://github.com/voyvodka/claude-project-flow/pull/999" ;;
  "auth git-credential") exit 0 ;;
  *) exit 1 ;;
esac
GH
chmod +x "$T/bin/gh"
export PATH="$T/bin:$PATH" GH_LOG="$T/gh.log" GH_ROOT="$T/gh"
: > "$GH_LOG"

P="$T/work/harbor-ledger"; mkdir -p "$P/src"
echo x > "$P/src/tidewatch_billing.py"; echo x > "$P/README.md"
git -C "$P" init -q && git -C "$P" add -A && git -C "$P" commit -qm init

FIELDS_OK='title: Gate question skipped after a resumed phase
class: never fires
instruction: references/phase-5-build.md, increment close
what-happened: The increment closed without the tool-defect question because the step sits after the state update.
proposed-change: Move the question before the state update so it is reached on every close.'

new_workdir() {
  W=$("$REPORT" clone) || { bad "clone"; return 1; }
  printf '%s\n' "$FIELDS_OK" > "$W/fields"
  printf '\n<!-- clarified -->\n' >> "$W/src/plugins/project-flow/skills/project-flow/references/phase-5-build.md"
}

new_workdir
check "clone disables push in the agent's working copy" \
  '[ "$(git -C "$W/src" remote get-url --push origin)" = push-disabled-use-report-send ]'

"$REPORT" prepare --workdir "$W" --project "$P" >/dev/null 2>"$T/err"; rc=$?
check "clean report prepares (rc=$rc)" '[ $rc = 0 ]'

scrub_case() { # name, field-line-replacement, expected finding text
  new_workdir
  printf '%s\n' "$FIELDS_OK" | sed "s|^what-happened:.*|what-happened: $2|" > "$W/fields"
  "$REPORT" prepare --workdir "$W" --project "$P" >/dev/null 2>"$T/err"; rc=$?
  want=$3
  check "scrub blocks $1 (rc=$rc)" '[ $rc = 3 ] && grep -q "$want" "$T/err"'
}
scrub_case "macOS home path"      "It read /Users/dquill/notes before asking."  "home path"
scrub_case "Linux home path"      "It read /home/dquill/notes before asking."   "home path"
scrub_case "Windows home path"    'It read C:\\\\Users\\\\dquill\\\\notes first.' "home path"
scrub_case "tilde path"           "It read ~/Code/thing before asking."          "home path"
scrub_case "e-mail address"       "Mail went to ops@tidewatch.io afterwards."    "e-mail"
scrub_case "git user name"        "Quillfeather approved it twice."              "user or machine name"
scrub_case "project directory"    "The harbor-ledger project lost a step."       "project name"
scrub_case "project file name"    "tidewatch_billing.py was rewritten."          "project name"
scrub_case "secret-shaped token"  "Token ghp_abcdefghijklmnopqrstuvwxyz0123 leaked." "secret"

new_workdir; "$REPORT" prepare --workdir "$W" --project "$P" >/dev/null 2>&1
TMPDIR=/nonexistent/tmp "$REPORT" preview --workdir "$W" --project "$P" > "$T/out" 2>"$T/err"; rc=$?
check "scrub fails closed when it cannot run (rc=$rc)" '[ $rc != 0 ] && ! grep -q "BEGIN PREVIEW" "$T/out" && grep -q "could not run" "$T/err"'
new_workdir; printf '%s\n' "$FIELDS_OK" | sed 's|^what-happened:.*|what-happened: It read /home/dquill/x first.|' > "$W/fields"
TMPDIR=/nonexistent/tmp "$REPORT" prepare --workdir "$W" --project "$P" >/dev/null 2>&1; rc=$?
check "prepare with a broken scrub does not pass a dirty payload (rc=$rc)" '[ $rc != 0 ]'

new_workdir; printf '%s\n' "$FIELDS_OK" | sed 's|^what-happened:.*|what-happened: A fixture used t@example.com as its git address.|' > "$W/fields"
"$REPORT" prepare --workdir "$W" --project "$P" >/dev/null 2>&1; rc=$?
check "reserved example.com address passes (rc=$rc)" '[ $rc = 0 ]'

# The pull-request route is withheld in this release: prepare makes an issue link and send only prints it.
: > "$GH_LOG"
new_workdir; "$REPORT" prepare --workdir "$W" --project "$P" >/dev/null 2>"$T/err"; rc=$?
check "prepare makes the issue route even with a gh session and a change in the clone (rc=$rc)" \
  '[ $rc = 0 ] && grep -q "^Route: issue link" "$W/payload.txt" && ! grep -q "=== Diff ===" "$W/payload.txt" && ! grep -q "^Branch: " "$W/payload.txt"'
"$REPORT" preview --workdir "$W" --project "$P" > "$T/preview"
D=$(sed -n 's/^Digest: //p' "$T/preview")
sed -n '/^----- BEGIN PREVIEW/,/^----- END PREVIEW/p' "$T/preview" | sed '1d;$d' > "$T/shown"
check "preview prints the payload byte for byte" 'cmp -s "$T/shown" "$W/payload.txt"'

"$REPORT" send --workdir "$W" --project "$P" >/dev/null 2>&1; rc=$?
check "send without --digest is refused (rc=$rc)" '[ $rc != 0 ]'
cp "$W/payload.txt" "$T/payload.bak"; sed -i.x 's/^Title: .*/Title: Gate question skipped after a resumed phase, edited/' "$W/payload.txt"
"$REPORT" send --workdir "$W" --project "$P" --digest "$D" >/dev/null 2>"$T/err"; rc=$?
check "send with a digest from an older preview is refused (rc=$rc)" '[ $rc != 0 ] && grep -q "digest mismatch" "$T/err"'
cp "$T/payload.bak" "$W/payload.txt"
sed -i.x 's|^\*\*Proposed change:\*\* |&Reported from /Users/dquill/x. |' "$W/payload.txt"
"$REPORT" send --workdir "$W" --project "$P" --digest "$(shasum -a 256 < "$W/payload.txt" | cut -c1-16)" >/dev/null 2>"$T/err"; rc=$?
check "send re-scrubs a payload edited after preview, even with its own digest (rc=$rc)" '[ $rc = 3 ]'
cp "$T/payload.bak" "$W/payload.txt"

URL=$("$REPORT" send --workdir "$W" --project "$P" --digest "$D" | tail -n1)
decoded=$(python3 -c 'import sys,urllib.parse as u; q=u.parse_qs(u.urlsplit(sys.argv[1]).query); sys.stdout.write(q["body"][0])' "$URL")
awk '/^=== Body ===$/{b=1; next} b' "$W/payload.txt" > "$T/issue.body"
check "send prints an issue link whose body decodes to the previewed body" \
  '[[ "$URL" == https://github.com/voyvodka/claude-project-flow/issues/new\?* ]] && [ "$decoded" = "$(cat "$T/issue.body")" ]'

new_workdir; "$REPORT" prepare --workdir "$W" --project "$P" --route pr >/dev/null 2>"$T/err"; rc=$?
check "prepare refuses --route pr (rc=$rc)" '[ $rc = 2 ] && grep -q "not available" "$T/err" && [ ! -f "$W/payload.txt" ]'

# A payload written by an older release, or by hand, for the pull-request route.
"$REPORT" prepare --workdir "$W" --project "$P" >/dev/null
sed -i.x 's/^Route: .*/Route: pull request from a fork under your GitHub account, opened as tester (public)/' "$W/payload.txt"
printf 'Login: tester\nId: 4242\nPush: true\n' > "$W/meta.route"
D=$("$REPORT" preview --workdir "$W" --project "$P" | sed -n 's/^Digest: //p')
"$REPORT" send --workdir "$W" --project "$P" --digest "$D" > "$T/out" 2>"$T/err"; rc=$?
check "send refuses a pull-request payload and pushes nothing (rc=$rc)" \
  '[ $rc = 2 ] && grep -q "only the issue link" "$T/err" && ! grep -q "github.com" "$T/out" && [ "$(git --git-dir="$T/gh/voyvodka/claude-project-flow.git" for-each-ref | wc -l | tr -d " ")" = 1 ]'
check "no step called gh to push, fork or open anything" '! grep -q -e "pr create" -e "repo fork" -e "api user" -e "api repos" "$GH_LOG"'
check "report.sh has no push, fork or pull-request code" '! grep -Eq "git[^#]*[[:space:]]push|gh (pr|repo fork)|pull request [a-z]" "$REPORT"'
check "the plugin registers no hooks" '[ ! -e "$PLUGIN/hooks" ]'

echo "passed $pass, failed $fail"
[ "$fail" = 0 ]
