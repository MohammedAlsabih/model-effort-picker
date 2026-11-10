#!/usr/bin/env bash
# Claude Code PostToolUse hook: every N tool calls, remind Claude to run the
# periodic model/effort review from the model-effort-picker skill.
# Interval: set MODEL_REVIEW_EVERY (default 25).

EVERY="${MODEL_REVIEW_EVERY:-25}"

input="$(cat)"
session_id="$(printf '%s' "$input" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
[ -z "$session_id" ] && session_id="default"

dir="${TMPDIR:-/tmp}/claude-model-review"
mkdir -p "$dir"
file="$dir/$session_id.count"

count=0
[ -f "$file" ] && count="$(cat "$file" 2>/dev/null)"
case "$count" in ''|*[!0-9]*) count=0 ;; esac
count=$((count + 1))
printf '%s' "$count" > "$file"

if [ $((count % EVERY)) -eq 0 ]; then
  msg="Checkpoint (${count} tool calls): run the silent periodic model/effort review from the model-effort-picker skill. Write nothing if the current model and effort still fit; otherwise add one line starting with 🔄 and continue the task."
  printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$msg"
fi

exit 0
