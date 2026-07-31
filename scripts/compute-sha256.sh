#!/usr/bin/env bash
# =============================================================================
# compute-sha256.sh — Download a private GitHub release asset and print sha256
# =============================================================================
#
# Requires HOMEBREW_GITHUB_API_TOKEN or GITHUB_TOKEN with repo read access.
#
# Usage:
#   ./scripts/compute-sha256.sh <owner> <repo> <tag> <asset_name>
#
# Example:
#   ./scripts/compute-sha256.sh my-org project-x v1.2.3 \
#     project-x-1.2.3-darwin-arm64.tar.gz
# =============================================================================

set -euo pipefail

if [[ $# -ne 4 ]]; then
  echo "Usage: $0 <owner> <repo> <tag> <asset_name>" >&2
  exit 1
fi

OWNER="$1"
REPO="$2"
TAG="$3"
ASSET="$4"
TOKEN="${HOMEBREW_GITHUB_API_TOKEN:-${GITHUB_TOKEN:-}}"

if [[ -z "$TOKEN" ]]; then
  echo "ERROR: Set HOMEBREW_GITHUB_API_TOKEN or GITHUB_TOKEN" >&2
  exit 1
fi

TMPDIR="${TMPDIR:-/tmp}"
ARCHIVE="${TMPDIR}/${ASSET}"

# GitHub API: resolve release asset download URL (follows redirect with auth).
API_URL="https://api.github.com/repos/${OWNER}/${REPO}/releases/tags/${TAG}"
ASSET_URL="$(curl -fsSL \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  "$API_URL" \
  | jq -r --arg name "$ASSET" '.assets[] | select(.name == $name) | .url')"

if [[ -z "$ASSET_URL" || "$ASSET_URL" == "null" ]]; then
  echo "ERROR: Asset '${ASSET}' not found on release ${TAG}" >&2
  exit 1
fi

curl -fsSL \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Accept: application/octet-stream" \
  -L -o "$ARCHIVE" \
  "$ASSET_URL"

shasum -a 256 "$ARCHIVE" | awk '{print $1}'
rm -f "$ARCHIVE"
