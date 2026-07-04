# Jitendra — App Store

**Live site: https://jitendrajangidcodes-cloud.github.io/app-store/**

A personal catalog of apps built by Jitendra, browsable and installable directly — no store
review, no accounts. There is also a native **PNSJY Store** Android app that installs and
updates every listed app like an app store, and keeps itself up to date.

## Single-repo hub

This repository is the one public hub for distribution. Every APK — each listed app plus the
store app itself — is published here as a GitHub Release under a stable tag (`reminder`,
`cards`, `store`). The website, the store app, and the store's self-update all read from this
one repo, and `releases.json` is regenerated here whenever a new build is mirrored in — so the
site and the store always reflect the latest shipped version.

Distribution is centralized, but **security is not compromised**: CI only ever writes this repo
using the built-in token, reads the source repos unauthenticated, and the signing keystore and
its `key.properties` are gitignored and never committed. No tokens, credentials, or logins live
in the repo.

New apps are never added automatically — an app is only listed when explicitly added to
`apps.json`. See `AGENTS.md` for the full layout and release flow.
