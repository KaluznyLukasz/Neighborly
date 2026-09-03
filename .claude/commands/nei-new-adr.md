---
description: Record an architecture decision under docs/decisions
argument-hint: [short title of the decision]
---

Record a decision that changes how the app is built — a format choice, a dependency,
a pattern adopted or rejected. Small enough to skim, permanent enough to cite later.

1. Filename: `docs/decisions/YYYY-MM-DD-<slug>.md` (today's date, kebab-case slug).
2. Body:

   ```markdown
   ---
   title: <decision title>
   date: <YYYY-MM-DD>
   status: accepted
   ---

   ## Context
   <what forced the decision — the problem, the constraints>

   ## Decision
   <what we chose, stated plainly>

   ## Consequences
   <what this makes easy, what it makes hard, what we gave up>
   ```

3. If it supersedes an earlier ADR, set that one's `status: superseded by <this file>`.

Title (if given): $ARGUMENTS

Keep it to one screen. No AI-tell prose — run `nei-stop-slop` over the text.
