---
name: form-destructive-button-icon-stays-blue
description: Button(role: .destructive) with a systemImage inside a Form colors only the title red; the icon stays accent blue
type: gotcha
area: Views (Form rows)
---

In a `Form`/`List`, `Button("Remove", systemImage: "trash", role: .destructive)` renders
the title red but leaves the SF Symbol in the accent color (blue).

**Why:** the role only styles the text. A blue trash icon next to red text looks broken and
reads as a non-destructive action.

**How to apply:** add `.foregroundStyle(.red)` to the button so the icon and title match.
Text-only destructive buttons don't need it.
