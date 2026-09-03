#!/usr/bin/env bash
# PostToolUse: watch context-window usage; at >=90% of the model's window, surface a
# strong directive to compact. Window is model-aware — 1M for the 1M-context build
# (model id contains "[1m]"/"1m context"), else 200k. (Claude Code auto-compacts near its
# own hard limit; this fires earlier.) Warns once per crossing per session via a marker.
IN="$(cat)"
read -r SID TP PCT < <(printf '%s' "$IN" | python3 -c '
import sys, json, os
try: d=json.load(sys.stdin)
except: d={}
sid=d.get("session_id","x"); tp=d.get("transcript_path",""); ctx=0; limit=200000
try:
    if tp and os.path.exists(tp):
        with open(tp,"rb") as f:
            try: f.seek(-200000,2)
            except: f.seek(0)
            tail=f.read().decode("utf-8","ignore")
        for line in reversed(tail.splitlines()):
            try: o=json.loads(line)
            except: continue
            msg=o.get("message",{}) or {}
            u=msg.get("usage") or o.get("usage")
            if u and u.get("input_tokens") is not None:
                ctx=u.get("input_tokens",0)+u.get("cache_read_input_tokens",0)+u.get("cache_creation_input_tokens",0)
                model=str(msg.get("model","") or o.get("model","")).lower()
                if "[1m]" in model or "1m" in model: limit=1000000
                break
except: pass
print(sid, "x", ctx*100//limit)
' 2>/dev/null)

[ -z "${PCT:-}" ] && exit 0
MARK="/tmp/nei_ctx_${SID}.warned"
if [ "$PCT" -lt 90 ]; then rm -f "$MARK"; exit 0; fi   # re-arm once back under 90%
[ -f "$MARK" ] && exit 0          # already warned at this crossing
touch "$MARK"

printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"⚠ CONTEXT AT %s%% (>=90%%). Compact now: wrap up the current tool, then run /compact (or stop and let the harness auto-compact). Do not start large new tool output until compacted."}}\n' "$PCT"
