---
name: firebase-email-change-needs-verify-link
description: Firebase Auth updateEmail(to:) fails on this project — email change must go through sendEmailVerification(beforeUpdatingEmail:)
type: gotcha
area: Auth
---

Edit Profile wrote the new email to the Firestore `users` doc, then called `try? await user.updateEmail(to:)`. Firebase rejected that call: the project has email enumeration protection on, and a direct email change also requires a recent login. The `try?` swallowed the error. Settings reads `authService.currentUser?.email`, so it kept showing the old address while the profile doc held the new one.

**Why:** Firebase won't switch a sign-in email until the new owner clicks a link. `sendEmailVerification(beforeUpdatingEmail:)` sends that link. When it's clicked, Auth changes the email and revokes the session, so the user signs in again with the new address.

**How to apply:** Change email only through `NEIAuthService.requestEmailChange(to:)`. On `.requiresRecentLogin`, prompt for the password, call `reauthenticate(password:)`, then retry. Firebase Auth is the only store for email. The `users` doc is readable by every signed-in user, so it must not hold one: `firestore.rules` rejects adding or changing `email` there, and `removeLegacyProfileEmail` strips the old field when its owner signs in.
