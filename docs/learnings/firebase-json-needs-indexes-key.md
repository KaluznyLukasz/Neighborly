---
name: firebase-json-needs-indexes-key
description: firebase.json's firestore block must list "indexes" or `firebase deploy --only firestore:indexes` deploys nothing
type: gotcha
area: firestore.rules
---

`firebase.json` had `{"firestore": {"rules": "firestore.rules"}}` with no `"indexes"` key. `firestore.indexes.json` existed at the repo root with a correct composite index, but `firebase deploy --only firestore:indexes` had no declared path to it — the command exits successfully but deploys nothing.

**Why:** The deploy appearing to succeed (no error, no obvious failure) makes this easy to miss — the missing-index Firestore query just keeps failing in the app with no signal that the "deploy" didn't actually deploy anything.

**How to apply:** Whenever adding/changing `firestore.indexes.json`, verify `firebase.json`'s `firestore` block also has `"indexes": "firestore.indexes.json"`. After deploying, confirm the index shows in the Firebase console (Firestore → Indexes) — don't trust CLI exit code alone.
