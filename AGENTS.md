# AGENTS.md — app-store

Personal app catalog (GitHub Pages) plus a Flutter Android "store" app that installs
and updates the listed apps.

## Layout
- `index.html` / `app.html` / `script.js` / `style.css` — the static website
- `apps.json` — the ONE source of truth: every listed app (its `repo` is the build/source
  repo). Adding an entry here makes it appear on the website AND in the store app. Never add
  an app anywhere else.
- `releases.json` — generated in CI; latest version + hub APK url per app. Do not hand-edit.
- `scripts/sync-releases.sh` — mirrors each app's latest source APK into THIS repo's Releases.
- `scripts/build-manifest.mjs` — regenerates `releases.json` from THIS repo's hub Releases.
- `store-app/` — Flutter Android store app. Fetches apps.json + releases.json from the
  live site and installs/updates apps via the system installer.

## Single-repo hub (how releases flow)
- This repo is the ONE public hub. Every APK — `reminder`, `cards`, and the store app itself
  (`store`) — is published as a Release here under a stable tag equal to that name. The human
  version lives in the release NAME; the APK is the release asset.
- The website, the store app, and the store's self-update ALL read from this repo. Because the
  APKs and `releases.json` live together, `.github/workflows/sync-releases.yml` mirrors + rebuilds
  the manifest in one run (30-min cron + manual + on relevant push), so a new source release
  propagates within one tick. No cross-repo token; app build repos are never modified.
- To ship a new store build: `flutter build apk --release`, then publish the APK to the `store`
  tag here (title = `<name>+<code>`). Keep a bridge copy in the legacy `pnsjy-store` repo only
  until every install has moved past `1.0.0+1`.

## Conventions
- Design tokens (colors, fonts, animations) are defined once in `style.css` `:root`
  blocks; the Flutter app mirrors them in `store-app/lib/theme/`. Keep the two in sync.
- Hub release NAME carries the version as `<name>+<code>` (e.g. `1.2.3+45`) so the manifest
  can carry a numeric versionCode. Name-only still works (semver fallback).
- No credentials in the repo. CI uses the built-in `GITHUB_TOKEN` only (writes THIS repo,
  reads source repos unauthenticated). Keystore + `key.properties` are gitignored; never commit.

## Verify
- Mirror + manifest: `bash scripts/sync-releases.sh && node scripts/build-manifest.mjs`
  (needs network + gh auth) then inspect `releases.json`.
- Flutter: `cd store-app && flutter analyze && flutter build apk --debug`.
