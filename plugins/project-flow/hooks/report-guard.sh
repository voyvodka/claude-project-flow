#!/usr/bin/env bash
# Enforces that `report.sh send` runs only after a user prompt newer than the session's last preview,
# and that nothing is pushed or created from a report workdir except through send.
# Raw JSON is matched with grep because jq is not guaranteed on users' machines.
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
