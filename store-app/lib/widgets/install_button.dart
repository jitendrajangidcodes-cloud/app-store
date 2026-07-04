import 'package:flutter/material.dart';
import '../models/app_entry.dart';
import '../models/install_status.dart';
import '../services/downloader.dart';
import '../services/installer.dart';
import '../theme/app_theme.dart';
import 'gradient_button.dart';

// Renders one app's action from its AppStatus and drives the download+install
// flow. Install/Update download the APK (with a progress bar) then hand it to
// the system installer; Open launches the already-installed app.
class InstallButton extends StatefulWidget {
  final AppEntry app;
  final AppStatus status;
  final double fontSize;
  const InstallButton({
    super.key,
    required this.app,
    required this.status,
    this.fontSize = 15,
  });

  @override
  State<InstallButton> createState() => _InstallButtonState();
}

class _InstallButtonState extends State<InstallButton> {
  final _installer = Installer();
  final _downloader = Downloader();
  bool _busy = false;
  double _progress = 0;

  Future<void> _installOrUpdate() async {
    final latest = widget.status.latest;
    if (latest?.apkUrl == null || _busy) return;
    setState(() {
      _busy = true;
      _progress = 0;
    });
    try {
      final file = await _downloader.download(
        latest!.apkUrl!,
        "${widget.app.id}-${latest.version}.apk",
        onProgress: (p) => setState(() => _progress = p),
      );
      await _installer.installApk(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Download failed: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (_busy) {
      return _ProgressPill(progress: _progress, color: t.accent, track: t.glass2);
    }

    final latest = widget.status.latest;
    switch (widget.status.state) {
      case InstallState.notInstalled:
        return GradientButton(
          label: "Get APK${latest?.sizeBytes != null ? ' · ${latest!.sizeLabel}' : ''}",
          icon: Icons.download_rounded,
          fontSize: widget.fontSize,
          onTap: _installOrUpdate,
        );
      case InstallState.updateAvailable:
        return GradientButton(
          label: "Update · v${latest!.version}",
          icon: Icons.upgrade_rounded,
          fontSize: widget.fontSize,
          onTap: _installOrUpdate,
        );
      case InstallState.upToDate:
        return _OpenButton(
          onTap: () => _installer.openApp(widget.app.packageId),
          fontSize: widget.fontSize,
        );
      case InstallState.unknown:
        return GradientButton(
          label: "Unavailable",
          fontSize: widget.fontSize,
          onTap: null,
        );
    }
  }
}

class _OpenButton extends StatelessWidget {
  final VoidCallback onTap;
  final double fontSize;
  const _OpenButton({required this.onTap, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: t.text,
        side: BorderSide(color: t.border2),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 18),
          const SizedBox(width: 8),
          Text("Open", style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ProgressPill extends StatelessWidget {
  final double progress;
  final Color color;
  final Color track;
  const _ProgressPill({required this.progress, required this.color, required this.track});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: LinearProgressIndicator(
              value: progress > 0 ? progress : null,
              minHeight: 48,
              backgroundColor: track,
              valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.6)),
            ),
          ),
          Text(
            progress > 0 ? "Downloading ${(progress * 100).round()}%" : "Starting…",
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
