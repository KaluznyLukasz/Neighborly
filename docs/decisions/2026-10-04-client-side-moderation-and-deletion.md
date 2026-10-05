---
status: accepted
date: 2026-10-04
---

# Moderation and account deletion run in the app, enforced by Firestore rules

## Context

App Store review needs four things for user content (Guideline 1.2): a filter, reporting, blocking
and contact details. It also needs account deletion that removes the user's data (5.1.1(v)), and
GDPR Art. 17 says the same. Neighborly has no backend: no Cloud Functions, no server.

## Decision

- **Reports** are documents in a create-only `reports` collection. Rules validate the fields and
  forbid reads, so only the Firebase console sees them. Each report copies an `excerpt` of the
  content so the moderator can see it after deletion.
- **Filtering** is a regex word list in the app (`NEIContentFilter`), English and Polish stems,
  matched after folding diacritics and leetspeak.
- **Blocking** stays a private `users/{uid}/blocked` list. Rules use `exists()` on the target's
  list to refuse requests, alert threads and messages from people they blocked.
- **Account deletion** is a cascade in the app (`NEIAccountDeletionService`) run before the
  profile and Auth user are deleted. Rules got the deletes it needs: participants delete messages
  of finished transactions, thread participants delete alert threads, reviewers delete their
  reviews. One collection-group read finds the user's messages in other people's alert threads.
  That read needs a `messages.senderId` collection-group field override.

## Consequences

- No server cost or deploy step beyond rules and indexes, but a modified client can skip the
  filter and the cascade. Reports and Auth account disabling are the backstop.
- The cascade runs before `user.delete()`. If it fails, the account stays and a retry finishes it.
- Deleting an account also deletes shared transactions and their chats for the other person.
- If a backend is added later, move the cascade to an Auth `onDelete` trigger and the filter to a
  write trigger. Then remove the extra delete permissions from the rules.
