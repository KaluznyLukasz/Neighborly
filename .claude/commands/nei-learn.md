---
description: Capture a non-obvious discovery as a durable repo learning
argument-hint: [one-line gist of what you learned]
---

A learning is one non-obvious fact the NEXT agent should not have to rediscover:
a gotcha, a tuning rationale, a constraint, a "why it's done this way." Skip
anything already in CLAUDE.md, the git history, or obvious from the code.

Do this now:

1. Decide the slug: short kebab-case (e.g. `sheet-detent-remount`, `firestore-dedupe-id`).
2. Write `docs/learnings/<slug>.md` with this exact frontmatter + body:

   ```markdown
   ---
   name: <slug>
   description: <one line — used to judge relevance later>
   type: gotcha | convention | decision
   area: <area, e.g. Views/Map, Services, firestore.rules>
   ---

   <the fact, stated plainly>

   **Why:** <what makes it non-obvious / what bites if ignored>
   **How to apply:** <what a future agent should do>
   ```

   Link related learnings with `[[other-slug]]`.

3. Append one line to `docs/learnings/INDEX.md`:
   `- [<slug>](<slug>.md) — <hook>`

4. If this learning is really a project-wide RULE (not a one-off), say so and
   suggest `/nei-distill` to promote it into CLAUDE.md.

Topic (if given): $ARGUMENTS

Keep it terse. One fact per file. Don't duplicate an existing learning — check
`docs/learnings/INDEX.md` first and update that file instead if it overlaps.
