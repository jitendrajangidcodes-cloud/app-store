// One catalog entry, straight from apps.json. Same schema the website reads.
class AppEntry {
  final String id;
  final String name;
  final String tagline;
  final String category;
  final String platform;
  final String colorHex;
  final String? icon;
  final bool requiresAccount;
  final String repo;
  final String packageId;
  final String about;
  final String requirements;
  final List<Screenshot> screenshots;

  const AppEntry({
    required this.id,
    required this.name,
    required this.tagline,
    required this.category,
    required this.platform,
    required this.colorHex,
    required this.icon,
    required this.requiresAccount,
    required this.repo,
    required this.packageId,
    required this.about,
    required this.requirements,
    required this.screenshots,
  });

  factory AppEntry.fromJson(Map<String, dynamic> j) => AppEntry(
        id: j["id"] as String,
        name: j["name"] as String,
        tagline: j["tagline"] as String? ?? "",
        category: j["category"] as String? ?? "",
        platform: j["platform"] as String? ?? "Android",
        colorHex: j["color"] as String? ?? "#2f7ee3",
        icon: j["icon"] as String?,
        requiresAccount: j["requiresAccount"] as bool? ?? false,
        repo: j["repo"] as String? ?? "",
        packageId: j["packageId"] as String? ?? "",
        about: j["about"] as String? ?? "",
        requirements: j["requirements"] as String? ?? "",
        screenshots: (j["screenshots"] as List<dynamic>? ?? [])
            .map((s) => Screenshot.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

class Screenshot {
  final String src;
  final String alt;
  const Screenshot({required this.src, required this.alt});

  factory Screenshot.fromJson(Map<String, dynamic> j) =>
      Screenshot(src: j["src"] as String, alt: j["alt"] as String? ?? "");
}
