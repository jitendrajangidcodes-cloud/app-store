# Features

## Website (existing)
- Catalog of Android apps from apps.json [VERIFIED]
- Live version/download/release-notes per app from GitHub Releases [VERIFIED]
- Light/dark theme with glass + glow design [VERIFIED]

## PNSJY Store (in progress)
- releases.json manifest generated in CI from apps.json + Releases [BUILT-AWAITING-VERIFY]
- Website consumes releases.json (one fetch) with live-API fallback [BUILT-AWAITING-VERIFY]
- "Download the PNSJY Store app" entry on site [TODO]
- Flutter Android store app mirroring web UI/theme/animation [TODO]
- Per-app Install / Update / Open state from installed version [TODO]
- One-tap system-installer APK install + update [TODO]
- Store self-update from its own Releases [BUILT-AWAITING-VERIFY]
- Background update notifications (WorkManager, 6h) [BUILT-AWAITING-VERIFY]
- Feedback / Suggest / Report bug -> prefilled GitHub issue, on site + app [BUILT-AWAITING-VERIFY]
- Star ratings [DEFERRED — needs Firebase/DB]

## Single-repo hub (app-store hosts every APK)
- All app + store APKs mirrored into app-store Releases under stable tags [BUILT-AWAITING-VERIFY]
- CI mirror (sync-releases.sh) idempotent; only moves bytes on a real bump [BUILT-AWAITING-VERIFY]
- Manifest + APKs same-repo -> refreshed in one CI run, 30-min cron [BUILT-AWAITING-VERIFY]
- Web, store app, and self-update all read from the one hub repo [BUILT-AWAITING-VERIFY]
- No cross-repo token; app build repos untouched; keystore stays gitignored [VERIFIED]

## Store UX
- Store self-update shows live download progress + errors (not a dead tap) [BUILT-AWAITING-VERIFY]
- Single merged brand header on the store home (no duplicate logo block) [BUILT-AWAITING-VERIFY]
- Pull-to-refresh updates in place, no web-reload flash (gapless images) [BUILT-AWAITING-VERIFY]
