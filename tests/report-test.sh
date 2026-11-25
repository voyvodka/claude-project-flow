#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2034  # check() evaluates its condition strings later
# No network: github.com URLs resolve to local bare repos via a private git config, and gh is a stub.
# Every name, path and address below is invented.
set -uo pipefail
export LC_ALL=C
ROOT=$(cd "$(dirname "$0")/.." && pwd)
PLUGIN="$ROOT/plugins/project-flow"
REPORT="$PLUGIN/skills/project-flow/scripts/report.sh"
GUARD="$PLUGIN/hooks/report-guard.sh"
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
  "api user") [[ "$*" == *"(.id"* ]] && echo "tester 4242" || echo "tester" ;;
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

new_workdir; echo "x" > "$W/src/OUTSIDE.md"
"$REPORT" prepare --workdir "$W" --project "$P" >/dev/null 2>"$T/err"; rc=$?
check "scrub blocks a change outside plugins/project-flow (rc=$rc)" '[ $rc = 3 ] && grep -q "outside the plugin" "$T/err"'

new_workdir; printf 'see /Users/dquill/x\n' >> "$W/src/plugins/project-flow/README.md"
"$REPORT" prepare --workdir "$W" --project "$P" >/dev/null 2>"$T/err"; rc=$?
check "scrub reads added diff lines (rc=$rc)" '[ $rc = 3 ] && grep -q "home path" "$T/err"'

new_workdir; printf '%s\n' "$FIELDS_OK" | sed 's|^what-happened:.*|what-happened: A fixture used t@example.com as its git address.|' > "$W/fields"
"$REPORT" prepare --workdir "$W" --project "$P" >/dev/null 2>&1; rc=$?
check "reserved example.com address passes (rc=$rc)" '[ $rc = 0 ]'

new_workdir; "$REPORT" prepare --workdir "$W" --project "$P" >/dev/null
"$REPORT" preview --workdir "$W" --project "$P" > "$T/preview"
D=$(sed -n 's/^Digest: //p' "$T/preview")
sed -n '/^----- BEGIN PREVIEW/,/^----- END PREVIEW/p' "$T/preview" | sed '1d;$d' > "$T/shown"
check "preview prints the payload byte for byte" 'cmp -s "$T/shown" "$W/payload.txt"'
check "preview shows the noreply commit identity, not the git config" 'grep -q "4242+tester@users.noreply.github.com" "$T/shown" && ! grep -qi quillfeather "$T/shown"'

"$REPORT" send --workdir "$W" --project "$P" >/dev/null 2>&1; rc=$?
check "send without --digest is refused (rc=$rc)" '[ $rc != 0 ] && ! grep -q "pr create" "$GH_LOG"'
cp "$W/payload.txt" "$T/payload.bak"; sed -i.x 's/^Title: .*/Title: Gate question skipped after a resumed phase, edited/' "$W/payload.txt"
"$REPORT" send --workdir "$W" --project "$P" --digest "$D" >/dev/null 2>"$T/err"; rc=$?
check "send with a digest from an older preview is refused (rc=$rc)" '[ $rc != 0 ] && grep -q "digest mismatch" "$T/err" && ! grep -q "pr create" "$GH_LOG"'
cp "$T/payload.bak" "$W/payload.txt"
sed -i.x 's|^\*\*Proposed change:\*\* |&Reported from /Users/dquill/x. |' "$W/payload.txt"
"$REPORT" send --workdir "$W" --project "$P" --digest "$(shasum -a 256 < "$W/payload.txt" | cut -c1-16)" >/dev/null 2>"$T/err"; rc=$?
check "send re-scrubs a payload edited after preview, even with its own digest (rc=$rc)" '[ $rc = 3 ] && ! grep -q "pr create" "$GH_LOG"'
cp "$T/payload.bak" "$W/payload.txt"

: > "$GH_LOG"
"$REPORT" send --workdir "$W" --project "$P" --digest "$D" > "$T/out" 2>"$T/err"; rc=$?
check "send via fork succeeds (rc=$rc)" '[ $rc = 0 ] && grep -q "repo fork" "$GH_LOG" && grep -q "pull/999" "$T/out"'
BR=$(sed -n 's/^Branch: //p' "$W/payload.txt")
FORK="$T/gh/tester/claude-project-flow.git"; BASE=$(sed -n 's/^base=//p' "$W/meta")
git --git-dir="$FORK" diff --no-ext-diff "$BASE" "$BR" > "$T/pushed.diff" 2>/dev/null
awk '/^=== Diff ===$/{d=1; next} d' "$W/payload.txt" > "$T/previewed.diff"
check "pushed diff equals the previewed diff" 'cmp -s "$T/pushed.diff" "$T/previewed.diff"'
check "commit author is the noreply address, date in UTC" \
  '[ "$(git --git-dir="$FORK" log -1 --format="%ae %ce %ad" --date=format:%z "$BR")" = "4242+tester@users.noreply.github.com 4242+tester@users.noreply.github.com +0000" ]'
