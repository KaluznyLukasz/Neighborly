#!/usr/bin/env bash
# PreToolUse(Bash): block direct commits / merges / pushes to `main`.
# Discipline guard, not a security boundary — stops casual mistakes, not a
# determined override. Bypass: command contains `MAIN_OK`, or env NEI_MAIN=1.
CMD="$(python3 -c 'import sys, json
try:
    print(json.load(sys.stdin).get("tool_input", {}).get("command", ""))
except Exception:
    print("")')"

case "$CMD" in *MAIN_OK*) exit 0 ;; esac
[ "${NEI_MAIN:-0}" = "1" ] && exit 0

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
[ -z "$ROOT" ] && exit 0
BRANCH="$(git -C "$ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null)"
norm="$(printf '%s' "$CMD" | tr -s ' \t\n' ' ')"

deny() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$1"
  exit 0
}

# Match a pattern only at a COMMAND position (start, or after ; && || |) — so the
# string appearing as an argument to grep/echo/sed doesn't trigger a false block.
invokes() { printf '%s' "$norm" | grep -qE "(^|[;&|])[[:space:]]*$1"; }

if [ "$BRANCH" = "main" ]; then
  if invokes "git commit"; then
    deny "Do not commit directly to main. Branch off first: git switch -c <type>/<slug>, then commit and open a PR. Override with MAIN_OK in the command if you really mean it."
  fi
  if invokes "git merge "; then
    deny "Do not merge into main locally. Open a PR instead."
  fi
fi

if invokes "git push" && printf '%s' "$norm" | grep -qE " (main|HEAD:main|origin[[:space:]]+main|:main)"; then
  deny "Do not push to main directly. Push your topic branch: git push -u origin HEAD."
fi

exit 0
