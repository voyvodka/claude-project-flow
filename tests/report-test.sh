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
export CLAUDE_PLUGIN_DATA  # set below, before the first hook call
# Hook inputs in the shape Claude Code sends (captured from a real session, values replaced).
hook_json() { # event, extra JSON fields
  printf '{"session_id":"%s","transcript_path":"/t/x.jsonl","cwd":"/w","prompt_id":"p1","permission_mode":"default","hook_event_name":"%s"%s}' "${SID:-s1}" "$1" "$2"
}
json_str() { python3 -c 'import json,sys; sys.stdout.write(json.dumps(sys.stdin.read()))'; }
post_preview() { # stdout file [agent]
  local extra=""; [ -n "${2:-}" ] && extra=',"agent_id":"a1","agent_type":"general-purpose"'
  hook_json PostToolUse "$extra,\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"bash \\\"\$R\\\" preview\"},\"tool_response\":{\"stdout\":$(json_str < "$1"),\"stderr\":\"\",\"interrupted\":false}" | bash "$GUARD"
}
user_prompt() { hook_json UserPromptSubmit ",\"prompt\":$(printf '%s' "$1" | json_str)" | bash "$GUARD"; }
reset_consent() { rm -f "$CLAUDE_PLUGIN_DATA"/report-guard/pending-* "$W/consent"; }
preview_with_reply() { # runs preview, feeds the hook, then a typed reply; prints the digest
  "$REPORT" preview --workdir "$W" --project "$P" > "$T/pv.out"
  post_preview "$T/pv.out"; user_prompt "yes"
  sed -n 's/^Digest: //p' "$T/pv.out"
}
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
pass=0; fail=0
ok()  { pass=$((pass+1)); echo "ok   $1"; }
bad() { fail=$((fail+1)); echo "FAIL $1"; }
check() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }

export HOME="$T/home"; mkdir -p "$HOME"
CLAUDE_PLUGIN_DATA="$T/data"
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
"$REPORT" send --workdir "$W" --project "$P" --digest "$D" > /dev/null 2>"$T/err"; rc=$?
check "send right after preview, with no reply from the user, is refused (rc=$rc)" '[ $rc != 0 ] && grep -q "no reply" "$T/err" && ! grep -q "pr create" "$GH_LOG"'
post_preview "$T/preview"; user_prompt "<task-notification><task-id>x</task-id><status>completed</status></task-notification>"
"$REPORT" send --workdir "$W" --project "$P" --digest "$D" > /dev/null 2>"$T/err"; rc=$?
check "a background-task notification is not a reply (rc=$rc)" '[ $rc != 0 ] && ! grep -q "pr create" "$GH_LOG"'
reset_consent; post_preview "$T/preview" agent; user_prompt "yes"
"$REPORT" send --workdir "$W" --project "$P" --digest "$D" > /dev/null 2>"$T/err"; rc=$?
check "a preview run by a subagent, which the user never saw, earns no consent (rc=$rc)" '[ $rc != 0 ] && ! grep -q "pr create" "$GH_LOG"'
reset_consent; post_preview "$T/preview"; SID=s2 user_prompt "yes"
"$REPORT" send --workdir "$W" --project "$P" --digest "$D" > /dev/null 2>"$T/err"; rc=$?
check "a reply in another session does not count (rc=$rc)" '[ $rc != 0 ] && ! grep -q "pr create" "$GH_LOG"'
reset_consent; ( cd "$(dirname "$REPORT")" && bash ./report.sh send --workdir "$W" --project "$P" --digest "$D" ) > /dev/null 2>&1; rc=$?
check "the gate holds however the script is invoked (relative path from its own directory) (rc=$rc)" '[ $rc != 0 ] && ! grep -q "pr create" "$GH_LOG"'
post_preview "$T/preview"; user_prompt "yes"
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
"$REPORT" send --workdir "$W" --project "$P" --digest "$D" > /dev/null 2>"$T/err"; rc=$?
check "consent is used up by one send (rc=$rc)" '[ $rc != 0 ] && grep -q "no reply" "$T/err"'
post_preview "$T/preview"; user_prompt "yes"; "$REPORT" preview --workdir "$W" --project "$P" > /dev/null
check "a new preview clears an earlier consent" '[ ! -f "$W/consent" ]'

