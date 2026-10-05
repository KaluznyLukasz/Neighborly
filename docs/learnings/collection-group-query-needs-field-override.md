---
name: collection-group-query-needs-field-override
description: a single-field collectionGroup query fails until firestore.indexes.json has a COLLECTION_GROUP fieldOverride, which must also re-list the collection-scope indexes; deploying with --force deletes console-only indexes
type: gotcha
area: firestore.indexes.json
---

`collectionGroup("messages").whereField("senderId", isEqualTo:)` fails with FAILED_PRECONDITION.
Firestore creates single-field indexes automatically for collection scope only, not for
collection groups. The fix is a `fieldOverrides` entry for `messages.senderId` with
`queryScope: COLLECTION_GROUP`. An override replaces the automatic indexes for that field, so it
must also list the collection-scope ASCENDING, DESCENDING and CONTAINS indexes. Otherwise normal
`messages` queries on `senderId` lose their index.

The query also needs its own rule, `match /{path=**}/messages/{id}`, because the per-path rules
don't cover collection-group reads.

**Why:** `NEIAccountDeletionService` uses this query to find a user's messages in other people's
alert threads. Without the index, Delete Account fails partway through.

**How to apply:** For any new collection-group query, add the override and the `{path=**}` rule,
then deploy with `npx firebase-tools@latest deploy --only firestore`. `--force` skips the prompt
but deletes any index that exists only in the console. Run `firestore:indexes` first and compare
it with the file.
