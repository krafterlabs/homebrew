#!/usr/bin/env bash
# =============================================================================
# update-formula.sh — Update version and checksums in a Homebrew formula
# =============================================================================
#
# Usage:
#   ./scripts/update-formula.sh <PROJECT_NAME> <NEW_VERSION> [OPTIONS]
#
# Required:
#   PROJECT_NAME   Formula name (e.g. project-x) — maps to Formula/<name>.rb
#   NEW_VERSION    Release version (with or without leading "v")
#
# Checksum options (provide at least one):
#   --sha256 <hash>              Single-platform: sets one url/sha256 pair
#   --sha256-darwin-arm64 <hash>
#   --sha256-darwin-amd64 <hash>
#   --sha256-linux-arm64 <hash>
#   --sha256-linux-amd64 <hash>
#
# Optional:
#   --github-org <org>           Override org (default: from config/projects.yaml)
#   --github-repo <repo>         Override repo name (default: PROJECT_NAME)
#   --binary <name>              Binary name inside tarball
#   --no-commit                  Update file but do not git commit
#   --dry-run                    Print changes without writing
#
# Examples:
#   ./scripts/update-formula.sh project-x 1.2.3 \
#     --sha256-darwin-arm64 abc... \
#     --sha256-darwin-amd64 def...
#
#   ./scripts/update-formula.sh project-x 1.2.3 --sha256 abc123...
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
FORMULA_DIR="${REPO_ROOT}/Formula"
CONFIG_FILE="${REPO_ROOT}/config/projects.yaml"

PROJECT_NAME=""
NEW_VERSION=""
GITHUB_ORG=""
GITHUB_REPO=""
BINARY_NAME=""
DRY_RUN=false
NO_COMMIT=false

declare -A SHA256_MAP

