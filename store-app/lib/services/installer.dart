import 'package:flutter/services.dart';
import '../models/install_status.dart';

// Thin wrapper over the Kotlin MethodChannel in MainActivity. This is the only
// place that talks to the Android package layer.
class Installer {
  static const _channel = MethodChannel("com.pnsjy.store/installer");

  Future<InstalledInfo> installedInfo(String packageId) async {
    final res = await _channel.invokeMapMethod<String, dynamic>(
      "installedInfo",
      {"packageId": packageId},
    );
    if (res == null) return const InstalledInfo();
    return InstalledInfo(
      versionName: res["versionName"] as String?,
      versionCode: (res["versionCode"] as num?)?.toInt(),
    );
  }

  Future<bool> canInstall() async =>
      await _channel.invokeMethod<bool>("canInstall") ?? false;

  // Lands the user on this app's own "install unknown apps" toggle.
  Future<void> openInstallPermissionSettings() async =>
      await _channel.invokeMethod<void>("openInstallPermissionSettings");

  Future<bool> openApp(String packageId) async =>
      await _channel.invokeMethod<bool>("openApp", {"packageId": packageId}) ?? false;

  // Launches the system uninstall dialog; the OS confirms and performs it.
  Future<bool> uninstall(String packageId) async =>
      await _channel.invokeMethod<bool>("uninstallApp", {"packageId": packageId}) ?? false;

  // Hands the downloaded file to the system installer. The OS shows its own
  // confirm dialog -- the store cannot and does not bypass it.
  Future<bool> installApk(String path) async =>
      await _channel.invokeMethod<bool>("installApk", {"path": path}) ?? false;
}
