#!/usr/bin/env bash
# Stop: end-of-turn discipline. Once per session, if Swift files changed, nudge to
# verify-build + capture learnings. Gated to ONE fire per session to avoid Stop-block
# loops. Disable entirely with NEI_STOP_NUDGE=0.
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT" || exit 0

[ "${NEI_STOP_NUDGE:-1}" = "0" ] && exit 0

SID="$(python3 -c 'import sys, json
try:
    print(json.load(sys.stdin).get("session_id", "x"))
except Exception:
    print("x")')"
MARK_DIR="$ROOT/.claude/.cache"; mkdir -p "$MARK_DIR"
MARK="$MARK_DIR/stop-nudged-$SID"
[ -f "$MARK" ] && exit 0   # already nudged this session

CHANGED="$(git diff --name-only HEAD 2>/dev/null)"
if printf '%s' "$CHANGED" | grep -q '\.swift$'; then
  touch "$MARK"
  printf '{"decision":"block","reason":"Swift files changed this session. Before wrapping up: (1) run scripts/build.sh and confirm ** BUILD SUCCEEDED **; (2) capture non-obvious findings with /nei-learn. Fires once per session — proceed if already handled."}\n'
fi
exit 0
