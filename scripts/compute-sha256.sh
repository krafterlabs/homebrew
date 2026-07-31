#!/usr/bin/env bash
# Compute sha256 for a private GitHub release asset.
# Usage: ./scripts/compute-sha256.sh <owner> <repo> <tag> <asset_name>
set -euo pipefail

[[ $# -eq 4 ]] || { echo "Usage: $0 <owner> <repo> <tag> <asset_name>" >&2; exit 1; }
OWNER="$1" REPO="$2" TAG="$3" ASSET="$4"
TOKEN="${HOMEBREW_GITHUB_API_TOKEN:-${GITHUB_TOKEN:-}}"
[[ -n "$TOKEN" ]] || { echo "ERROR: set HOMEBREW_GITHUB_API_TOKEN or GITHUB_TOKEN" >&2; exit 1; }

API="https://api.github.com/repos/${OWNER}/${REPO}/releases/tags/${TAG}"
ASSET_URL="$(curl -fsSL \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  "$API" | jq -r --arg name "$ASSET" '.assets[] | select(.name == $name) | .url')"

[[ -n "$ASSET_URL" && "$ASSET_URL" != "null" ]] || { echo "ERROR: asset '${ASSET}' not found on ${TAG}" >&2; exit 1; }

ARCHIVE="$(mktemp)"
trap 'rm -f "$ARCHIVE"' EXIT
curl -fsSL \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Accept: application/octet-stream" \
  -L -o "$ARCHIVE" "$ASSET_URL"
shasum -a 256 "$ARCHIVE" | awk '{print $1}'
