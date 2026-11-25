#!/usr/bin/env bash
# Mechanical half of the defect-report consent rule (skills/project-flow/references/defect-report.md):
# `report.sh send` runs only when the user has submitted a message after the session's latest
# `report.sh preview`. The model can never produce that message itself, so a preview and a send in
# the same turn are refused, and so is a send with no preview at all. Raw pushes or PR/issue
# creation from a report workdir are refused too, so the scrub and digest check cannot be skipped.
# Hook input is read as raw JSON on purpose: jq is not guaranteed on users' machines.
input=$(cat)

sid=$(printf '%s' "$input" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | tr -cd 'A-Za-z0-9_-')
[ -n "$sid" ] || sid=unknown
dir=${CLAUDE_PLUGIN_DATA:-${TMPDIR:-/tmp}/project-flow-data}/report-guard
mkdir -p "$dir" 2>/dev/null || exit 0

deny() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$1"
  exit 0
}

if printf '%s' "$input" | grep -Eq '"hook_event_name"[[:space:]]*:[[:space:]]*"UserPromptSubmit"'; then
  touch "$dir/prompt-$sid"; exit 0
fi

# Only Bash commands that mention a report reach the checks below.
case "$input" in *report.sh*|*pf-report*) ;; *) exit 0 ;; esac

if printf '%s' "$input" | grep -Eq 'report\.sh[^;&|]*[[:space:]]preview([[:space:]]|\\"|"|$)'; then
  touch "$dir/preview-$sid"
  exit 0
fi

if printf '%s' "$input" | grep -Eq 'report\.sh[^;&|]*[[:space:]]send([[:space:]]|\\"|"|$)'; then
  [ -f "$dir/preview-$sid" ] || deny "project-flow: no preview was shown in this session. Run report.sh preview, show its output verbatim, ask the user, and end the reply."
  [ -f "$dir/prompt-$sid" ] && [ "$dir/prompt-$sid" -nt "$dir/preview-$sid" ] \
    || deny "project-flow: the user has not replied since the preview. End the reply with the preview and the yes/no question; send only after the user answers yes."
  exit 0
fi

if printf '%s' "$input" | grep -Eq 'pf-report' && printf '%s' "$input" | grep -Eq 'git[^;&|]*[[:space:]]push|gh[[:space:]]+(pr|issue)[[:space:]]+create|gh[[:space:]]+api[^;&|]*(-X|--method)[[:space:]]*(POST|PUT|PATCH)'; then
  deny "project-flow: a defect report leaves the machine only through report.sh send, after a preview the user answered."
fi
exit 0
