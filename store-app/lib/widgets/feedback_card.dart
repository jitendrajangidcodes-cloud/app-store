import 'package:flutter/material.dart';
import '../services/feedback_links.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

// Suggest / Report bug / Send feedback, each opening a prefilled GitHub issue.
// appName/appId scope the issue to one app; omit for general store feedback.
class FeedbackCard extends StatelessWidget {
  final String? appName;
  final String? appId;
  const FeedbackCard({super.key, this.appName, this.appId});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(appName == null ? "Feedback & ideas" : "Feedback on $appName",
              style: sora(20, color: t.text)),
          const SizedBox(height: 6),
          Text("Opens a GitHub issue — no account data shared.",
              style: dmSans(13, color: t.muted)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _btn(context, Icons.lightbulb_outline_rounded, "Suggest",
                  FeedbackType.suggestion),
              _btn(context, Icons.bug_report_outlined, "Report bug", FeedbackType.bug),
              _btn(context, Icons.chat_bubble_outline_rounded, "Feedback",
                  FeedbackType.feedback),
            ],
          ),
        ],
      ),
    );
  }

  Widget _btn(BuildContext context, IconData icon, String label, FeedbackType type) {
    final t = context.tokens;
    return OutlinedButton.icon(
      onPressed: () => FeedbackLinks.open(type, appName: appName, appId: appId),
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: t.text,
        side: BorderSide(color: t.border2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
