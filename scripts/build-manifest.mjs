// Regenerates releases.json from the HUB repo's own Releases. Each app has a
// stable hub tag equal to its id (see scripts/sync-releases.sh); the human
// version lives in the release NAME. Run in CI after the mirror step, or locally
// with network. GITHUB_TOKEN is optional (lifts rate limit); no secrets are
// written to output -- only public release metadata.

import { readFile, writeFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const hub = process.env.HUB_REPO || "jitendrajangidcodes-cloud/app-store-web";
const token = process.env.GITHUB_TOKEN || "";

const headers = {
  Accept: "application/vnd.github+json",
  "X-GitHub-Api-Version": "2022-11-28",
  ...(token ? { Authorization: `Bearer ${token}` } : {}),
};

// Hub release name is v<name>+<code> or just <name>. Split so the store can
// compare numeric versionCode when present, and fall back to the name otherwise.
function parseVersion(raw) {
  const s = (raw || "").replace(/^v/, "");
  const [name, code] = s.split("+");
  return { version: name || s, versionCode: code ? Number(code) : null };
}

async function fetchHubTag(tag) {
  const res = await fetch(`https://api.github.com/repos/${hub}/releases/tags/${tag}`, { headers });
  if (!res.ok) return null;
  const data = await res.json();
  const asset = (data.assets || []).find((a) => a.name.endsWith(".apk")) || (data.assets || [])[0];
  const { version, versionCode } = parseVersion(data.name || data.tag_name);
  return {
    version,
    versionCode,
    notes: data.body || "",
    publishedAt: data.published_at || null,
    apkUrl: asset ? asset.browser_download_url : null,
    sizeBytes: asset ? asset.size : null,
  };
}

const apps = JSON.parse(await readFile(join(root, "apps.json"), "utf8"));
const out = { generatedAt: new Date().toISOString(), apps: {} };

for (const app of apps) {
  try {
    const rel = await fetchHubTag(app.id);
    if (rel && rel.apkUrl) out.apps[app.id] = rel;
    else console.warn(`no hub release for ${app.id} (tag ${app.id})`);
  } catch (e) {
    console.warn(`failed ${app.id}: ${e.message}`);
  }
}

await writeFile(join(root, "releases.json"), JSON.stringify(out, null, 2) + "\n");
console.log(`wrote releases.json for ${Object.keys(out.apps).length}/${apps.length} apps from ${hub}`);
