#!/usr/bin/env bash
# Writes <workdir>/consent, which report.sh send requires: a main-session preview (seen in PostToolUse)
# followed by a typed prompt. Prompts starting with "<" (task notifications) do not count; no jq on users' machines.
input=$(cat)
field() { printf '%s' "$input" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -n1; }

sid=$(field session_id | tr -cd 'A-Za-z0-9_-')
[ -n "$sid" ] || exit 0
state=${CLAUDE_PLUGIN_DATA:-${TMPDIR:-/tmp}/project-flow-data}/report-guard
mkdir -p "$state" 2>/dev/null || exit 0
pending="$state/pending-$sid"

case "$(field hook_event_name)" in
  PostToolUse)
    printf '%s' "$input" | grep -q '"agent_id"' && exit 0
    printf '%s' "$input" | grep -q -- '----- BEGIN PREVIEW' || exit 0
    digest=$(printf '%s' "$input" | grep -Eo 'Digest: [0-9a-f]{16}' | tail -n1 | cut -c9-)
    workdir=$(printf '%s' "$input" | grep -Eo 'Workdir: [A-Za-z0-9._/-]*pf-report\.[A-Za-z0-9]+' | tail -n1 | cut -c10-)
    [ -n "$digest" ] && [ -d "$workdir" ] && [ -f "$workdir/meta" ] || exit 0
    rm -f "$workdir/consent"
    printf '%s %s\n' "$digest" "$workdir" > "$pending"
    ;;
  UserPromptSubmit)
    [ -f "$pending" ] || exit 0
    printf '%s' "$input" | grep -Eq '"prompt"[[:space:]]*:[[:space:]]*"[[:space:]]*<' && exit 0
    read -r digest workdir < "$pending"
    rm -f "$pending"
    [ -d "$workdir" ] && [ "$(cat "$workdir/previewed" 2>/dev/null)" = "$digest" ] || exit 0
    printf '%s\n' "$digest" > "$workdir/consent"
    ;;
esac
exit 0
