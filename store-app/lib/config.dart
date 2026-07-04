// Single source of truth for where the store reads from. The catalog and
// manifest come from the live site, so adding an app to apps.json makes it
// appear here with no store rebuild.
class Config {
  static const siteBase =
      "https://jitendrajangidcodes-cloud.github.io/app-store";
  static const appsUrl = "$siteBase/apps.json";
  static const manifestUrl = "$siteBase/releases.json";

  // The store's own repo, used only for self-update. Safe if it does not exist
  // yet: the self-update check simply finds no newer release and stays quiet.
  static const storeRepo = "jitendrajangidcodes-cloud/pnsjy-store";
  static const storePackageId = "com.pnsjy.store";

  // Feedback/suggestions/bug reports open a prefilled issue here. No backend,
  // no secrets: GitHub owns identity and spam handling.
  static const feedbackRepo = "jitendrajangidcodes-cloud/app-store";
}
