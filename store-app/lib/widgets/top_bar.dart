import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

// The glass nav bar: the PNSJY company mark shown prominently, the "Store"
// wordmark, and the theme toggle.
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
          if (leading != null) ...[leading!, const SizedBox(width: 10)],
          const BrandLogo(size: 34),
          const SizedBox(width: 12),
          Text("PNSJY", style: sora(17, weight: FontWeight.w800, color: t.text)),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(bottom: 1),
            child: Text("Store", style: sora(15, weight: FontWeight.w600, color: t.muted)),
          ),
          const Spacer(),
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

// The company mark, rounded with a soft shadow. Falls back to a colored tile if
// the asset ever fails to load.
class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: size * 0.4,
            offset: Offset(0, size * 0.15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: Image.asset(
          "assets/brand/pnsjy-mark.png",
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => ColoredBox(color: t.accent),
        ),
      ),
    );
  }
}
