import 'package:flutter/material.dart';
import 'services/background.dart';
import 'services/downloader.dart';
import 'services/notifications.dart';
import 'screens/catalog_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'theme/tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final theme = ThemeController();
  await theme.load();
  await Notifications.init();
  Downloader().cleanupApks();
  // Background registration is best-effort; a failure here must not block the UI.
  try {
    await Background.register();
  } catch (_) {}
  runApp(StoreApp(theme: theme));
}

class StoreApp extends StatelessWidget {
  final ThemeController theme;
  const StoreApp({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: theme,
      builder: (context, mode, _) {
        return MaterialApp(
          title: "PNSJY Store",
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: buildTheme(Tokens.light, Brightness.light),
          darkTheme: buildTheme(Tokens.dark, Brightness.dark),
          home: Builder(
            builder: (context) => CatalogScreen(
              onToggleTheme: () => theme.toggle(Theme.of(context).brightness),
            ),
          ),
        );
      },
    );
  }
}
