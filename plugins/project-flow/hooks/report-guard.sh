#!/usr/bin/env bash
# Writes <workdir>/consent, which report.sh send requires: a main-session preview (seen in PostToolUse),
# then a typed prompt whose preceding assistant reply holds the whole payload verbatim. The consent
# lasts until the next prompt in the session. Plain grep/sed/awk: no jq or python on users' machines.
input=$(cat)
field() { printf '%s' "$input" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -n1; }

sid=$(field session_id | tr -cd 'A-Za-z0-9_-')
[ -n "$sid" ] || exit 0
state=${CLAUDE_PLUGIN_DATA:-${TMPDIR:-/tmp}/project-flow-data}/report-guard
mkdir -p "$state" 2>/dev/null || exit 0
pending="$state/pending-$sid"
granted="$state/granted-$sid"

# prepare refuses control characters other than tab, so these are the only JSON escapes needed.
json_escape() { sed 's/[[:space:]]*$//; s/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g'; }

case "$(field hook_event_name)" in
  PostToolUse)
    printf '%s' "$input" | grep -q '"agent_id"' && exit 0
    printf '%s' "$input" | grep -q -- '----- BEGIN PREVIEW' || exit 0
    digest=$(printf '%s' "$input" | grep -Eo 'Digest: [0-9a-f]{16}' | tail -n1 | cut -c9-)
    workdir=$(printf '%s' "$input" | grep -Eo 'Workdir: [A-Za-z0-9._/-]*pf-report\.[A-Za-z0-9]+' | tail -n1 | cut -c10-)
    [ -n "$digest" ] && [ -d "$workdir" ] && [ -f "$workdir/meta" ] || exit 0
    rm -f "$workdir/consent" "$workdir/consent-refused"
    printf '%s %s\n' "$digest" "$workdir" > "$pending"
    ;;
  UserPromptSubmit)
    # Any prompt, typed or not, ends the turn in which a consent could be used.
    if [ -f "$granted" ]; then
      read -r old < "$granted"
      rm -f "$granted"
      [ -n "$old" ] && rm -f "$old/consent"
    fi
    [ -f "$pending" ] || exit 0
    prompt_start=$(printf '%s' "$input" | sed -n 's/.*"prompt"[[:space:]]*:[[:space:]]*"\(.\{0,40\}\).*/\1/p' | head -n1 \
      | sed -E 's/^([[:space:]]|\\[nrt])*//')
    case "$prompt_start" in "<"*) exit 0 ;; esac
    read -r digest workdir < "$pending"
    rm -f "$pending"
    [ -d "$workdir" ] && [ "$(cat "$workdir/previewed" 2>/dev/null)" = "$digest" ] || exit 0
    refuse() { printf '%s\n' "$1" > "$workdir/consent-refused"; exit 0; }
    transcript=$(field transcript_path)
    [ -f "$transcript" ] || refuse "the session transcript could not be read, so it is unknown what the user was shown"
    # Only assistant text rows count: thinking, tool calls and request records are not what the user saw.
    shown=$(mktemp "${TMPDIR:-/tmp}/pf-shown.XXXXXX") || exit 0
    awk -v d="Digest: $digest" '
      !index($0, "\"isSidechain\":false") { next }
      index($0, "\"type\":\"tool_result\"") && index($0, d) && index($0, "BEGIN PREVIEW") { n = 1; buf = ""; next }
      n && index($0, "\"role\":\"assistant\",\"content\":[{\"type\":\"text\",\"text\":\"") && !index($0, "\"type\":\"api-request") { buf = buf $0 "\n" }
      END { printf "%s", buf }' "$transcript" | sed -E 's/([[:space:]]|\\t)+\\n/\\n/g' > "$shown"
    needle=$(json_escape < "$workdir/payload.txt" | awk 'NR > 1 { printf "\\n" } { printf "%s", $0 }')
    found=0
    [ -n "$needle" ] && grep -qF -- "$needle" "$shown" && found=1
    rm -f "$shown"
    [ "$found" = 1 ] || refuse "the reply before the user's answer did not contain the whole preview verbatim; paste it unchanged and ask again"
    printf '%s %s\n' "$digest" "$(date +%s)" > "$workdir/consent"
    printf '%s\n' "$workdir" > "$granted"
    ;;
esac
exit 0
