# Releases

Distribution: this app has no separate source repo -- it lives inside the
`app-store` hub itself and publishes straight to the hub's own GitHub
Releases under the stable tag `store` (see `../AGENTS.md`). Self-update reads
that same tag directly (`lib/services/self_update.dart` / `lib/config.dart`).

## v1.0.3+4 (2026-07-04)

- Update button now shows live download progress and reports errors (no more
  dead-looking tap)
- Single, cleaner brand header on the home screen
- Pull-to-refresh updates in place instead of flashing like a web reload
- Installs every app and its own updates from the one hub

- Hub: https://github.com/jitendrajangidcodes-cloud/app-store/releases/tag/store
