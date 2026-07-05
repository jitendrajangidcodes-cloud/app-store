const THEME_KEY = "theme";
const THEME_EXPLICIT_KEY = "theme-explicit";

// This hub repo -- apps published directly here (apps.json `repo` field
// equals this) need tag-specific release lookups, never "latest". See
// getRelease() below.
const HUB_REPO = "jitendrajangidcodes-cloud/app-store";

function currentTheme() {
  return document.documentElement.getAttribute("data-theme") || "dark";
}

function applyTheme(theme) {
  document.documentElement.setAttribute("data-theme", theme);
}

function toggleTheme() {
  const next = currentTheme() === "dark" ? "light" : "dark";
  localStorage.setItem(THEME_KEY, next);
  localStorage.setItem(THEME_EXPLICIT_KEY, "1");
  applyTheme(next);
}

window.matchMedia("(prefers-color-scheme: light)").addEventListener("change", (e) => {
  if (localStorage.getItem(THEME_EXPLICIT_KEY) === "1") return;
  applyTheme(e.matches ? "light" : "dark");
});

document.addEventListener("DOMContentLoaded", () => {
  const btn = document.querySelector(".theme-toggle");
  if (btn) btn.addEventListener("click", toggleTheme);
});

async function fetchLatestRelease(repo) {
  try {
    const res = await fetch(`https://api.github.com/repos/${repo}/releases/latest`, {
      headers: { Accept: "application/vnd.github+json" },
    });
    if (!res.ok) return null;
    const data = await res.json();
    const asset = (data.assets || [])[0];
    return {
      version: (data.tag_name || "").replace(/^v/, ""),
      notes: data.body || "",
      publishedAt: data.published_at || null,
      downloadUrl: asset ? asset.browser_download_url : null,
      sizeBytes: asset ? asset.size : null,
    };
  } catch (e) {
    return null;
  }
}

// One release by exact tag. The hub keeps a stable tag per app/store, with the
// human version in the release name, so latest-by-tag is deterministic even
// though the hub holds several apps' releases.
async function fetchReleaseByTag(repo, tag) {
  try {
    const res = await fetch(`https://api.github.com/repos/${repo}/releases/tags/${tag}`, {
      headers: { Accept: "application/vnd.github+json" },
    });
    if (!res.ok) return null;
    const data = await res.json();
    const asset = (data.assets || []).find((a) => a.name.endsWith(".apk")) || (data.assets || [])[0];
    return {
      version: (data.name || data.tag_name || "").replace(/^v/, ""),
      notes: data.body || "",
      publishedAt: data.published_at || null,
      downloadUrl: asset ? asset.browser_download_url : null,
      sizeBytes: asset ? asset.size : null,
    };
  } catch (e) {
    return null;
  }
}

// Short release history for the detail page's "Release notes" card -- shows
// the latest expanded plus a couple of previous versions collapsed, all real
// data (no fabricated version history).
async function fetchReleaseHistory(repo, count = 3) {
  try {
    const res = await fetch(`https://api.github.com/repos/${repo}/releases?per_page=${count}`, {
      headers: { Accept: "application/vnd.github+json" },
    });
    if (!res.ok) return [];
    const data = await res.json();
    return data.map((rel) => {
      const asset = (rel.assets || [])[0];
      return {
        version: (rel.tag_name || "").replace(/^v/, ""),
        notes: rel.body || "",
        publishedAt: rel.published_at || null,
        downloadUrl: asset ? asset.browser_download_url : null,
        sizeBytes: asset ? asset.size : null,
      };
    });
  } catch (e) {
    return [];
  }
}

