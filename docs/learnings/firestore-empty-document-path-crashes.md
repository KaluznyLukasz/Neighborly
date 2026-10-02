---
name: firestore-empty-document-path-crashes
description: document("") raises an Obj-C exception that try? can't catch — guard uid fallbacks like `?? ""` before building a Firestore path
type: gotcha
area: Services, ViewModels
---

`db.collection(...).document("")` doesn't return a Swift error. Firestore raises an
Obj-C `NSException` (`-[FIRCollectionReference documentWithPath:]`, invalid argument),
and Swift `try?` / `do-catch` can't catch it, so the app aborts with SIGABRT.

**Why:** many views pass `authService.currentUser?.uid ?? ""`. Right after sign-out
`currentUser` is nil, and a reload can still fire with `""` before the TabView is gone.
`NEIProfileViewModel.load` → `fetchUser` crashed this way on Sign Out. The `try?` around
the call makes the code look safe, but it doesn't stop this crash.

**How to apply:** if an id can come from a `?? ""` fallback, check
`guard !id.isEmpty` before calling `.document(id)`. Put the check in the VM/service
entry point, not in each caller. For an unexplained crash on the simulator, start
with `~/Library/Logs/DiagnosticReports/Neighborly-*.ips`: the faulting thread
names the Swift file and line.
