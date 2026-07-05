import 'package:flutter/material.dart';

import '../services/log_service.dart';
import '../theme/app_theme.dart';

/// Shown once, before the very first download from this store. Required (no
/// skip) -- name is mandatory, email optional. Disclosed plainly: this data
/// is what makes the "who's using this" tracking possible, and only applies
/// to this store app, not the apps it installs.
class InfoGateSheet extends StatefulWidget {
  const InfoGateSheet({super.key});

  /// Returns true once info was submitted, false if the sheet was dismissed
  /// without submitting (caller should not proceed with the download).
  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => const InfoGateSheet(),
    );
    return result ?? false;
  }

  @override
  State<InfoGateSheet> createState() => _InfoGateSheetState();
}

class _InfoGateSheetState extends State<InfoGateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await LogService().saveInfo(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Before you download', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: t.text)),
            const SizedBox(height: 8),
            Text(
              'We ask for your name (and optionally email) once, so we know who\'s '
              'using these apps. Basic device info is recorded alongside it. This '
              'store keeps its own log, separate from any app it installs.',
              style: TextStyle(fontSize: 13.5, color: t.muted, height: 1.4),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email (optional)'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
