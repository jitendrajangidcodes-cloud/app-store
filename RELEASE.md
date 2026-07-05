# Releases (hub itself)

This file tracks changes to the `app-store` hub repo itself (the website,
`apps.json`/`releases.json`, and the release-distribution scripts) -- not any
individual app's APK releases. Each listed app has its own `RELEASE.md` in its
own repo for that.

## 2026-07-05 -- Direct-to-hub publishing pattern added

Added a second, simpler release pattern alongside the existing per-app
`-pub` mirror repos: an app can publish its release straight into this hub's
own GitHub Releases (tag = app id) instead of maintaining a separate public
sibling repo, when it has no OAuth-homepage or pre-existing update-checker
dependency forcing one. `scripts/sync-releases.sh` now skips the mirror step
for any app whose `apps.json` `repo` field is this hub itself. Documented both
patterns in `AGENTS.md`.

Added AI Scanner (`ai-scanner`) as the first app using this pattern, listed
under category "Beta" (pre-release).

- Hub: https://github.com/jitendrajangidcodes-cloud/app-store
