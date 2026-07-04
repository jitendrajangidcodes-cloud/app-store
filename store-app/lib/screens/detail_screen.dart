import 'package:flutter/material.dart';
import '../data/catalog_repository.dart';
import '../models/app_entry.dart';
import '../models/install_status.dart';
import '../services/downloader.dart';
import '../services/installer.dart';
import '../services/update_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icon.dart';
import '../widgets/feedback_card.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_background.dart';
import '../widgets/install_button.dart';
import '../widgets/top_bar.dart';

class DetailScreen extends StatefulWidget {
  final AppEntry app;
  final AppStatus? status;
  final VoidCallback onToggleTheme;
  const DetailScreen({
    super.key,
    required this.app,
    required this.status,
    required this.onToggleTheme,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> with WidgetsBindingObserver {
  final _updates = UpdateService(Installer());
  late AppStatus? _status = widget.status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Downloader().cleanupApks();
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final catalog = await CatalogRepository().load();
    final status = await _updates.statusFor(widget.app, catalog);
    if (mounted) setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final app = widget.app;
    final latest = _status?.latest;

    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              TopBar(
                onToggleTheme: widget.onToggleTheme,
                leading: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Icon(Icons.arrow_back_rounded, color: t.text, size: 20),
                ),
              ),
              const SizedBox(height: 20),
              _head(context),
              if (app.screenshots.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text("Screenshots", style: sora(20, color: t.text)),
                const SizedBox(height: 14),
                _screenshots(app),
              ],
              const SizedBox(height: 24),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("About", style: sora(20, color: t.text)),
                    const SizedBox(height: 12),
                    Text(app.about, style: dmSans(15, color: t.muted)),
                    const SizedBox(height: 12),
                    Text(app.requirements, style: mono(12, color: t.muted)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Latest release", style: sora(20, color: t.text)),
                    const SizedBox(height: 14),
                    if (latest != null) ...[
                      Row(children: [
                        _chip(context, "v${latest.version}", accent: true),
                        const SizedBox(width: 8),
                        _chip(context, latest.sizeLabel),
                      ]),
                      const SizedBox(height: 12),
                      Text(
                        latest.notes.isEmpty ? "No release notes." : latest.notes,
                        style: dmSans(14, color: t.muted),
                      ),
                    ] else
                      Text("Release info unavailable right now.",
                          style: dmSans(14, color: t.muted)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _installSteps(context),
              const SizedBox(height: 20),
              FeedbackCard(appName: app.name, appId: app.id),
            ],
          ),
        ),
      ),
    );
  }

  Widget _head(BuildContext context) {
    final t = context.tokens;
    final app = widget.app;
    return GlassCard(
      radius: 26,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcon(app: app, size: 84),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.name, style: sora(28, weight: FontWeight.w800, color: t.text)),
                    const SizedBox(height: 6),
                    Text(app.tagline, style: dmSans(14, color: t.muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _chip(context, app.platform),
            _chip(context, app.category),
            _chip(context, app.requiresAccount ? "Google sign-in" : "No account",
                accent: !app.requiresAccount),
          ]),
          const SizedBox(height: 18),
          if (_status != null) ...[
            InstallButton(app: app, status: _status!, fontSize: 16),
            if (_status!.installed.isInstalled) ...[
              const SizedBox(height: 12),
              _uninstallButton(context, app.packageId),
            ],
          ],
        ],
      ),
    );
  }

  Widget _uninstallButton(BuildContext context, String packageId) {
    return TextButton.icon(
      onPressed: () => Installer().uninstall(packageId),
      icon: const Icon(Icons.delete_outline_rounded, size: 18),
      label: const Text("Uninstall"),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFd73a4a),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }

  Widget _screenshots(AppEntry app) {
    return SizedBox(
      height: 380,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: app.screenshots.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (_, i) => ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(
            resolveAsset(app.screenshots[i].src),
            width: 210,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => const SizedBox(width: 210),
          ),
        ),
      ),
    );
  }

  Widget _installSteps(BuildContext context) {
    final t = context.tokens;
    const steps = [
      "Tap Get APK / Update above",
      "Allow install from this source if prompted",
      "Open the file and tap Install",
    ];
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Install in 3 steps", style: sora(20, color: t.text)),
          const SizedBox(height: 16),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: t.brandGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Text("${i + 1}",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(steps[i], style: dmSans(14, color: t.muted))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, {bool accent = false}) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent ? t.chip : Colors.transparent,
        border: accent ? null : Border.all(color: t.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: mono(11, color: accent ? t.chipText : t.muted)),
    );
  }
}
