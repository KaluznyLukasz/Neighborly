# Moderation

App Store Guideline 1.2 requires apps with user content to filter objectionable material, let
users report content and block users, publish contact details, and act on reports quickly. The
Terms of Use and the app promise a review within 24 hours, so someone has to check reports at
least once a day.

## What the app does on its own

- `NEIContentFilter` rejects offensive words in posts, alerts, messages, profiles, reviews and
  request notes before they are saved. It runs only in the app, so a modified client could skip it.
- Report buttons write a document to `reports`. Users can create reports but can't read, edit or
  delete them, so only the Firebase console sees them.
- Blocking hides the blocked person's posts and alerts. The Firestore rules stop them from
  messaging the blocker, replying to their alerts or requesting their posts.

## Daily check

1. Open Firebase console → Firestore → `reports` and filter `status == "open"`.
2. Each report has `targetType`, `targetId`, `targetOwnerId`, `reason`, `excerpt` (the reported
   text at the time of the report) and `reporterId`. For messages, `targetId` is the full
   document path.
3. If the content breaks the Terms, delete the document at `targetId` (offers, alerts and reviews
   are in their own collections; messages are at the path in `targetId`).
4. For serious or repeat abuse, go to Authentication → Users, find `targetOwnerId` and
   **Disable account**. A disabled user can't sign in or use the API again.
5. Set the report's `status` to `actioned` or `dismissed` and add a `note` field saying what you
   did. Keep reports for up to 12 months (Privacy Policy), then delete them.
6. If you removed content, email the user the reason when you can. The Terms promise this, and
   the EU Digital Services Act expects a statement of reasons.

## Other requests to `contact@example.com`

- **Account deletion when the user can't sign in:** check the request comes from the account's
  email. Delete their data the same way `NEIAccountDeletionService` does, then delete the user in
  Authentication.
- **Data copy (GDPR access):** export their `users/{uid}` document, the offers, alerts,
  transactions and reviews that reference their uid, and their messages (collection group
  `messages` filtered by `senderId`). Reply within one month.
- **Reviews about a deleted user:** delete the `reviews` documents where `revieweeId` is their uid.
