#!/usr/bin/env bash
# Enforces that skills/project-flow/scripts/report.sh send runs only after a user prompt newer than
# the session's last preview, and that nothing leaves a report workdir except through send.
# Raw JSON is matched with grep because jq is not guaranteed on users' machines.
input=$(cat)

deny() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$1"
  exit 0
}
has() { printf '%s' "$norm" | grep -Eq -- "$1"; }

sid=$(printf '%s' "$input" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | tr -cd 'A-Za-z0-9_-')
[ -n "$sid" ] || sid=unknown
dir=${CLAUDE_PLUGIN_DATA:-${TMPDIR:-/tmp}/project-flow-data}/report-guard
# Quotes and backslashes removed, so report.sh "send" and report.sh 'send' read the same.
norm=$(printf '%s' "$input" | tr -d "\"'\\\\")

if printf '%s' "$input" | grep -Eq '"hook_event_name"[[:space:]]*:[[:space:]]*"UserPromptSubmit"'; then
  mkdir -p "$dir" 2>/dev/null && touch "$dir/prompt-$sid"
  exit 0
fi

if printf '%s' "$input" | grep -Eq '"tool_name"[[:space:]]*:[[:space:]]*"(Write|Edit|MultiEdit|NotebookEdit)"'; then
  has 'pf-report[^/[:space:]]*/(payload\.txt|previewed|meta|project)([^A-Za-z0-9_.-]|$)' \
    && deny "project-flow: report payload files are written only by report.sh."
  exit 0
fi

script='skills/project-flow/scripts/report\.sh'
if has "$script"; then
  # send is checked before preview: one command running both must still be refused.
  if has '(^|[^A-Za-z0-9_-])send([^A-Za-z0-9_-]|$)'; then
    mkdir -p "$dir" 2>/dev/null || deny "project-flow: the report guard cannot record consent here, so sending is refused."
    [ -f "$dir/preview-$sid" ] || deny "project-flow: no preview was shown in this session. Run report.sh preview, show its output verbatim, ask the user, and end the reply."
    [ -f "$dir/prompt-$sid" ] && [ "$dir/prompt-$sid" -nt "$dir/preview-$sid" ] \
      || deny "project-flow: the user has not replied since the preview. End the reply with the preview and the yes/no question; send only after the user answers yes."
    has '(^|[^A-Za-z0-9_-])preview([^A-Za-z0-9_-]|$)' && deny "project-flow: preview and send may not run in one command."
    exit 0
  fi
  if has '(^|[^A-Za-z0-9_-])preview([^A-Za-z0-9_-]|$)'; then
    mkdir -p "$dir" 2>/dev/null && touch "$dir/preview-$sid"
  fi
  exit 0
fi

# In a report workdir (named in the command or the working directory), nothing may reach the network
# or rewrite the consent record except report.sh itself.
if has 'pf-report'; then
  has '(^|[^A-Za-z0-9_-])(git[^;&|]*[[:space:]]push|gh|curl|wget|scp|sftp|rsync|nc|ncat|ssh|http|https)([[:space:]]|$)' \
    && deny "project-flow: a defect report leaves the machine only through report.sh send, after a preview the user answered."
  has 'previewed' && deny "project-flow: the preview record is written only by report.sh preview."
fi
exit 0
