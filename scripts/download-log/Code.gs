// Google Apps Script Web App -- appends one row per download/install
// submission to whatever Google Sheet this script is bound to. Runs entirely
// under your own Google account; the deployed URL is the only thing that's
// public, and it can only append rows, never read the sheet back or touch
// anything else in your Drive.
//
// Setup (one-time):
//   1. Open (or create) the Google Sheet you want rows to land in.
//   2. Extensions -> Apps Script.
//   3. Delete the placeholder code, paste this whole file in, save.
//   4. Deploy -> New deployment -> type "Web app".
//      - Execute as: Me
//      - Who has access: Anyone
//   5. Copy the resulting web app URL (ends in /exec) -- that's DOWNLOAD_LOG_URL,
//      used by both the website (script.js) and the store app (log_service.dart).
//   6. If you ever edit this script, you must create a NEW deployment (or use
//      "Manage deployments" -> edit -> new version) for changes to take effect;
//      editing the code alone does not update the live /exec URL's behavior.

function doPost(e) {
  var lock = LockService.getScriptLock();
  lock.waitLock(10000);
  try {
    var data = JSON.parse(e.postData.contents);
    var sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();

    if (sheet.getLastRow() === 0) {
      sheet.appendRow([
        'Timestamp', 'App', 'Platform', 'Name', 'Email',
        'Device Model', 'Manufacturer', 'OS', 'OS Version',
        'Browser / User-Agent', 'Screen', 'Timezone', 'Language',
      ]);
    }

    sheet.appendRow([
      new Date(),
      data.app || '',
      data.platform || '',
      data.name || '',
      data.email || '',
      data.deviceModel || '',
      data.manufacturer || '',
      data.os || '',
      data.osVersion || '',
      data.userAgent || '',
      data.screen || '',
      data.timezone || '',
      data.language || '',
    ]);

    return ContentService.createTextOutput(JSON.stringify({ ok: true }))
      .setMimeType(ContentService.MimeType.JSON);
  } catch (err) {
    return ContentService.createTextOutput(JSON.stringify({ ok: false, error: String(err) }))
      .setMimeType(ContentService.MimeType.JSON);
  } finally {
    lock.releaseLock();
  }
}

function doGet(e) {
  return ContentService.createTextOutput('OK');
}
