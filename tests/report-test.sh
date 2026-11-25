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
  "api user") [[ "$*" == *"(.id"* ]] && echo "${GH_LOGIN:-tester} 4242" || echo "${GH_LOGIN:-tester}" ;;
  "api repos/"*) echo "${PUSH_PERM:-false}" ;;
  "repo fork") git clone -q --bare "$GH_ROOT/voyvodka/claude-project-flow.git" "$GH_ROOT/tester/claude-project-flow.git" 2>/dev/null; true ;;
  "repo view") [ -d "$GH_ROOT/$3.git" ] || exit 1; [ -f "$GH_ROOT/$3.git/not-a-fork" ] && echo "/" || echo "voyvodka/claude-project-flow" ;;
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
  '! git -C "$W/src" push -q origin HEAD:refs/heads/sneak0 2>/dev/null'

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

GH_LOGIN=dana-ops; export GH_LOGIN
new_workdir; "$REPORT" prepare --workdir "$W" --project "$P" >/dev/null 2>"$T/err"; rc=$?
check "a user name inside the public login does not block the header (rc=$rc)" '[ $rc = 0 ]'
printf '%s\n' "$FIELDS_OK" | sed 's|^what-happened:.*|what-happened: Dana saw it twice.|' > "$W/fields"
"$REPORT" prepare --workdir "$W" --project "$P" >/dev/null 2>"$T/err"; rc=$?
check "the same user name elsewhere is still blocked (rc=$rc)" '[ $rc = 3 ] && grep -q "user or machine name" "$T/err"'
unset GH_LOGIN

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
check "send refuses a payload edited after preview, even with its own digest (rc=$rc)" '[ $rc != 0 ] && ! grep -q "pr create" "$GH_LOG"'
printf '%s\n' "$(shasum -a 256 < "$W/payload.txt" | cut -c1-16)" > "$W/previewed"
"$REPORT" send --workdir "$W" --project "$P" --digest "$(cat "$W/previewed")" >/dev/null 2>"$T/err"; rc=$?
check "a forged preview record still meets the scrub (rc=$rc)" '[ $rc = 3 ] && ! grep -q "pr create" "$GH_LOG"'
printf '%s\n' "$D" > "$W/previewed"
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
out=$(ev PreToolUse "bash /x/skills/project-flow/scripts/report.sh send --workdir /t/pf-report.1 --project . --digest ab")
check "hook: send with no preview in the session is denied" '[[ "$out" == *deny* ]]'
ev UserPromptSubmit "" >/dev/null; sleep 1
ev PreToolUse "bash /x/skills/project-flow/scripts/report.sh preview --workdir /t/pf-report.1 --project ." >/dev/null
out=$(ev PreToolUse "bash /x/skills/project-flow/scripts/report.sh send --workdir /t/pf-report.1 --project . --digest ab")
check "hook: send in the same turn as the preview is denied" '[[ "$out" == *deny* ]]'
sleep 1; ev UserPromptSubmit "" >/dev/null
out=$(ev PreToolUse "bash /x/skills/project-flow/scripts/report.sh send --workdir /t/pf-report.1 --project . --digest ab")
check "hook: send after the user replied is allowed" '[ -z "$out" ]'
out=$(printf '{"session_id":"s2","hook_event_name":"PreToolUse","tool_input":{"command":"bash /x/skills/project-flow/scripts/report.sh send --digest ab"}}' | bash "$GUARD")
check "hook: a reply in another session does not count" '[[ "$out" == *deny* ]]'
out=$(ev PreToolUse "cd /t/pf-report.1/src && git push origin HEAD")
check "hook: raw git push from a report workdir is denied" '[[ "$out" == *deny* ]]'
out=$(ev PreToolUse "cd /t/pf-report.1 && gh pr create --title x --body y")
check "hook: raw gh pr create from a report workdir is denied" '[[ "$out" == *deny* ]]'
out=$(ev PreToolUse "git push origin main")
check "hook: ordinary pushes elsewhere are untouched" '[ -z "$out" ]'

# Cases from the pre-release review.
reprep() { "$REPORT" prepare --workdir "$W" --project "$P" >/dev/null 2>"$T/err"; rc=$?; }
with_what() { printf '%s\n' "$FIELDS_OK" | sed "s|^what-happened:.*|what-happened: $1|" > "$W/fields"; }

