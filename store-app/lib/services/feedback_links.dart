import 'package:url_launcher/url_launcher.dart';
import '../config.dart';

enum FeedbackType { feedback, suggestion, bug }

extension on FeedbackType {
  String get label => switch (this) {
        FeedbackType.feedback => "feedback",
        FeedbackType.suggestion => "suggestion",
        FeedbackType.bug => "bug",
      };
  String get title => switch (this) {
        FeedbackType.feedback => "Feedback",
        FeedbackType.suggestion => "Suggestion",
        FeedbackType.bug => "Bug report",
      };
}

// Opens a prefilled GitHub issue. Nothing sensitive is included -- only the app
// name, type, and an empty prompt the user fills in. Uri handles all encoding,
// so titles/bodies cannot break the URL or inject query params.
class FeedbackLinks {
  static Future<bool> open(FeedbackType type, {String? appName, String? appId}) {
    final scope = appName != null ? " for $appName" : "";
    final uri = Uri.https("github.com", "/${Config.feedbackRepo}/issues/new", {
      "title": "${type.title}$scope: ",
      "labels": [type.label, ?appId].join(","),
      "body": _bodyTemplate(type, appName),
    });
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static String _bodyTemplate(FeedbackType type, String? appName) {
    final target = appName != null ? "**App:** $appName\n\n" : "";
    return switch (type) {
      FeedbackType.bug =>
        "$target**What happened:**\n\n**Steps to reproduce:**\n\n**Device / Android version:**\n",
      FeedbackType.suggestion => "$target**What would you like to see:**\n",
      FeedbackType.feedback => "$target**Your feedback:**\n",
    };
  }
}
