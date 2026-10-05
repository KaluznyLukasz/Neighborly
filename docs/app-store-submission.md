# App Store submission checklist

What the code covers is marked done. The rest happens in App Store Connect or needs a decision.

## Before you submit

- [ ] Replace `contact@example.com` with a real address in `Neighborly/Utils/NEILegal.swift` and
      `web/*.html`, then redeploy: `npx firebase-tools@latest deploy --only hosting`.
- [ ] Set up a way to check reports every day (`docs/moderation.md`). The app promises a 24-hour
      review.
- [ ] Create a demo account for App Review that has a post, an alert and a chat so the reviewer
      can try the report and block flows.
- [ ] iPad screenshots: the target supports iPad (`TARGETED_DEVICE_FAMILY = 1,2`). Either provide
      13" iPad screenshots or make the app iPhone-only.

## Done in code

- Privacy Policy, Terms of Use (with Apple's required EULA terms) and Support pages:
  `web/`, served at https://neighborly-d3c33.web.app/privacy, /terms and /support.
- Sign-up requires confirming the user is 18+ and accepts the Terms. The version and time are
  saved to `users/{uid}.termsVersion` and `termsAcceptedAt`.
- In-app links to the policy, terms and support email (Settings → About, Community Guidelines).
- Account deletion removes all of the user's data (`NEIAccountDeletionService`), not just the
  profile (Guideline 5.1.1(v)).
- User content (Guideline 1.2): offensive language filter, Report on posts, alerts, profiles,
  messages and reviews, Block with server-side enforcement, zero-tolerance rules in the Terms and
  Community Guidelines, published contact address.
- Privacy manifests: `Neighborly/PrivacyInfo.xcprivacy` and `NeighborlyWidgets/PrivacyInfo.xcprivacy`
  (UserDefaults reasons CA92.1 and 1C8F.1, collected data types, no tracking).
- `ITSAppUsesNonExemptEncryption = NO` in `Neighborly-Info.plist`. The app uses only HTTPS, so
  there's no export compliance question on upload.
- FirebaseAnalytics removed. It was linked but unused, and collected data automatically.
- Location permission text explains that alert locations get posted.

## App Store Connect

**App Information**
- Privacy Policy URL: `https://neighborly-d3c33.web.app/privacy`
- Support URL: `https://neighborly-d3c33.web.app/support`
- Category: Lifestyle (or Social Networking).
- Content rights: the app shows content uploaded by users.

**Age rating.** Answer the questionnaire honestly: user-generated content **yes**, messaging and chat
**yes**, everything else none. The Terms require 18+, so pick an 18+ rating if the questionnaire
offers a choice.

**App Privacy (nutrition label).** Everything is "Linked to You", "App Functionality", not used for
tracking:

| Data type | Why |
| --- | --- |
| Contact Info → Name | account and profile |
| Contact Info → Email Address | sign-in |
| Location → Precise Location | alerts store the poster's location; posts store the address's location |
| User Content → Photos or Videos | post, alert and profile photos |
| User Content → Emails or Text Messages | in-app chat |
| User Content → Other User Content | posts, alerts, reviews, bio, reports |
| Identifiers → User ID | Firebase user ID |

No usage data, diagnostics or identifiers for advertising (Analytics is gone). Keep this table, the
privacy manifest and `web/privacy.html` in sync.

**EU Digital Services Act.** Declare trader status (App Store Connect → Business). As a trader, your
address and phone number are shown on the EU storefront.

**Review notes** (paste and fill in):

> Demo account: <email> / <password>
> Neighborly is a neighborhood lending and help app. User-generated content is moderated:
> offensive language is filtered before posting; every post, alert, profile, message (touch and
> hold) and review can be reported; users can be blocked from their profile, which also stops
> them from messaging you; reports are reviewed within 24 hours and abusive accounts are
> disabled. Account deletion: Profile → Settings → Delete Account.
> Location is used to show nearby posts and alerts and to place alerts the user posts.
