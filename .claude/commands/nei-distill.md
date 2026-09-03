---
description: Promote recurring learnings into durable CLAUDE.md rules / ADRs
---

The self-improving step: ephemeral learnings → durable rules. Run periodically.

1. Read `docs/learnings/INDEX.md` and the linked files.
2. Identify learnings that are (a) project-wide rules, (b) recurring, or
   (c) high-cost-if-ignored. These deserve promotion.
3. For each promotable learning:
   - If it's a **rule for one area** → add a terse bullet to that area's `CLAUDE.md`
     (root `CLAUDE.md`, or a per-folder one under `Neighborly/Views/` etc. if it exists).
   - If it's a **significant architectural choice** → run `/nei-new-adr` to record it
     under `docs/decisions/`.
   - After promoting, mark the learning: add `promoted: <where>` to its frontmatter
     and a `(promoted)` tag on its INDEX line. Do NOT delete it — keep the trail.
4. If two learnings contradict, surface the conflict; don't silently pick one.
5. Summarize what you promoted and where.

Be conservative: a one-off gotcha stays a learning. Only promote what genuinely
changes how future work should be done. Match the terse style of each target file.
