---
name: section-per-row-breaks-ondelete
description: Wrapping each List row in its own Section (card-per-row look) breaks ForEach.onDelete — use per-row .swipeActions
type: gotcha
area: Views/Transactions
---

The Activity lists render one `Section` per row (`.insetGrouped` + `.listSectionSpacing(12)`)
so items appear as separate cards. With `ForEach { Section { row } }`, `.onDelete` on the
`ForEach` no longer gives swipe-to-delete on the rows, because the rows now belong to
separate sections instead of one data-driven section.

**Why:** Swipe-to-delete silently disappears. There is no build error or warning.
**How to apply:** In card-per-row lists, attach `.swipeActions` with a
`Button(role: .destructive)` to each row and delete by item (`deleteOffer(_:)`), not by `IndexSet`.
