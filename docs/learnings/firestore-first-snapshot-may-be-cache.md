---
name: firestore-first-snapshot-may-be-cache
description: A Firestore snapshot listener often fires first from the local cache and then again from the server, so "skip the first snapshot" doesn't mean "skip what existed at start"
type: gotcha
area: Utils/NEIAlertNotifier
---
`NEIAlertNotifier` should stay quiet about alerts that already existed when the app opened,
because the bell count on the map shows them. Skipping the listener's first snapshot didn't
work: that snapshot often comes from the offline cache with old data, and the server snapshot
that follows still contains the alerts posted while the app was closed. They then arrived as a
burst of notifications at launch.

**Why:** with persistence on, `addSnapshotListener` first delivers cached results
(`metadata.isFromCache == true`) and then the server results.
**How to apply:** filter by the documents' own timestamps (here: `createdAt` before the listener
started), not by snapshot order. Or check `snapshot.metadata.isFromCache` if the service
exposes it.
