import 'package:flutter/material.dart';
import '../data/catalog_repository.dart';
import '../models/app_entry.dart';
import 'buddy_tile.dart';

// The app's real icon (apps.json `icon`, resolved against the site) with the
// branded letter tile shown behind it -- so while it loads or if it fails, the
// colored first-letter tile shows instead of a blank box.
class AppIcon extends StatelessWidget {
  final AppEntry app;
  final double size;
  const AppIcon({super.key, required this.app, required this.size});

  @override
  Widget build(BuildContext context) {
    final fallback = BuddyTile(
      ch: app.name.substring(0, 1).toUpperCase(),
      bg: hexColor(app.colorHex),
      fg: Colors.white,
      size: size,
    );
    if (app.icon == null) return fallback;

    final radius = size * 0.24;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            fallback,
            Image.network(
              resolveAsset(app.icon!),
              fit: BoxFit.cover,
              // Keep the decoded icon on screen across rebuilds (e.g. a pull-to-
              // refresh) so it never blanks back to the fallback and flashes.
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
              frameBuilder: (_, child, frame, wasSync) =>
                  frame == null && !wasSync ? const SizedBox.shrink() : child,
            ),
          ],
        ),
      ),
    );
  }
}
