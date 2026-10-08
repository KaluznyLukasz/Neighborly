---
name: list-row-restyles-label-in-button
description: List rows restyle any Label inside them (chip loses its title, or a wide gap opens after the icon); build inline icon+text from HStack { Image; Text }
type: gotcha
area: Views/Components
---

`NEITrustBadgesView` draws each badge as a `Button` whose label is a `Label` with a
capsule background. When the Profile hero card moved into a `List` row, the badge
turned into a narrow, tall capsule showing only the icon. `.fixedSize()` didn't help.
Replacing the `Label` with `HStack { Image; Text }` did.

A plain `Label` in a row shows the other symptom. The "Planned for …" line in
`TransactionRow` (Activity tab) had a wide gap between the calendar icon and the date,
because the row reserves an icon-width column for the `Label`. `HStack(spacing: 4)` fixed it.

**Why:** List rows restyle any `Label` inside them, including one nested in a
plain-style `Button`. The view looks fine everywhere else, so it's easy to miss.
**How to apply:** For a chip, capsule or inline icon+text line that might end up in a
`List` row, use `HStack { Image(systemName:); Text }` rather than `Label`. Mark the
image `.accessibilityHidden(true)` when the text says it all. Related:
[[swipeactions-need-a-list]].
