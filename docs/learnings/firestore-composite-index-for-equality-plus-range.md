---
name: firestore-composite-index-for-equality-plus-range
description: adding a second whereField (equality) alongside an existing range/order query requires a new composite index, or the query throws at runtime
type: gotcha
area: Services
---

Firestore auto-indexes single-field equality queries, but the moment you add an
equality `.whereField` next to an existing range filter (`isGreaterThan`/`isLessThan`)
or `.order(by:)` on a different field, that combination needs a composite index
declared in `firestore.indexes.json` (see [[firebase-json-needs-indexes-key]] for why
the file even gets deployed). Without it the query fails at runtime with a Firestore
error containing a console link to auto-create the index — it is not caught at compile
time or in `scripts/build.sh`.

**Why:** e.g. adding `.whereField("isActive", isEqualTo: true)` to `NEIOfferService.fetchOffers`'s
bounding-box query (which already range-filters + orders on `latitude`) needs an
`isActive ASC, latitude ASC` composite index. Same pattern for adding
`.order(by: "createdAt", descending: true)` next to an existing `ownerId`/`requesterId`
equality filter in `NEIOfferService.fetchOffersByOwner` / `NEITransactionService`.

**How to apply:** whenever you add a second query clause to an existing Firestore query
in this codebase, add the matching composite index entry to `firestore.indexes.json`
in the same change, and tell the user to run
`firebase deploy --only firestore:indexes` (don't run it yourself — it changes shared
remote infra). Test in the simulator against a real project only after the index is
live, since it can take a few minutes to build server-side.
