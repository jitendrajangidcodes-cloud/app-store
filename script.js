const THEME_KEY = "theme";
const THEME_EXPLICIT_KEY = "theme-explicit";

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
