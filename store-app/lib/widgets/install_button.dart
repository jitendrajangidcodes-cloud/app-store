import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import '../models/app_entry.dart';
import '../models/install_status.dart';
import '../services/downloader.dart';
import '../services/installer.dart';
import '../services/log_service.dart';
import '../theme/app_theme.dart';
import 'gradient_button.dart';
import 'info_gate_sheet.dart';

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

class _InstallButtonState extends State<InstallButton> with WidgetsBindingObserver {
  final _installer = Installer();
  final _downloader = Downloader();
  bool _busy = false;
  double _progress = 0;
  String? _error;
  bool _needsPermission = false;
  File? _downloadedFile;

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

  // Coming back from the "install unknown apps" settings screen: the file is
  // already downloaded, so just retry the install handoff -- never re-download.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _needsPermission && _downloadedFile != null) {
      unawaited(_tryInstall(_downloadedFile!));
    }
  }

  Future<void> _tryInstall(File file) async {
    if (!await _installer.canInstall()) {
      if (mounted) setState(() { _needsPermission = true; _downloadedFile = file; });
      return;
    }
    if (mounted) setState(() { _needsPermission = false; _downloadedFile = null; });
    await _installer.installApk(file.path);
  }

  Future<void> _installOrUpdate() async {
    final latest = widget.status.latest;
    if (latest?.apkUrl == null || _busy) return;

    if (!await LogService().hasSubmittedInfo()) {
      if (!mounted) return;
      final submitted = await InfoGateSheet.show(context);
      if (!submitted) return;
    }
    unawaited(LogService().logDownload(widget.app.id));

    setState(() {
      _busy = true;
      _progress = 0;
      _error = null;
      _needsPermission = false;
    });
    try {
      final file = await _downloader.download(
        latest!.apkUrl!,
        "${widget.app.id}-${latest.version}.apk",
        onProgress: (p) => mounted ? setState(() => _progress = p) : null,
      );
      await _tryInstall(file);
    } catch (e) {
      // The partial file stays on disk (see Downloader) -- retrying resumes
      // instead of starting over, which matters for a Wi-Fi/mobile-data
      // switch or a dropped connection mid-download, not just a hard failure.
      if (mounted) setState(() => _error = "Download interrupted");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (_needsPermission) {
      return _PermissionPrompt(
        onOpenSettings: () => unawaited(_installer.openInstallPermissionSettings()),
      );
    }
    if (_error != null) {
      return _RetryPill(message: _error!, onRetry: _installOrUpdate, color: t.accent);
    }
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

// Shown when the APK finished downloading but Android's "install unknown
// apps" permission isn't granted yet for this store -- without this,
// firing the install intent blindly gets silently blocked by the OS with
// its own warning screen instead of the real install prompt ever appearing.
class _PermissionPrompt extends StatelessWidget {
  final VoidCallback onOpenSettings;
  const _PermissionPrompt({required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onOpenSettings,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white70),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.settings_outlined, size: 18),
          SizedBox(width: 8),
          Flexible(child: Text("Allow installs — tap to open Settings", overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

// A dropped connection (Wi-Fi/mobile data switch, signal loss) lands here
// instead of a transient toast -- retrying resumes from the partial file
// (see Downloader) rather than starting the whole download over.
class _RetryPill extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final Color color;
  const _RetryPill({required this.message, required this.onRetry, required this.color});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onRetry,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.refresh_rounded, size: 18),
          const SizedBox(width: 8),
          Flexible(child: Text("$message — Retry", overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
