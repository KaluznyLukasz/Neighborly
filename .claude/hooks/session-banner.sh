#!/usr/bin/env bash
# SessionStart: orient the agent — branch + knowledge pointers.
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT" || exit 0
BRANCH="$(git branch --show-current 2>/dev/null || echo '?')"

cat <<EOF
Neighborly — branch: $BRANCH
Knowledge map (read before editing an area):
  • CLAUDE.md — build, architecture, conventions, the loop
  • .claude/skills/CLAUDE.md — scenario → skill routing (skills auto-apply, don't wait to be asked)
  • docs/learnings/INDEX.md — accumulated gotchas (/nei-learn to add)
  • docs/decisions/ — ADRs (/nei-new-adr)
The loop: after any UI or build-relevant change run scripts/build.sh and confirm
** BUILD SUCCEEDED ** before reporting done; after a non-obvious fix run /nei-learn;
recurring rule → /nei-distill into CLAUDE.md.
Skills auto-apply by scenario — see .claude/skills/CLAUDE.md.
EOF
