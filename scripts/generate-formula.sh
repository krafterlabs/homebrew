#!/usr/bin/env bash
# =============================================================================
# generate-formula.sh — Bootstrap a new formula from the template
# =============================================================================
#
# Usage:
#   ./scripts/generate-formula.sh <project-name> [version]
#
# Creates Formula/<project-name>.rb from templates/formula.rb.template
# using values from config/projects.yaml when available.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <project-name> [version]" >&2
  exit 1
fi

PROJECT_NAME="$1"
VERSION="${2:-0.0.0}"
TEMPLATE="${REPO_ROOT}/templates/formula.rb.template"
OUTPUT="${REPO_ROOT}/Formula/${PROJECT_NAME}.rb"
CONFIG="${REPO_ROOT}/config/projects.yaml"

lookup() {
  awk -v name="$PROJECT_NAME" -v field="$1" '
    $0 ~ "^  - name: " name "$" { found=1; next }
    found && $0 ~ "^  - name:" { found=0 }
    found && $0 ~ "^    " field ": " {
      sub("^    " field ": ", "")
      gsub(/^"|"$/, "")
      print
      exit
    }
  ' "$CONFIG" 2>/dev/null || true
}

to_ruby_class() {
  local name="$1" result="" part
  IFS='-' read -ra parts <<< "$name"
  for part in "${parts[@]}"; do
    result+="$(tr '[:lower:]' '[:upper:]' <<< "${part:0:1}")${part:1}"
  done
  echo "$result"
}

GITHUB_ORG="$(lookup github_org)"
GITHUB_ORG="${GITHUB_ORG:-my-org}"
GITHUB_REPO="$(lookup repo)"
GITHUB_REPO="${GITHUB_REPO:-$PROJECT_NAME}"
DESCRIPTION="$(lookup description)"
DESCRIPTION="${DESCRIPTION:-Private CLI tool}"
if [[ ${#DESCRIPTION} -gt 79 ]]; then
  echo "ERROR: desc is ${#DESCRIPTION} characters (max 79): ${DESCRIPTION}" >&2
  exit 1
fi
HOMEPAGE="$(lookup homepage)"
HOMEPAGE="${HOMEPAGE:-https://github.com/${GITHUB_ORG}/${GITHUB_REPO}}"
BINARY="$(lookup binary)"
BINARY="${BINARY:-$PROJECT_NAME}"
RUBY_CLASS="$(to_ruby_class "$PROJECT_NAME")"

if [[ ! -f "$TEMPLATE" ]]; then
  echo "ERROR: Template not found: $TEMPLATE" >&2
  exit 1
fi

if [[ -f "$OUTPUT" ]]; then
  echo "ERROR: Formula already exists: $OUTPUT" >&2
  exit 1
fi

sed \
  -e "s/__ProjectNameCamelCase__/${RUBY_CLASS}/g" \
  -e "s/__DESCRIPTION__/${DESCRIPTION}/g" \
  -e "s/__HOMEPAGE__/${HOMEPAGE}/g" \
  -e "s/__VERSION__/${VERSION}/g" \
  -e "s/__GITHUB_ORG__/${GITHUB_ORG}/g" \
  -e "s/__GITHUB_REPO__/${GITHUB_REPO}/g" \
  -e "s/__BINARY_NAME__/${BINARY}/g" \
  -e "s/__ASSET_NAME_DARWIN_ARM64__/${PROJECT_NAME}-${VERSION}-darwin-arm64.tar.gz/g" \
  -e "s/__ASSET_NAME_DARWIN_AMD64__/${PROJECT_NAME}-${VERSION}-darwin-amd64.tar.gz/g" \
  -e "s/__ASSET_NAME_LINUX_ARM64__/${PROJECT_NAME}-${VERSION}-linux-arm64.tar.gz/g" \
  -e "s/__ASSET_NAME_LINUX_AMD64__/${PROJECT_NAME}-${VERSION}-linux-amd64.tar.gz/g" \
  -e "s/__SHA256_DARWIN_ARM64__/PLACEHOLDER_SHA256/g" \
  -e "s/__SHA256_DARWIN_AMD64__/PLACEHOLDER_SHA256/g" \
  -e "s/__SHA256_LINUX_ARM64__/PLACEHOLDER_SHA256/g" \
  -e "s/__SHA256_LINUX_AMD64__/PLACEHOLDER_SHA256/g" \
  -e "s/__ASSET_NAME__/${PROJECT_NAME}-${VERSION}.tar.gz/g" \
  -e "s/__SHA256__/PLACEHOLDER_SHA256/g" \
  "$TEMPLATE" > "$OUTPUT"

echo "Created ${OUTPUT}"
echo "Next: run update-formula.sh after publishing release assets with real checksums."
echo "Reminder: run ./scripts/audit-formula.sh to validate formulas."
