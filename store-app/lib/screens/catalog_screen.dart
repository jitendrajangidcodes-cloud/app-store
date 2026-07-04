import 'package:flutter/material.dart';
import '../data/catalog_repository.dart';
import '../models/install_status.dart';
import '../models/release_info.dart';
import '../services/downloader.dart';
import '../services/installer.dart';
import '../services/self_update.dart';
import '../services/update_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/feedback_card.dart';
import '../widgets/glass_card.dart';
import '../widgets/glow_background.dart';
import '../widgets/gradient_button.dart';
import '../widgets/top_bar.dart';
import 'detail_screen.dart';

class CatalogScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const CatalogScreen({super.key, required this.onToggleTheme});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen>
    with WidgetsBindingObserver {
  final _repo = CatalogRepository();
  final _updates = UpdateService(Installer());

  Catalog? _catalog;
  Map<String, AppStatus> _statuses = {};
  ReleaseInfo? _selfUpdate;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Coming back from a system install dialog: recompute states so a freshly
  // installed/updated app flips to Open without a manual refresh.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _catalog != null) _refreshStatuses();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final catalog = await _repo.load();
      final statuses = await _updates.statusForAll(catalog);
      final self = await SelfUpdate().check();
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _statuses = statuses;
        _selfUpdate = self;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "$e";
        _loading = false;
      });
    }
  }

  Future<void> _refreshStatuses() async {
    final catalog = _catalog;
    if (catalog == null) return;
    final statuses = await _updates.statusForAll(catalog);
    if (mounted) setState(() => _statuses = statuses);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            child: _body(),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    final t = context.tokens;
    if (_loading) {
      return ListView(children: [
        const SizedBox(height: 240),
        Center(child: CircularProgressIndicator(color: t.accent)),
      ]);
    }
    if (_error != null) {
      return ListView(children: [
        const SizedBox(height: 200),
        Center(child: Text("Could not load catalog.\n$_error",
            textAlign: TextAlign.center, style: dmSans(14, color: t.muted))),
      ]);
    }

    final apps = _catalog!.apps;
    final updateCount = _statuses.values
        .where((s) => s.state == InstallState.updateAvailable)
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        TopBar(onToggleTheme: widget.onToggleTheme),
        const SizedBox(height: 24),
        Text("Apps I've built,", style: sora(30, weight: FontWeight.w800, color: t.text)),
        ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: [Color(0xFFE8632C), Color(0xFF8A56D6)],
          ).createShader(r),
          child: Text("ready to install.",
              style: sora(30, weight: FontWeight.w800, color: Colors.white)),
        ),
        const SizedBox(height: 12),
        Text(
          "Direct APK installs, updated the moment a new release ships.",
          style: dmSans(15, color: t.muted),
        ),
        const SizedBox(height: 20),
        if (_selfUpdate != null) ...[
          _SelfUpdateBanner(release: _selfUpdate!, onDone: _refreshStatuses),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Text("All apps", style: sora(22, color: t.text)),
            const SizedBox(width: 12),
            Text(
              updateCount > 0 ? "$updateCount update${updateCount > 1 ? 's' : ''}" : "${apps.length} apps",
              style: mono(12, color: updateCount > 0 ? t.accent : t.muted),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (final app in apps)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AppCard(
              app: app,
              status: _statuses[app.id],
              onOpen: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailScreen(
                    app: app,
                    status: _statuses[app.id],
                    onToggleTheme: widget.onToggleTheme,
                  ),
                ),
              ).then((_) => _refreshStatuses()),
            ),
          ),
        const SizedBox(height: 8),
        const FeedbackCard(),
      ],
    );
  }
}

class _SelfUpdateBanner extends StatelessWidget {
  final ReleaseInfo release;
  final VoidCallback onDone;
  const _SelfUpdateBanner({required this.release, required this.onDone});

  Future<void> _update(BuildContext context) async {
    try {
      final file = await Downloader()
          .download(release.apkUrl!, "pnsjy-store-${release.version}.apk");
      await Installer().installApk(file.path);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GlassCard(
      radius: 18,
      child: Row(
        children: [
          Icon(Icons.system_update_rounded, color: t.accent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Store update available", style: sora(15, color: t.text)),
                Text("Version ${release.version}", style: dmSans(13, color: t.muted)),
              ],
            ),
          ),
          GradientButton(
            label: "Update",
            fontSize: 13,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            onTap: () => _update(context),
          ),
        ],
      ),
    );
  }
}
