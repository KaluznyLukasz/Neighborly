---
name: firebase-email-change-needs-verify-link
description: Firebase Auth rejects updateEmail(to:) while email enumeration protection is on; the app falls back to sendEmailVerification(beforeUpdatingEmail:)
type: gotcha
area: Auth
---

Edit Profile used to call `try? await user.updateEmail(to:)`. Firebase rejected it, and the `try?` hid the error. Settings reads `authService.currentUser?.email`, so it kept the old address while the profile doc showed the new one.

**Why:** `neighborly-d3c33` had email enumeration protection on, as new Firebase projects do by default. With it on, Firebase only changes an email through a link sent to the new address (`sendEmailVerification(beforeUpdatingEmail:)`), and `updateEmail(to:)` fails with `.operationNotAllowed` even right after reauthentication. You can check from outside: `accounts:createAuthUri` leaves out the `registered` field while protection is on.

**How to apply:** change email only through `NEIAuthService.changeEmail(to:password:)`. It reauthenticates with the password and calls `updateEmail(to:)`. On `.operationNotAllowed` it sends the link instead and returns `.verificationSent`. `updateEmail` is deprecated, so the service calls it through the `DirectEmailUpdating` protocol to keep the build free of warnings.

Firebase Auth is the only place that stores the email. The `users` doc is readable by every signed-in user: `firestore.rules` rejects adding or changing `email` there, and `removeLegacyProfileEmail` strips the old field when its owner signs in.
