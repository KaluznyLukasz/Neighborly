---
name: button-in-list-tints-primary-text-blue
description: Inside any Button label (List row or not), .foregroundStyle(.primary) / .secondary resolve against the tint; use Color(.label) / Color(.secondaryLabel)
type: gotcha
area: Views (Button labels)
---
A settings row built as `Button { HStack { icon; Text(title); Spacer(); Text(value) } }` in a
`List` showed its title and value in accent blue, even with `.foregroundStyle(.primary)` and
`.secondary` set on the texts. Sibling rows built with `Picker` or `Toggle` stayed white.
**Why:** the button style applies the tint as a foreground style on the label, and the
hierarchical styles `.primary`/`.secondary` resolve against that tint, not against the label color.
**How to apply:** in any Button label, use concrete colors: `Color(.label)`,
`Color(.secondaryLabel)`, `Color(.tertiaryLabel)`. `.buttonStyle(.plain)` also works but drops the
row's tap highlight.
Not List-specific: a plain `Button` on the sign-in screen with `.tint(.green)` rendered
`Text("Don't have an account? …").foregroundStyle(.secondary)` as dim green. Same fix.
Related: [[list-row-restyles-label-in-button]].
