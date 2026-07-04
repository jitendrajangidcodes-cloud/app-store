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
