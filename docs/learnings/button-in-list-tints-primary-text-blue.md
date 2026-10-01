---
name: button-in-list-tints-primary-text-blue
description: Inside a Button in a List row, .foregroundStyle(.primary) / .secondary still render accent blue; use Color(.label) / Color(.secondaryLabel)
type: gotcha
area: Views (List rows)
---
A settings row built as `Button { HStack { icon; Text(title); Spacer(); Text(value) } }` in a
`List` showed its title and value in accent blue, even with `.foregroundStyle(.primary)` and
`.secondary` set on the texts. Sibling rows built with `Picker` or `Toggle` stayed white.
**Why:** the button style applies the tint as a foreground style on the label, and the
hierarchical styles `.primary`/`.secondary` resolve against that tint, not against the label color.
**How to apply:** in Button labels inside a List, use concrete colors: `Color(.label)`,
`Color(.secondaryLabel)`, `Color(.tertiaryLabel)`. `.buttonStyle(.plain)` also works but drops the
row's tap highlight. Related: [[list-row-restyles-label-in-button]].
