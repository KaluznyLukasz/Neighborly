---
name: ios27-sim-provisional-notifications-denied
description: On the iOS 27 beta simulator, provisional notification auth reports .provisional but every add() fails as Denied; test reminders on an iOS 26.x sim
type: gotcha
area: Utils/NEIReminderService
---
`NEIReminderService.sync` asks for provisional (quiet) permission when nothing has been asked
yet, so the volunteer's phone can schedule reminders without a prompt. On the iOS 27 beta
simulator `notificationSettings()` then returns `.provisional`, but every
`UNUserNotificationCenter.add` fails with `UNErrorDomain 2003 "Source is not authorized"`
(`UNAuthorizationStatus=Denied`), and nothing ends up pending. The same build on an iOS 26.2
simulator schedules all reminders.

**Why:** a bug in the beta runtime, not in the app.
**How to apply:**
- To check scheduled reminders, use an iOS 26.x simulator: `iPhone 17` on 26.2 works.
- `simctl privacy` has no `notifications` service, and simctl can't tap the system prompt, so
  provisional is the only way to get permission on a simulator without a person tapping Allow.
- Don't "fix" this by removing the provisional request.
