import 'package:flutter/material.dart';
import '../models/app_entry.dart';
import '../models/install_status.dart';
import '../theme/app_theme.dart';
import 'app_icon.dart';
import 'glass_card.dart';
import 'install_button.dart';

// Catalog tile mirroring the web .app-card: icon + name, tagline, action pill,
// and the account chip.
class AppCard extends StatelessWidget {
  final AppEntry app;
  final AppStatus? status;
  final VoidCallback onOpen;
  const AppCard({
    super.key,
    required this.app,
    required this.status,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GlassCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(app: app, size: 58),
              const SizedBox(width: 16),
              Expanded(
                child: Text(app.name, style: sora(19, color: t.text)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(app.tagline, style: dmSans(14, color: t.muted)),
          const SizedBox(height: 16),
          Row(
            children: [
              if (status != null)
                Flexible(child: InstallButton(app: app, status: status!, fontSize: 13)),
              const SizedBox(width: 10),
              Flexible(
                child: Text("${app.category} · Android 8+",
                    style: dmSans(12, color: t.muted),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _AccountChip(requiresAccount: app.requiresAccount),
        ],
      ),
    );
  }
}

class _AccountChip extends StatelessWidget {
  final bool requiresAccount;
  const _AccountChip({required this.requiresAccount});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final accent = !requiresAccount;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent ? t.chip : Colors.transparent,
        border: accent ? null : Border.all(color: t.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        requiresAccount ? "Requires Google sign-in" : "No account needed",
        style: mono(11, color: accent ? t.chipText : t.muted),
      ),
    );
  }
}