function formatSize(bytes) {
  if (!bytes) return "--";
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

function formatDate(iso) {
  if (!iso) return "--";
  return new Date(iso).toLocaleDateString(undefined, { year: "numeric", month: "short", day: "numeric" });
}

async function loadApps() {
  const res = await fetch("apps.json");
  return res.json();
}

// releases.json is generated in CI from every app's Releases, so the listing
// needs ONE fetch instead of one GitHub API call per app. Cached per page load.
let _manifestPromise = null;
function loadManifest() {
  if (!_manifestPromise) {
    _manifestPromise = fetch("releases.json")
      .then((r) => (r.ok ? r.json() : null))
      .catch(() => null);
  }
  return _manifestPromise;
}

// Prefer the manifest; fall back to the live API per app if it is missing or
// stale. Returns the same shape as fetchLatestRelease (downloadUrl, not apkUrl).
//
// Apps published directly to this hub (apps.json `repo` === HUB_REPO, e.g.
// ai-scanner) MUST fall back to a tag-specific lookup, never
// fetchLatestRelease -- the hub holds multiple apps' releases under
// different tags, so "latest" resolves to whichever app released most
// recently, not this one. This mirrors the same fix already applied to
// scripts/sync-releases.sh; missing it here left the site briefly showing
// another app's version (or none) for any hub-direct app whenever
// releases.json was momentarily stale/uncached.
async function getRelease(app) {
  const manifest = await loadManifest();
  const m = manifest && manifest.apps ? manifest.apps[app.id] : null;
  if (m && m.apkUrl) {
    return {
      version: m.version,
      notes: m.notes || "",
      publishedAt: m.publishedAt || null,
      downloadUrl: m.apkUrl,
      sizeBytes: m.sizeBytes || null,
    };
  }
  if (app.repo === HUB_REPO) {
    return fetchReleaseByTag(app.repo, app.id);
  }
  return fetchLatestRelease(app.repo);
}

// ── Buddy tile brand component ──────────────────────────────────────────
// One colored rounded tile per PNSJY letter, or a single-letter app icon
// tile. `size` in px; `fontSize`/`eyeSize`/`eyeGap`/`eyeTop` scale with it
// by default but can be overridden for particularly small/large usages.

const PNSJY_LETTERS = [
  { ch: "P", bg: "#e8632c", fg: "#ffffff" },
  { ch: "N", bg: "#f0a92c", fg: "#6b4400" },
  { ch: "S", bg: "#3fae6a", fg: "#ffffff" },
  { ch: "J", bg: "#2f7ee3", fg: "#ffffff" },
  { ch: "Y", bg: "#8a56d6", fg: "#ffffff" },
];

function buddyTileHTML(ch, bg, fg, size) {
  const radius = Math.round(size * 0.28);
  const font = Math.round(size * 0.55);
  const eye = Math.max(3, Math.round(size * 0.13));
  const gap = Math.round(size * 0.19);
  const top = Math.round(size * 0.19);
  const pad = Math.round(size * 0.1);
  return `
    <div class="buddy-tile" style="width:${size}px;height:${size}px;border-radius:${radius}px;background:${bg};">
      <div class="eyes" style="top:${top}px;gap:${gap}px;">
        <span style="width:${eye}px;height:${eye}px;background:${fg};"></span>
        <span style="width:${eye}px;height:${eye}px;background:${fg};"></span>
      </div>
      <span class="letter" style="font-size:${font}px;color:${fg};padding-bottom:${pad}px;">${ch}</span>
    </div>
  `;
}

function pnsjyLogoHTML(size) {
  return `<div class="buddy-row">${PNSJY_LETTERS.map((b) => buddyTileHTML(b.ch, b.bg, b.fg, size)).join("")}</div>`;
}

function appTileHTML(app, size) {
  return buddyTileHTML(app.name.charAt(0).toUpperCase(), app.color || "#2f7ee3", "#ffffff", size);
}

// Real app icon (apps.json `icon`) with a colored first-letter tile behind it,
// so a missing/failed image degrades to the branded letter instead of a gap.
function appIconHTML(app, size) {
  if (!app.icon) return appTileHTML(app, size);
  const radius = Math.round(size * 0.24);
  const font = Math.round(size * 0.5);
  const bg = app.color || "#2f7ee3";
  const letter = app.name.charAt(0).toUpperCase();
  return `
    <div class="app-icon" style="width:${size}px;height:${size}px;border-radius:${radius}px;background:${bg};">
      <span class="fallback" style="font-size:${font}px;">${letter}</span>
      <img src="${app.icon}" alt="${app.name} icon" loading="lazy" style="border-radius:${radius}px;" onerror="this.remove()">
    </div>`;
}

// ── Feedback (prefilled GitHub issues) ───────────────────────────────────

// Feedback opens a prefilled GitHub issue on the app-store repo -- no backend,
// no account data, GitHub handles identity and spam. Mirrors the store app's
// FeedbackLinks so both surfaces file into the same inbox with the same labels.
const FEEDBACK_REPO = "jitendrajangidcodes-cloud/app-store";

// Every APK lives in this hub repo. The store app's own build sits under the
// stable "store" tag; the "Get the Store app" banner pulls its live version/
// size/download straight from that release.
const STORE_REPO = "jitendrajangidcodes-cloud/app-store";
const STORE_TAG = "store";

function feedbackUrl(type, app) {
  const titles = { feedback: "Feedback", suggestion: "Suggestion", bug: "Bug report" };
  const scope = app ? ` for ${app.name}` : "";
  const target = app ? `**App:** ${app.name}\n\n` : "";
  const bodies = {
    bug: `${target}**What happened:**\n\n**Steps to reproduce:**\n\n**Device / Android version:**\n`,
    suggestion: `${target}**What would you like to see:**\n`,
    feedback: `${target}**Your feedback:**\n`,
  };
  const params = new URLSearchParams({
    title: `${titles[type]}${scope}: `,
    labels: [type, app ? app.id : null].filter(Boolean).join(","),
    body: bodies[type],
  });
  return `https://github.com/${FEEDBACK_REPO}/issues/new?${params.toString()}`;
}

function feedbackRowHTML(app) {
  const mk = (type, label) =>
    `<a class="feedback-link" target="_blank" rel="noopener" href="${feedbackUrl(type, app)}">${label}</a>`;
  return `${mk("suggestion", "Suggest a feature")}${mk("bug", "Report a bug")}${mk("feedback", "Send feedback")}`;
}

// ── Card tilt-on-hover ───────────────────────────────────────────────────

function attachTilt(el) {
  el.addEventListener("mousemove", (e) => {
    const r = el.getBoundingClientRect();
    const x = (e.clientX - r.left) / r.width - 0.5;
    const y = (e.clientY - r.top) / r.height - 0.5;
    el.style.transform = `perspective(800px) rotateY(${x * 10}deg) rotateX(${-y * 10}deg) translateY(-4px)`;
  });
  el.addEventListener("mouseleave", () => {
    el.style.transform = "";
  });
}
