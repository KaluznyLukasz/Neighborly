---
name: list-row-restyles-label-in-button
description: A Label used as a Button's label inside a List row loses its title and stretches tall; build the chip from HStack { Image; Text }
type: gotcha
area: Views/Components
---

`NEITrustBadgesView` draws each badge as a `Button` whose label is a `Label` with a
capsule background. When the Profile hero card moved into a `List` row, the badge
turned into a narrow, tall capsule showing only the icon. `.fixedSize()` didn't help.
Replacing the `Label` with `HStack { Image; Text }` did.

**Why:** List rows restyle any `Label` inside them, including one nested in a
plain-style `Button`. The view looks fine everywhere else, so it's easy to miss.
**How to apply:** If a chip or capsule view might end up in a `List` row, build it
from `HStack { Image(systemName:); Text }` rather than `Label`. Related:
[[swipeactions-need-a-list]].
