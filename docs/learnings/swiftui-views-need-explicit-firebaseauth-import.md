---
name: swiftui-views-need-explicit-firebaseauth-import
description: reading User.uid/displayName in a view fails to build without `import FirebaseAuth` (MemberImportVisibility is on)
type: gotcha
area: Views
---

A new view that only touches `authService.currentUser?.uid` / `.displayName` fails with `property 'uid' is not available due to missing import of defining module 'FirebaseAuth' [#MemberImportVisibility]`, even though `NEIAuthService` (a project type) exposes the property.

**Why:** the project enables upcoming feature `MemberImportVisibility`, so members of a type from another module are only visible when that module is imported in the *current file*. SourceKit inside the editor shows unrelated "No such module" noise for every new file, so only `scripts/build.sh` reveals the real error.

**How to apply:** any new view or file using `FirebaseAuth.User` members gets `import FirebaseAuth` (see `NEITransactionListView.swift`). Trust `scripts/build.sh`, not SourceKit diagnostics, for new files.
