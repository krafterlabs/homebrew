#!/usr/bin/env bash
# =============================================================================
# fetch-release-metadata.sh — Fetch GitHub release assets, URLs, and sha256 sums
# =============================================================================
#
# Requires HOMEBREW_GITHUB_API_TOKEN or GITHUB_TOKEN with repo read access.
#
# Usage:
#   ./scripts/fetch-release-metadata.sh <owner> <repo> <tag> [asset_pattern]
#
# Arguments:
#   owner         GitHub org or user
#   repo          Repository name
#   tag           Release tag (e.g. v1.2.3)
#   asset_pattern Optional Go-style template for asset filenames. Variables:
#                 {{ .Version }} — version without leading "v"
#                 {{ .OS }}      — "darwin" or "linux"
#                 {{ .Arch }}    — "arm64" or "amd64"
#                 Default: "<repo>-{{ .Version }}-{{ .OS }}-{{ .Arch }}.tar.gz"
#
# Output (stdout — suitable for piping into update-formula.sh):
#   Line 1: normalized version (no leading "v")
#   Lines 2+: one flag/hash pair per platform, e.g.
#     --sha256-darwin-arm64 <64-char-hex>
#     --sha256-darwin-amd64 <64-char-hex>
#     --sha256-linux-arm64 <64-char-hex>
#     --sha256-linux-amd64 <64-char-hex>
#
# Progress, asset URLs, and errors go to stderr.
#
# Example — pipe checksum flags into update-formula.sh:
#   mapfile -t META < <(./scripts/fetch-release-metadata.sh my-org project-x v1.2.3)
#   ./scripts/update-formula.sh project-x "${META[0]}" "${META[@]:1}"
#
# Example — custom asset naming (matches config/projects.yaml asset_pattern):
#   ./scripts/fetch-release-metadata.sh my-org project-x v1.2.3 \
#     'project-x-{{ .Version }}-{{ .OS }}-{{ .Arch }}.tar.gz'
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPUTE_SHA256="${SCRIPT_DIR}/compute-sha256.sh"

if [[ $# -lt 3 || $# -gt 4 ]]; then
  echo "Usage: $0 <owner> <repo> <tag> [asset_pattern]" >&2
  exit 1
fi

OWNER="$1"
REPO="$2"
TAG="$3"
ASSET_PATTERN="${4:-${REPO}-{{ .Version }}-{{ .OS }}-{{ .Arch }}.tar.gz}"
TOKEN="${HOMEBREW_GITHUB_API_TOKEN:-${GITHUB_TOKEN:-}}"

if [[ -z "$TOKEN" ]]; then
  echo "ERROR: Set HOMEBREW_GITHUB_API_TOKEN or GITHUB_TOKEN" >&2
  exit 1
fi

if [[ ! -x "$COMPUTE_SHA256" ]]; then
  echo "ERROR: compute-sha256.sh not found or not executable: ${COMPUTE_SHA256}" >&2
  exit 1
fi

log() { printf '[fetch-release-metadata] %s\n' "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }

normalize_version() {
  echo "${1#v}"
}

# Expand {{ .Version }}, {{ .OS }}, {{ .Arch }} in asset_pattern.
render_asset_name() {
  local version="$1"
  local os="$2"
  local arch="$3"
  local pattern="$4"
  local result="$pattern"

  result="${result//\{\{ \.Version \}\}/$version}"
  result="${result//\{\{ .Version \}\}/$version}"
  result="${result//\{\{ \.OS \}\}/$os}"
  result="${result//\{\{ .OS \}\}/$os}"
  result="${result//\{\{ \.Arch \}\}/$arch}"
  result="${result//\{\{ .Arch \}\}/$arch}"
  echo "$result"
}

release_download_url() {
  local version="$1"
  local asset_name="$2"
  echo "https://github.com/${OWNER}/${REPO}/releases/download/v${version}/${asset_name}"
}

VERSION="$(normalize_version "$TAG")"
API_URL="https://api.github.com/repos/${OWNER}/${REPO}/releases/tags/${TAG}"

log "Fetching release ${OWNER}/${REPO}@${TAG}..."

RELEASE_JSON="$(curl -fsSL \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  "$API_URL")"

if [[ -z "$RELEASE_JSON" || "$RELEASE_JSON" == "null" ]]; then
  die "Release not found for tag ${TAG}"
fi

API_TAG="$(echo "$RELEASE_JSON" | jq -r '.tag_name // empty')"
if [[ -z "$API_TAG" ]]; then
  die "Invalid release response for tag ${TAG}"
fi

VERSION="$(normalize_version "$API_TAG")"
log "Version: ${VERSION}"

PLATFORMS=(
  "darwin:arm64:darwin-arm64"
  "darwin:amd64:darwin-amd64"
  "linux:arm64:linux-arm64"
  "linux:amd64:linux-amd64"
)

declare -a OUTPUT_LINES=()
found=0

for entry in "${PLATFORMS[@]}"; do
  IFS=':' read -r os arch platform_key <<< "$entry"
  asset_name="$(render_asset_name "$VERSION" "$os" "$arch" "$ASSET_PATTERN")"

  asset_exists="$(echo "$RELEASE_JSON" | jq -r --arg name "$asset_name" \
    '.assets[] | select(.name == $name) | .name' | head -n 1)"

  if [[ -z "$asset_exists" ]]; then
    log "Skipping ${platform_key}: asset not found (${asset_name})"
    continue
  fi

  url="$(release_download_url "$VERSION" "$asset_name")"
  log "Computing sha256 for ${platform_key}: ${asset_name}"
  log "  URL: ${url}"

  sha256="$("$COMPUTE_SHA256" "$OWNER" "$REPO" "$API_TAG" "$asset_name")"
  OUTPUT_LINES+=("--sha256-${platform_key}" "$sha256")
  found=$((found + 1))
done

if [[ "$found" -eq 0 ]]; then
  die "No release assets matched pattern: ${ASSET_PATTERN}"
fi

printf '%s\n' "$VERSION"
for ((i = 0; i < ${#OUTPUT_LINES[@]}; i += 2)); do
  printf '%s %s\n' "${OUTPUT_LINES[$i]}" "${OUTPUT_LINES[$i + 1]}"
done