export PUSH_PERM=true; : > "$GH_LOG"
new_workdir; "$REPORT" prepare --workdir "$W" --project "$P" >/dev/null
D=$(preview_with_reply)
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
D=$(preview_with_reply)
"$REPORT" send --workdir "$W" --project "$P" --digest "$D" >/dev/null 2>"$T/err"; rc=$?
BR=$(sed -n 's/^Branch: //p' "$W/payload.txt")
check "an existing repo that is not a fork of the target gets nothing (rc=$rc)" \
  '[ $rc != 0 ] && grep -q "not a fork" "$T/err" && ! git --git-dir="$T/gh/tester/claude-project-flow.git" rev-parse -q --verify "$BR" >/dev/null'

new_workdir; "$REPORT" prepare --workdir "$W" --project "$P" >/dev/null
( cd "$W/src" && git push -q "example-host:owner/repo" HEAD:x ) > /dev/null 2>&1; rc1=$?
( cd "$W/src" && git push -q ../../ HEAD:x ) > /dev/null 2>&1; rc2=$?
check "the agent's clone refuses scp-style and relative pushes too (rc=$rc1/$rc2)" '[ $rc1 != 0 ] && [ $rc2 != 0 ]'
user_prompt "an ordinary prompt with nothing pending" >/dev/null
check "the hook writes nothing when no preview is pending" '[ ! -f "$W/consent" ]'

BIGNAME="$T/work/many-files"; mkdir -p "$BIGNAME"; git -C "$BIGNAME" init -q
( cd "$BIGNAME" && i=0; while [ "$i" -lt 21000 ]; do : > "f$i.txt"; i=$((i+1)); done; : > zz_marlowquest_plan.txt; git add -A && git commit -qm big )
new_workdir; printf '%s\n' "$FIELDS_OK" | sed 's|^what-happened:.*|what-happened: zz_marlowquest_plan.txt was rewritten.|' > "$W/fields"
"$REPORT" prepare --workdir "$W" --project "$BIGNAME" >/dev/null 2>"$T/err"; rc=$?
check "file names past the first 20000 are still scanned (rc=$rc)" '[ $rc = 3 ] && grep -q "project name" "$T/err"'
echo x > "$P/zephyrine_contract.pdf"; mkdir -p "$P/a/b/c/d/e/f"; echo x > "$P/a/b/c/d/e/f/deepnamefile.txt"
for v in "zephyrine_contract.pdf leaked." "deepnamefile.txt leaked."; do
  new_workdir; printf '%s\n' "$FIELDS_OK" | sed "s|^what-happened:.*|what-happened: $v|" > "$W/fields"
  "$REPORT" prepare --workdir "$W" --project "$P" >/dev/null 2>"$T/err"; rc=$?
  check "untracked and deep file names are scanned: $v (rc=$rc)" '[ $rc = 3 ]'
done
rm -rf "$P/zephyrine_contract.pdf" "$P/a"
git config --global user.name "Flow Owner"
new_workdir; "$REPORT" prepare --workdir "$W" --project "$P" >/dev/null 2>"$T/err"; rc=$?
check "a personal name that is also tool vocabulary does not block every report (rc=$rc)" '[ $rc = 0 ]'
git config --global user.name "Dana Quillfeather"

new_workdir; mkdir -p "$P/pf-report.inside/src/plugins/project-flow"; echo x > "$P/pf-report.inside/src/plugins/project-flow/uniqueinsidename.md"
"$REPORT" prepare --workdir "$W" --project "$P" >/dev/null 2>"$T/err"; rc=$?
check "a report workdir inside the project is not scanned as project files (rc=$rc)" '[ $rc = 0 ]'
rm -rf "$P/pf-report.inside"

echo "passed $pass, failed $fail"
[ "$fail" = 0 ]
