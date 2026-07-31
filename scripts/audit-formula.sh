#!/usr/bin/env bash
# =============================================================================
# audit-formula.sh — Validate formula desc lengths and run brew audit
# =============================================================================
#
# Usage:
#   ./scripts/audit-formula.sh
#
# Checks:
#   1. Every Formula/*.rb desc is strictly under 80 characters
#   2. brew audit --strict --new-formula (when brew is installed)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
FORMULA_DIR="${REPO_ROOT}/Formula"

log() { printf '[audit-formula] %s\n' "$*"; }
err() { printf '[audit-formula] ERROR: %s\n' "$*" >&2; }

validate_desc_lengths() {
  local formula desc len failed=0

  shopt -s nullglob
  local formulas=("${FORMULA_DIR}"/*.rb)

  if [[ ${#formulas[@]} -eq 0 ]]; then
    log "No formulas found in ${FORMULA_DIR}"
    return 0
  fi

  log "Validating desc lengths (< 80 chars) in ${#formulas[@]} formula(s)..."

  for formula in "${formulas[@]}"; do
    while IFS= read -r line; do
      desc="$(awk -F'"' '{ print $2 }' <<< "$line")"
      len="${#desc}"
      if [[ "$len" -ge 80 ]]; then
        err "${formula}: desc is ${len} characters (must be < 80): ${desc}"
        failed=1
      fi
    done < <(grep '^  desc "' "$formula" || true)
  done

  if [[ "$failed" -ne 0 ]]; then
    return 1
  fi

  log "desc length validation passed"
}

run_brew_audit() {
  if ! command -v brew >/dev/null 2>&1; then
    log "SKIP: brew not installed — skipping brew audit"
    return 0
  fi

  shopt -s nullglob
  local formulas=("${FORMULA_DIR}"/*.rb)

  if [[ ${#formulas[@]} -eq 0 ]]; then
    log "No formulas to audit"
    return 0
  fi

  log "Running brew audit --strict --new-formula..."
  brew audit --strict --new-formula "${formulas[@]}"
  log "brew audit passed"
}

main() {
  validate_desc_lengths
  run_brew_audit
}

main "$@"
