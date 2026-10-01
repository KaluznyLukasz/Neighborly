---
name: swipeactions-need-a-list
description: .swipeActions only works on List rows; in ScrollView/VStack it does nothing. Convert to a plain List with clear rows to keep the card look.
type: gotcha
area: Views/Profile
---

`.swipeActions` only works on rows inside a `List`. If you put it on a view inside a
`ScrollView` + `VStack`, it compiles, doesn't warn and doesn't swipe. The Profile screen
was a `ScrollView` of cards, so My Posts couldn't get swipe-to-delete until the screen
became a `List`.

**Why:** Nothing tells you the modifier is ignored. It's easy to assume swipe works because
it works in Activity, which already uses a `List`.
**How to apply:** To add swipe actions to a card-style scroll screen, switch to
`List { … }.listStyle(.plain)` with `.scrollContentBackground(.hidden)` and
`.environment(\.defaultMinListRowHeight, 0)`. Give each row `.listRowInsets(…)`,
`.listRowBackground(Color.clear)` and `.listRowSeparator(.hidden)`, which the
`profileRow(_:)` helper in `NEIProfileView.swift` sets up. Use per-row spacing in the
insets in place of `VStack(spacing:)`. See also [[section-per-row-breaks-ondelete]].
