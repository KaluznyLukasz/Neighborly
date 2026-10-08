---
name: read-after-unawaited-write-denied-by-rules
description: getDocument right after an un-awaited setData can be denied by rules (doc not on the server yet); try? reads that as "missing"; .task on a stack root re-runs on pop and hits it
type: gotcha
area: Views/Offers, Services
---

`NEITransactionService.createTransaction` calls `setData(from:)` without waiting for the server.
A `getDocument()` on the same doc a moment later waits for the server. If the write hasn't
landed, the `transactions` read rule (`resource.data.requesterId == …`) sees no document and
denies the read. `try?` turns that into `nil`, so the doc looks like it doesn't exist even
though the user just created it.

`.task` on a `NavigationStack` root runs again when a pushed view pops. In `NEIOfferDetailView`
the "already applied" check ran right after `NEIRequestView` sent and popped. The read lost the
race and flipped the button back to "Offer to Help", so users applied twice.

**Why:** the local cache already has the doc (pending write), so it works in quick tests on a
fast network and fails on a real device.
**How to apply:**
- Don't downgrade state you already know (set by a callback like `onSent`) from a read that
  may fail. Only move it forward (`if found { applied = true }`).
- Expect a root `.task` to re-run after every pop. Guard work that should run once.
- Related: [[firestore-first-snapshot-may-be-cache]].
