---
name: firebase-cli-via-npx-no-global-install
description: firebase CLI isn't installed globally in this env — use npx firebase-tools@latest instead
type: convention
area: infra/firestore
---

`which firebase` fails in this dev environment — no global install. `node`/`npm`/`npx`
are present though, so `npx --yes firebase-tools@latest <command>` works without
installing anything permanently (e.g. `npx --yes firebase-tools@latest deploy --only
firestore:indexes --project neighborly-d3c33`). A cached login already existed
(`login:list` showed a logged-in account), so deploys didn't need interactive `firebase
login`.

**Why:** avoids assuming the deploy is blocked just because `firebase` isn't on PATH.
**How to apply:** for any future Firestore rules/indexes deploy, use the `npx
firebase-tools@latest` form; check `login:list` first to confirm cached auth before
assuming an interactive browser login is required.

See [[firestore-composite-index-for-equality-plus-range]].