awk '/^=== Body ===$/{b=1; next} /^=== Diff ===$/{exit} b' "$W/payload.txt" > "$T/previewed.body"
check "PR body equals the previewed body" 'cmp -s "$GH_LOG.body" "$T/previewed.body"'
check "PR head is the fork branch" '[ "$(cat "$GH_LOG.head")" = "tester:$BR" ]'
check "nothing in the sent commit names the user" '! git --git-dir="$FORK" log -1 --format=%B%an%ae%cn%ce "$BR" | grep -qi -e quillfeather -e dana'

export PUSH_PERM=true; : > "$GH_LOG"
new_workdir; "$REPORT" prepare --workdir "$W" --project "$P" >/dev/null
D=$("$REPORT" preview --workdir "$W" --project "$P" | sed -n 's/^Digest: //p')
"$REPORT" send --workdir "$W" --project "$P" --digest "$D" >/dev/null 2>"$T/err"; rc=$?
BR=$(sed -n 's/^Branch: //p' "$W/payload.txt")
check "with push permission the branch goes to the repository, no fork (rc=$rc)" \
  '[ $rc = 0 ] && ! grep -q "repo fork" "$GH_LOG" && git --git-dir="$T/gh/voyvodka/claude-project-flow.git" rev-parse -q --verify "$BR" >/dev/null'
unset PUSH_PERM

export GH_AUTHED=0; : > "$GH_LOG"
new_workdir; "$REPORT" prepare --workdir "$W" --project "$P" >/dev/null
check "without a gh session the route is the issue link" 'grep -q "^Route: issue link" "$W/payload.txt" && ! grep -q "=== Diff ===" "$W/payload.txt"'
D=$("$REPORT" preview --workdir "$W" --project "$P" | sed -n 's/^Digest: //p')
URL=$("$REPORT" send --workdir "$W" --project "$P" --digest "$D" | tail -n1)
decoded=$(python3 -c 'import sys,urllib.parse as u; q=u.parse_qs(u.urlsplit(sys.argv[1]).query); sys.stdout.write(q["body"][0])' "$URL")
awk '/^=== Body ===$/{b=1; next} b' "$W/payload.txt" > "$T/issue.body"
check "issue link body decodes to the previewed body" '[ "$decoded" = "$(cat "$T/issue.body")" ]'
check "issue route makes no pr/push call" '! grep -q -e "pr create" -e "repo fork" "$GH_LOG"'
unset GH_AUTHED

export CLAUDE_PLUGIN_DATA="$T/data"
ev() { printf '{"session_id":"s1","hook_event_name":"%s","tool_name":"Bash","tool_input":{"command":"%s"}}' "$1" "$2" | bash "$GUARD"; }
out=$(ev PreToolUse "bash /x/report.sh send --workdir /t/pf-report.1 --project . --digest ab")
check "hook: send with no preview in the session is denied" '[[ "$out" == *deny* ]]'
ev UserPromptSubmit "" >/dev/null; sleep 1
ev PreToolUse "bash /x/report.sh preview --workdir /t/pf-report.1 --project ." >/dev/null
out=$(ev PreToolUse "bash /x/report.sh send --workdir /t/pf-report.1 --project . --digest ab")
check "hook: send in the same turn as the preview is denied" '[[ "$out" == *deny* ]]'
sleep 1; ev UserPromptSubmit "" >/dev/null
out=$(ev PreToolUse "bash /x/report.sh send --workdir /t/pf-report.1 --project . --digest ab")
check "hook: send after the user replied is allowed" '[ -z "$out" ]'
out=$(printf '{"session_id":"s2","hook_event_name":"PreToolUse","tool_input":{"command":"bash /x/report.sh send --digest ab"}}' | bash "$GUARD")
check "hook: a reply in another session does not count" '[[ "$out" == *deny* ]]'
out=$(ev PreToolUse "cd /t/pf-report.1/src && git push origin HEAD")
check "hook: raw git push from a report workdir is denied" '[[ "$out" == *deny* ]]'
out=$(ev PreToolUse "cd /t/pf-report.1 && gh pr create --title x --body y")
check "hook: raw gh pr create from a report workdir is denied" '[[ "$out" == *deny* ]]'
out=$(ev PreToolUse "git push origin main")
check "hook: ordinary pushes elsewhere are untouched" '[ -z "$out" ]'

echo "passed $pass, failed $fail"
[ "$fail" = 0 ]