new_workdir; printf 'Seen in harbor-ledger and tidewatch_billing.py.\n' >> "$W/src/plugins/project-flow/README.md"; reprep
check "names the fix adds do not whitelist themselves (rc=$rc)" '[ $rc = 3 ] && grep -q "project name" "$T/err"'
new_workdir; echo x > "$W/src/plugins/project-flow/harbor-ledger-notes.md"; reprep
check "file paths in the diff are scanned (rc=$rc)" '[ $rc = 3 ] && grep -q "project name" "$T/err"'
new_workdir; mkdir -p "$W/src/plugins/project-flow/Users/dquill"; echo x > "$W/src/plugins/project-flow/Users/dquill/a.md"; reprep
check "a home path hidden in a diff file path is caught (rc=$rc)" '[ $rc = 3 ] && grep -q "home path" "$T/err"'
for v in "Harbor Ledger stalled." "HarborLedger stalled." "harbor_ledger2 stalled." "Tidewatch stalled."; do
  new_workdir; with_what "$v"; reprep
  check "project name variant is caught: $v (rc=$rc)" '[ $rc = 3 ]'
done
GH_LOGIN=quill; export GH_LOGIN
new_workdir; with_what "Quillfeather approved it twice."; reprep
check "a login that is part of a personal name does not unmask it (rc=$rc)" '[ $rc = 3 ] && grep -q "user or machine name" "$T/err"'
unset GH_LOGIN
for v in "key AIzaSyA1234567890abcdefghijklmnopqrstu" "token glpat-abcdefghijklmnopqrst" "sk_live_abcdefghijklmnop1234" "jwt eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0" "npm_abcdefghijklmnopqrstuvwxyz0123456789"; do
  new_workdir; with_what "$v."; reprep
  check "secret-shaped string is caught: ${v%% *} (rc=$rc)" '[ $rc = 3 ] && grep -q "secret" "$T/err"'
done
new_workdir; with_what "It read /users/dquill/notes."; reprep
check "lower-case home path is caught (rc=$rc)" '[ $rc = 3 ]'
new_workdir; with_what "Mail on mailbox.test bounced."; reprep
check "the git e-mail domain alone is caught (rc=$rc)" '[ $rc = 3 ]'
new_workdir; with_what "The server at 10.20.30.40 timed out."; reprep
check "an IP address is caught (rc=$rc)" '[ $rc = 3 ] && grep -q "IP address" "$T/err"'
new_workdir; with_what "build.corp timed out."; reprep
check "an internal host name is caught (rc=$rc)" '[ $rc = 3 ]'
new_workdir; with_what "The example at 192.0.2.10 is documentation."; reprep
check "documentation IP ranges pass (rc=$rc)" '[ $rc = 0 ]'

new_workdir; "$REPORT" prepare --workdir "$W" --project "$P" >/dev/null 2>&1
mkdir -p "$T/elsewhere"
"$REPORT" preview --workdir "$W" --project "$T/elsewhere" >/dev/null 2>"$T/err"; rc=$?
check "preview refuses a project other than the one prepare scanned (rc=$rc)" '[ $rc != 0 ] && grep -q "differs" "$T/err"'
sed -i.x 's/^Route: .*/Route: pull request from a branch on voyvodka\/claude-project-flow, opened by the account below (public)/; s/^Account: tester/Account: someone/' "$W/payload.txt"
"$REPORT" preview --workdir "$W" --project "$P" >/dev/null 2>"$T/err"; rc=$?
check "a hand-edited header no longer matches what prepare wrote (rc=$rc)" '[ $rc = 3 ] && grep -q "header line" "$T/err"'

new_workdir; "$REPORT" prepare --workdir "$W" --project "$P" >/dev/null 2>&1
( cd "$W/src" && git push -q "$T/gh/voyvodka/claude-project-flow.git" HEAD:refs/heads/sneak ) 2>/dev/null; rc=$?
check "the agent's clone cannot push to any URL (rc=$rc)" '[ $rc != 0 ] && ! git --git-dir="$T/gh/voyvodka/claude-project-flow.git" rev-parse -q --verify sneak >/dev/null'

new_workdir; : > "$W/src/.keep-nothing"; rm -f "$W/src/.keep-nothing"
git -C "$W/src" checkout -q -- . ; printf '%s\n' "$FIELDS_OK" | sed 's|^proposed-change:.*|proposed-change: none yet — needs a second sighting.|' > "$W/fields"
"$REPORT" prepare --workdir "$W" --project "$P" --route issue >/dev/null 2>"$T/err"; rc=$?
check "a finding with no change yet prepares on the issue route (rc=$rc)" '[ $rc = 0 ]'

