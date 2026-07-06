#!/usr/bin/env bash
# Mirrors each app's latest source-repo APK into the hub repo's Releases under a
# stable per-app tag (the app id). Idempotent: skips an app whose hub release
# already carries the same version, so steady-state runs move no bytes. Only the
# hub repo is written (via the ambient gh auth / GH_TOKEN); source repos are read
# unauthenticated. No secrets are read or written here.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
apps_json="$here/../apps.json"
HUB="${HUB_REPO:-jitendrajangidcodes-cloud/app-store-web}"

hub_version() {
  gh api "repos/$HUB/releases/tags/$1" 2>/dev/null | jq -r '.name // ""' || true
}

for id in $(jq -r '.[].id' "$apps_json"); do
  repo="$(jq -r --arg id "$id" '.[] | select(.id==$id) | .repo' "$apps_json")"

  # Apps published directly to the hub (repo == HUB) need no mirror step --
  # `releases/latest` on the hub itself would return whichever app released
  # most recently across ALL tags, not this app's release, so skip entirely
  # and let build-manifest.mjs read the app's own tag straight from the hub.
  if [ "$repo" = "$HUB" ]; then echo "ok $id: published directly to hub, no mirror needed"; continue; fi

  src="$(gh api "repos/$repo/releases/latest" 2>/dev/null || true)"
  if [ -z "$src" ]; then echo "skip $id: no source release ($repo)"; continue; fi

  srcver="$(echo "$src" | jq -r '.tag_name // ""' | sed 's/^v//')"
  asseturl="$(echo "$src" | jq -r 'first(.assets[]? | select(.name|endswith(".apk")) | .browser_download_url) // (.assets[0].browser_download_url // "")')"
  assetname="$(echo "$src" | jq -r 'first(.assets[]? | select(.name|endswith(".apk")) | .name) // (.assets[0].name // "")')"
  if [ -z "$asseturl" ] || [ -z "$assetname" ]; then echo "skip $id: no apk asset"; continue; fi

  if [ "$(hub_version "$id")" = "$srcver" ]; then echo "ok $id: hub up to date ($srcver)"; continue; fi

  echo "mirror $id: -> $srcver"
  tmp="$(mktemp -d)"
  notes="$tmp/notes.md"
  echo "$src" | jq -r '.body // ""' > "$notes"
  curl -fsSL "$asseturl" -o "$tmp/$assetname"

  if gh api "repos/$HUB/releases/tags/$id" >/dev/null 2>&1; then
    for old in $(gh release view "$id" --repo "$HUB" --json assets -q '.assets[].name' 2>/dev/null || true); do
      gh release delete-asset "$id" "$old" --repo "$HUB" -y || true
    done
    gh release edit "$id" --repo "$HUB" --title "$srcver" --notes-file "$notes"
    gh release upload "$id" "$tmp/$assetname" --repo "$HUB" --clobber
  else
    gh release create "$id" "$tmp/$assetname" --repo "$HUB" --title "$srcver" --notes-file "$notes"
  fi
  rm -rf "$tmp"
done