usage() {
  sed -n '3,35p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

log() { printf '[update-formula] %s\n' "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }

# Strip leading "v" from version tags.
normalize_version() {
  echo "${1#v}"
}

# Convert project-x to ProjectX for Ruby class names.
to_ruby_class() {
  local name="$1"
  local result=""
  local part
  IFS='-' read -ra parts <<< "$name"
  for part in "${parts[@]}"; do
    result+="$(tr '[:lower:]' '[:upper:]' <<< "${part:0:1}")${part:1}"
  done
  echo "$result"
}

asset_name() {
  local os="$1"
  local arch="$2"
  local ver
  ver="$(normalize_version "$NEW_VERSION")"
  echo "${PROJECT_NAME}-${ver}-${os}-${arch}.tar.gz"
}

release_url() {
  local asset="$1"
  local ver
  ver="$(normalize_version "$NEW_VERSION")"
  echo "https://github.com/${GITHUB_ORG}/${GITHUB_REPO}/releases/download/v${ver}/${asset}"
}

lookup_config() {
  local key="$1"
  local field="$2"
  if [[ ! -f "$CONFIG_FILE" ]]; then
    return 1
  fi
  # Minimal YAML lookup — sufficient for our flat projects list.
  awk -v name="$key" -v field="$field" '
    $0 ~ "^  - name: " name "$" { found=1; next }
    found && $0 ~ "^  - name:" { found=0 }
    found && $0 ~ "^    " field ": " {
      sub("^    " field ": ", "")
      gsub(/^"|"$/, "")
      print
      exit
    }
  ' "$CONFIG_FILE"
}

parse_args() {
  if [[ $# -lt 2 ]]; then
    usage 1
  fi

  PROJECT_NAME="$1"
  NEW_VERSION="$(normalize_version "$2")"
  shift 2

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --sha256)
        SHA256_MAP[single]="$2"; shift 2 ;;
      --sha256-darwin-arm64)
        SHA256_MAP[darwin-arm64]="$2"; shift 2 ;;
      --sha256-darwin-amd64)
        SHA256_MAP[darwin-amd64]="$2"; shift 2 ;;
      --sha256-linux-arm64)
        SHA256_MAP[linux-arm64]="$2"; shift 2 ;;
      --sha256-linux-amd64)
        SHA256_MAP[linux-amd64]="$2"; shift 2 ;;
      --github-org)
        GITHUB_ORG="$2"; shift 2 ;;
      --github-repo)
        GITHUB_REPO="$2"; shift 2 ;;
      --binary)
        BINARY_NAME="$2"; shift 2 ;;
      --dry-run)
        DRY_RUN=true; shift ;;
      --no-commit)
        NO_COMMIT=true; shift ;;
      -h|--help)
        usage 0 ;;
      *)
        die "Unknown argument: $1" ;;
    esac
  done

  GITHUB_ORG="${GITHUB_ORG:-$(lookup_config "$PROJECT_NAME" github_org || true)}"
  GITHUB_ORG="${GITHUB_ORG:-my-org}"
  GITHUB_REPO="${GITHUB_REPO:-$(lookup_config "$PROJECT_NAME" repo || true)}"
  GITHUB_REPO="${GITHUB_REPO:-$PROJECT_NAME}"
  BINARY_NAME="${BINARY_NAME:-$(lookup_config "$PROJECT_NAME" binary || true)}"
  BINARY_NAME="${BINARY_NAME:-$PROJECT_NAME}"

  if [[ ${#SHA256_MAP[@]} -eq 0 ]]; then
    die "At least one --sha256* argument is required"
  fi
}

update_existing_formula() {
  local formula_file="$1"
  local tmp
  tmp="$(mktemp)"

  cp "$formula_file" "$tmp"

  # Update top-level version line.
  sed -i "s/^  version \".*\"/  version \"${NEW_VERSION}\"/" "$tmp"

  if [[ -n "${SHA256_MAP[single]:-}" ]]; then
    sed -i "s|^  url \".*\"|  url \"$(release_url "$(asset_name darwin arm64)")\"|" "$tmp"
    sed -i "s/^  sha256 \".*\"/  sha256 \"${SHA256_MAP[single]}\"/" "$tmp"
  else
  local platform sha key asset url
  for key in darwin-arm64 darwin-amd64 linux-arm64 linux-amd64; do
    sha="${SHA256_MAP[$key]:-}"
    [[ -z "$sha" ]] && continue
    platform="${key%-*}"
    arch="${key#*-}"
    asset="$(asset_name "$platform" "$arch")"
    url="$(release_url "$asset")"

    # Update url line inside the matching on_* block (best-effort sed).
    sed -i "/on_${platform} do/,/end/{
      /on_${arch} do/,/end/{
        s|^      url \".*\"|      url \"${url}\"|
        s|^      sha256 \".*\"|      sha256 \"${sha}\"|
      }
    }" "$tmp"
  done
  fi

  if $DRY_RUN; then
    diff -u "$formula_file" "$tmp" || true
    rm -f "$tmp"
    return
  fi

  mv "$tmp" "$formula_file"
  log "Updated ${formula_file}"
}

generate_formula() {
  local formula_file="${FORMULA_DIR}/${PROJECT_NAME}.rb"
  local ruby_class
  ruby_class="$(to_ruby_class "$PROJECT_NAME")"
  local desc homepage
  desc="$(lookup_config "$PROJECT_NAME" description || echo "Private CLI tool")"
  homepage="$(lookup_config "$PROJECT_NAME" homepage || echo "https://github.com/${GITHUB_ORG}/${GITHUB_REPO}")"

  if $DRY_RUN; then
    log "Would create ${formula_file}"
    return
  fi

  cat > "$formula_file" <<RUBY
# frozen_string_literal: true

class ${ruby_class} < Formula
  desc "${desc}"
  homepage "${homepage}"
  version "${NEW_VERSION}"

  on_macos do
    on_arm do
      url "$(release_url "$(asset_name darwin arm64)")"
      sha256 "${SHA256_MAP[darwin-arm64]:-0000000000000000000000000000000000000000000000000000000000000000}"
    end
    on_intel do
      url "$(release_url "$(asset_name darwin amd64)")"
      sha256 "${SHA256_MAP[darwin-amd64]:-0000000000000000000000000000000000000000000000000000000000000000}"
    end
  end

  on_linux do
    on_arm do
      url "$(release_url "$(asset_name linux arm64)")"
      sha256 "${SHA256_MAP[linux-arm64]:-0000000000000000000000000000000000000000000000000000000000000000}"
    end
    on_intel do
      url "$(release_url "$(asset_name linux amd64)")"
      sha256 "${SHA256_MAP[linux-amd64]:-0000000000000000000000000000000000000000000000000000000000000000}"
    end
  end

  def install
    bin.install "${BINARY_NAME}"
  end

  test do
    system "#{bin}/${BINARY_NAME}", "--help"
  end
end
RUBY

  log "Created ${formula_file}"
}

commit_changes() {
  local formula_file="${FORMULA_DIR}/${PROJECT_NAME}.rb"
  if $NO_COMMIT || $DRY_RUN; then
    return
  fi

  if ! git -C "$REPO_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    log "Not a git repo — skipping commit"
    return
  fi

  git -C "$REPO_ROOT" add "$formula_file"
  if git -C "$REPO_ROOT" diff --cached --quiet; then
    log "No changes to commit"
    return
  fi

  git -C "$REPO_ROOT" commit -m "chore(formula): bump ${PROJECT_NAME} to v${NEW_VERSION}"
  log "Committed formula update"
}

main() {
  parse_args "$@"

  local formula_file="${FORMULA_DIR}/${PROJECT_NAME}.rb"
  mkdir -p "$FORMULA_DIR"

  if [[ -f "$formula_file" ]]; then
    update_existing_formula "$formula_file"
  else
    generate_formula
  fi

  commit_changes
}

main "$@"
