# PNSJY Store

Native Android store app for Jitendra's apps. It mirrors the website's design and installs /
updates every listed app through the system installer, and updates itself the same way.

## What it does
- Reads `apps.json` + `releases.json` from the live site (same data as the website).
- Shows per-app Install / Update / Open state from the installed version.
- Downloads the APK (with a progress bar) and hands it to the system installer.
- Self-updates from the hub repo's `store` release tag.
- Background check (WorkManager) notifies when an app has an update.
- Feedback / suggestions / bug reports open a prefilled GitHub issue.

## Distribution
All APKs — including this app's own build — are published as GitHub Releases in the parent
`app-store` hub repo under stable tags (`reminder`, `cards`, `store`). This app reads from
that one hub. See `../AGENTS.md` for the release flow.

## Build
```
flutter pub get
flutter analyze
flutter build apk --release   # needs android/key.properties + the gitignored keystore
```
The keystore and `key.properties` are gitignored and must never be committed.
