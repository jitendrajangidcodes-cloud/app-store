import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Logs who downloads/installs from this store into a Google Sheet, via a
/// Google Apps Script Web App (see scripts/download-log/ in the repo root
/// for the script source and setup steps). Deliberately scoped to this store
/// app only -- AI Scanner, Cards, and Reminder each separately promise "no
/// analytics" and are untouched by this.
///
/// Collected once per device (name + optional email), then persisted --
/// every subsequent download only logs which app + device info, not asked
/// again. Fire-and-forget: a failed log never blocks or delays the install.
class LogService {
  static const _endpoint =
      'REPLACE_WITH_YOUR_APPS_SCRIPT_EXEC_URL';

  static const _nameKey = 'log_name';
  static const _emailKey = 'log_email';

  Future<bool> hasSubmittedInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey) != null;
  }

  Future<void> saveInfo({required String name, String? email}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
    if (email != null && email.isNotEmpty) await prefs.setString(_emailKey, email);
  }

  Future<void> logDownload(String appId) async {
    if (_endpoint.startsWith('REPLACE_WITH')) return; // not configured yet
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_nameKey) ?? '';
      final email = prefs.getString(_emailKey) ?? '';
      final device = await _deviceInfo();

      await http
          .post(
            Uri.parse(_endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'app': appId,
              'platform': 'store-app',
              'name': name,
              'email': email,
              ...device,
            }),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // Best-effort -- never let logging failure affect the actual download.
    }
  }

  Future<Map<String, String>> _deviceInfo() async {
    try {
      if (!Platform.isAndroid) return {'os': Platform.operatingSystem};
      final info = await DeviceInfoPlugin().androidInfo;
      return {
        'deviceModel': info.model,
        'manufacturer': info.manufacturer,
        'os': 'Android',
        'osVersion': info.version.release,
      };
    } catch (_) {
      return {};
    }
  }
}
