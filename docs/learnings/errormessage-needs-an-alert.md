---
name: errormessage-needs-an-alert
description: a ViewModel's errorMessage property is inert unless some View actually binds it to an .alert
type: gotcha
area: ViewModels
---

`NEIProfileViewModel` correctly catches its reviews-fetch failure and sets `errorMessage` — but neither `NEIProfileView` nor `NEIUserProfileView` ever read `vm.errorMessage`. A real Firestore error (e.g. missing-index `FAILED_PRECONDITION`) rendered identically to "no reviews yet": both are just an empty `reviews` array from the caller's point of view.

**Why:** Fixing the catch block alone feels like a complete fix ("now it sets errorMessage!") but does nothing observable — the failure is still silent to the user and to whoever's debugging via screenshots, since nothing ever displays it.

**How to apply:** Any time you add/fix `errorMessage` handling in a ViewModel, grep the views that use it for `vm.errorMessage` — if nothing binds it to `.alert`/inline `Text`, add one (see the `Binding(get:set:)`-wrapped `.alert` pattern in `NEITransactionListView.swift`).
