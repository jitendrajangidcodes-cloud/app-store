import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../data/catalog_repository.dart';
import '../models/install_status.dart';
import 'installer.dart';
import 'notifications.dart';
import 'update_service.dart';

const _taskName = "pnsjy-update-check";

// Runs periodically even when the store is closed: refreshes the manifest,
// recomputes update states, and notifies about anything new. "New" is tracked
// per app+version in prefs so the same update is not announced twice.
class Background {
  static Future<void> register() async {
    await Workmanager().initialize(callbackDispatcher);
    await Workmanager().registerPeriodicTask(
      _taskName,
      _taskName,
      frequency: const Duration(hours: 6),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }
}

@pragma("vm:entry-point")
void callbackDispatcher() {
  Workmanager().executeTask((_, _) async {
    try {
      await Notifications.init();
      final catalog = await CatalogRepository().load();
      final statuses = await UpdateService(Installer()).statusForAll(catalog);

      final prefs = await SharedPreferences.getInstance();
      final fresh = <String>[];
      for (final app in catalog.apps) {
        final s = statuses[app.id];
        if (s == null || s.state != InstallState.updateAvailable) continue;
        final key = "notified_${app.id}";
        if (prefs.getString(key) == s.latest!.version) continue;
        prefs.setString(key, s.latest!.version);
        fresh.add(app.name);
      }
      await Notifications.showUpdates(fresh);
      return true;
    } catch (_) {
      return false;
    }
  });
}
