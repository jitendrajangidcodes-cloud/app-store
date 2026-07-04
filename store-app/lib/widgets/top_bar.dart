import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'buddy_tile.dart';
import 'glass_card.dart';

// The glass nav bar from the site: wordmark, "live from GitHub Releases" chip,
// and the theme toggle.
class TopBar extends StatelessWidget {
  final VoidCallback onToggleTheme;
  final Widget? leading;
  const TopBar({super.key, required this.onToggleTheme, this.leading});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 8)],
          const BuddyRow(size: 26),
          const SizedBox(width: 10),
          Text("Store", style: sora(15, color: t.text)),
          const Spacer(),
          _LiveChip(),
          const SizedBox(width: 8),
          InkWell(
            onTap: onToggleTheme,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                border: Border.all(color: t.border2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                size: 18,
                color: t.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: t.mint, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text("live from GitHub", style: mono(11, color: t.muted)),
        ],
      ),
    );
  }
}