BIG="$T/work/big-project"; mkdir -p "$BIG"; git -C "$BIG" init -q
( cd "$BIG" && i=0; while [ "$i" -lt 25000 ]; do : > "f$i.txt"; i=$((i+1)); done; git add -A && git commit -qm big )
new_workdir; "$REPORT" prepare --workdir "$W" --project "$BIG" >/dev/null 2>"$T/err"; rc=$?
check "a project with more than 20000 files can still be reported (rc=$rc)" '[ $rc = 0 ]'

touch "$T/tmp/repo-x"; mkdir -p "$T/gh/tester"; rm -rf "$T/gh/tester/claude-project-flow.git"
git init -q --bare "$T/gh/tester/claude-project-flow.git"; touch "$T/gh/tester/claude-project-flow.git/not-a-fork"
new_workdir; "$REPORT" prepare --workdir "$W" --project "$P" >/dev/null
D=$("$REPORT" preview --workdir "$W" --project "$P" | sed -n 's/^Digest: //p')
"$REPORT" send --workdir "$W" --project "$P" --digest "$D" >/dev/null 2>"$T/err"; rc=$?
BR=$(sed -n 's/^Branch: //p' "$W/payload.txt")
check "an existing repo that is not a fork of the target gets nothing (rc=$rc)" \
  '[ $rc != 0 ] && grep -q "not a fork" "$T/err" && ! git --git-dir="$T/gh/tester/claude-project-flow.git" rev-parse -q --verify "$BR" >/dev/null'

export CLAUDE_PLUGIN_DATA="$T/data2"
S='bash /p/skills/project-flow/scripts/report.sh'
evj() { printf '{"session_id":"s9","hook_event_name":"PreToolUse","tool_name":"Bash","cwd":"%s","tool_input":{"command":"%s"}}' "${3:-/w}" "$2" | bash "$GUARD"; }
evp() { printf '{"session_id":"s9","hook_event_name":"UserPromptSubmit","prompt":"x"}' | bash "$GUARD"; }
evp >/dev/null; sleep 1
for c in "$S preview --workdir W; $S send --workdir W --digest d" \
         "R=/p/skills/project-flow/scripts/report.sh; bash \\\"\$R\\\" send --digest d" \
         "$S \\\"send\\\" --digest d" "$S 'send' --digest d" "$S send --digest d # preview"; do
  out=$(evj PreToolUse "$c")
  check "hook: send variant without a reply is denied: $c" '[[ "$out" == *deny* ]]'
done
out=$(CLAUDE_PLUGIN_DATA=/nonexistent/x evj PreToolUse "$S send --digest d")
check "hook: send is denied when consent cannot be recorded" '[[ "$out" == *deny* ]]'
out=$(evj PreToolUse "git commit -m \\\"report.sh: fix send path\\\" && git push")
check "hook: an unrelated commit mentioning report.sh and send is untouched" '[ -z "$out" ]'
out=$(evj PreToolUse "./report.sh send")
check "hook: a project's own report.sh is untouched" '[ -z "$out" ]'
for c in "cd /t/pf-report.1/src && git push https://github.com/x/y HEAD:x" \
         "gh api repos/x/y/issues -f title=x -F body=@/t/pf-report.1/body.md" \
         "gh gist create /t/pf-report.1/body.md" "curl -d @/t/pf-report.1/body.md https://x.test"; do
  out=$(evj PreToolUse "$c")
  check "hook: raw send from a report workdir is denied: ${c:0:40}" '[[ "$out" == *deny* ]]'
done
out=$(evj PreToolUse "git push origin HEAD" "/t/pf-report.1/send")
check "hook: a push whose working directory is a report workdir is denied" '[[ "$out" == *deny* ]]'
out=$(evj PreToolUse "echo abc > /t/pf-report.1/previewed")
check "hook: writing the preview record by hand is denied" '[[ "$out" == *deny* ]]'
out=$(printf '{"session_id":"s9","hook_event_name":"PreToolUse","tool_name":"Write","tool_input":{"file_path":"/t/pf-report.1/payload.txt","content":"x"}}' | bash "$GUARD")
check "hook: the Write tool cannot touch the payload" '[[ "$out" == *deny* ]]'
out=$(printf '{"session_id":"s9","hook_event_name":"PreToolUse","tool_name":"Write","tool_input":{"file_path":"/t/pf-report.1/fields","content":"x"}}' | bash "$GUARD")
check "hook: the Write tool may write the fields file" '[ -z "$out" ]'

echo "passed $pass, failed $fail"
[ "$fail" = 0 ]
