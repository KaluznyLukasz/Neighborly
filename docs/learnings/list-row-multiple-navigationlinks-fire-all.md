---
name: list-row-multiple-navigationlinks-fire-all
description: Several NavigationLinks inside one List row all fire on a single tap, even with .buttonStyle(.plain); use Buttons + .navigationDestination(item:)
type: gotcha
area: Views/Profile
---

If one `List` row holds several `NavigationLink`s, like the Account card in Profile,
one tap pushes every destination in turn. `.buttonStyle(.plain)` doesn't stop it.

**Why:** In a `ScrollView` the same card works fine. The bug only shows up after the
container becomes a `List`, and nothing warns you.
**How to apply:** In card-style List rows, use plain `Button`s that set a
`@State var destination: Destination?`. Push from
`.navigationDestination(item: $destination)` on the stack's content. See
`NEIProfileView.Destination`. Related: [[swipeactions-need-a-list]].
