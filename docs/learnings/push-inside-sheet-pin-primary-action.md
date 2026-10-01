---
name: push-inside-sheet-pin-primary-action
description: A view pushed inside a .medium sheet keeps the sheet's detent, so a bottom button can sit below the fold; pin it with safeAreaInset, and push instead of stacking a second sheet
type: gotcha
area: Views/Offers
---

`NEIOfferDetailView` is a sheet with `[.medium, .large]` detents and its own `NavigationStack`.
Opening `NEIRequestView` as a second `.sheet` looked bad (sheet on a sheet). Pushing it with
`.navigationDestination(isPresented:)` fixes that, but the pushed page stays at the sheet's
current detent. At `.medium` the "Send Request" button, last in the `ScrollView`, was cut off.

**Why:** a push doesn't change the sheet's size, and the pushed page's content scrolls under
the half-height edge. Putting the primary action at the end of the scroll content only works
at `.large`.
**How to apply:**
- For any page pushed inside a sheet, pin the main action with `.safeAreaInset(edge: .bottom)`
  holding `Divider()` + button + `.background(.regularMaterial)` (see `NEIOfferDetailView` and
  `NEIRequestView.sendBar`).
- Don't stack a `.sheet` on a sheet. Push within the existing stack instead. The pushed view
  drops its own `NavigationStack`, `presentationDetents` and Cancel button (system back
  replaces it), and `dismiss()` pops it.
