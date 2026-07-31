---
title: Homebrew tap release update flow
type: feat
product_contract_source: legacy-requirements
---

# Plan: Document how releases update this tap

## Goal Capsule

Answer clearly for maintainers and end-users: **when `krafterlabs/0x-excali` ships a new GitHub Release, what must change in `krafterlabs/homebrew`?**

## Product Contract

### Problem

README says "bump versions by editing…" but never states the release lifecycle. Users who run `brew upgrade` after an upstream release get a SHA mismatch or stay on the old version with no explanation of *why*.

### Decision (session-settled: user-directed)

**Yes — a new upstream release requires a change in this tap repo.** Homebrew does not auto-discover new GitHub Releases for casks/formulas in a custom tap. Version + `sha256` are pinned in Ruby files here.

### Out of scope

- Building CI that auto-bumps on every 0x-excali release (nice-to-have later; not required for this doc update)
- Renaming the GitHub repo to `homebrew-tap`
- Changing formula/cask install names

### Acceptance

1. README has a short **"How releases work"** section that a non-Homebrew expert can follow.
2. The section states explicitly that the tap must be updated after each upstream release.
3. Maintainer steps list the exact files, checksum command, and user upgrade commands.
4. End-user path is: wait for tap update → `brew update` → `brew upgrade …`.

## How it works today

```
0x-excali cuts GitHub Release vX.Y.Z
        │  (uploads DMG + linux tar.gz)
        ▼
Someone updates THIS tap:
  Casks/0x-excali.rb     → version + sha256 (macOS)
  Formula/ox-excali.rb   → version + sha256 (Linux amd64)
        │
        ▼
Commit + push to krafterlabs/homebrew (main)
        │
        ▼
End users:
  brew update
  brew upgrade --cask 0x-excali   # macOS
  brew upgrade ox-excali          # Linux
```

Nothing in Homebrew watches the 0x-excali repo. Until this tap's Ruby files change, `brew upgrade` keeps the old pinned version.

## Implementation Units

### U1 — README: How releases work

**Files:** `README.md` only (do not change Optional rename / tap URL / token sections except as needed for consolidation)

**Approach:**

- Add **"How releases work"** between Available packages and Troubleshooting.
- Fold the old Maintainers section into it (one checklist, no duplicate).
- Explicit Yes: new upstream release → edit this repo.
- End-user path: wait for tap update → `brew update` → `brew upgrade …`; point SHA256 mismatch at this section.
- Maintainer steps: inline asset names; `./scripts/compute-sha256.sh` (needs token) **or** curl+shasum (public); note `Formula` sha256 is inside `on_intel`; prerequisites curl/jq/shasum.
- Note Linux arm64 unsupported.

### U2 — skipped

Keep everything in README (ponytail). No `MAINTAINING.md`.

## Verification

- [x] Explicit Yes: tap must change on upstream release.
- [x] Maintainer steps: files + checksum command(s) + upgrade commands.
- [x] End-user wait → update → upgrade path documented.
- [x] No claim that upgrades are automatic.
- [x] ce-doc-review findings applied (consolidate Maintainers, token friction, nested sha256, asset names, arm64 note).

## Definition of Done

README documents the release → tap → upgrade loop; review findings addressed; PR opened.
