# Download log (Google Sheet via Apps Script)

Free, no-backend way to log who downloads/installs from the app-store website
and the native Store app, straight into a Google Sheet in your own Drive.

## Why Apps Script instead of the Sheets API directly

The Sheets API needs a credential (service account key or OAuth token) to
write. Embedding that credential in a public website's JS or inside a
distributed APK would let anyone extract it and read/write your Sheet, or
worse depending on the key's scope. A Google Apps Script **Web App** avoids
this entirely: the script runs server-side under your account, and only a
plain URL is exposed publicly -- it can only do what the script lets it do
(here: append a row), never anything else in your Drive.

## Setup

See the header comment in `Code.gs` for the exact steps. In short: paste
`Code.gs` into a new Apps Script project bound to your target Sheet, deploy
as a Web App (**Execute as: Me**, **Who has access: Anyone**), and copy the
resulting `.../exec` URL.

## What gets logged

One row per first-time download/install, with an honest, disclosed set of
fields: name, optional email, app, platform (web or store-app), and
device/browser info (model, manufacturer, OS + version for the store app;
User-Agent, screen size, timezone, language for the website -- browsers
don't expose device model/manufacturer to JS).

This is deliberately scoped to the app-store distribution surface (the
website + the native Store app) only -- it does not touch AI Scanner, Cards,
or Reminder, which each separately promise "no analytics" in their own UI.

## Where the URL is used

- `script.js` (website): `DOWNLOAD_LOG_URL` constant.
- `store-app/lib/services/log_service.dart`: `_endpoint` constant.

Both are fire-and-forget POSTs (`no-cors` on the web side, since Apps
Script's redirect-based response can't be read cross-origin anyway) -- a
failed log never blocks or delays the actual download.
