# krafterlabs/homebrew

Homebrew tap for krafterlabs tools.

> Homebrew turns `brew tap krafterlabs/NAME` into a clone of
> `github.com/krafterlabs/homebrew-NAME`. This repo is named `homebrew`, so pass
> the clone URL explicitly (or rename the repo to `homebrew-tap` and use
> `brew tap krafterlabs/tap`).

```bash
brew tap krafterlabs/homebrew https://github.com/krafterlabs/homebrew
brew install --cask 0x-excali   # macOS
brew install ox-excali          # Linux amd64
```

This repo is **public** — no token is required to tap or install.

## Available packages

| Install | Platform | Notes |
|---------|----------|-------|
| `brew install --cask 0x-excali` | macOS | Universal DMG |
| `brew install ox-excali` | Linux amd64 | Needs WebKitGTK (`libwebkit2gtk-4.1-0`). Linux arm64 not supported yet. |

## How releases work

**Yes — a new [0x-excali](https://github.com/krafterlabs/0x-excali) GitHub Release requires a change in this tap.**

Homebrew does not watch the upstream repo. Version and `sha256` are pinned in Ruby files here. Until someone updates and pushes this tap, `brew upgrade` keeps the old version.

```
0x-excali publishes Release vX.Y.Z  (DMG + linux tar.gz)
        │
        ▼
Maintainer updates THIS repo (version + sha256), pushes to main
        │
        ▼
Users:  brew update && brew upgrade --cask 0x-excali   # or: brew upgrade ox-excali
```

### End users

1. Wait until this tap is updated for the new version (check recent commits on `main`).
2. Then:

```bash
brew update
brew upgrade --cask 0x-excali   # macOS
brew upgrade ox-excali          # Linux amd64
```

If you upgrade before the tap bumps, you may see a **SHA256 mismatch** — that means the tap is still on the previous release. Wait for the tap update (or ping maintainers).

### Maintainers — bump after an upstream release

Asset names (must match the GitHub Release files):

- macOS: `0x-excali-production-macOS-universal-vX.Y.Z.dmg`
- Linux: `0x-excali-production-linux-amd64-vX.Y.Z.tar.gz`

1. Compute checksums (needs `curl`, `jq`, `shasum`):

```bash
# Option A — GitHub API (needs HOMEBREW_GITHUB_API_TOKEN or GITHUB_TOKEN)
./scripts/compute-sha256.sh krafterlabs 0x-excali vX.Y.Z \
  0x-excali-production-macOS-universal-vX.Y.Z.dmg
./scripts/compute-sha256.sh krafterlabs 0x-excali vX.Y.Z \
  0x-excali-production-linux-amd64-vX.Y.Z.tar.gz

# Option B — public download (no token)
curl -fsSL -o /tmp/dmg "https://github.com/krafterlabs/0x-excali/releases/download/vX.Y.Z/0x-excali-production-macOS-universal-vX.Y.Z.dmg"
shasum -a 256 /tmp/dmg
curl -fsSL -o /tmp/tgz "https://github.com/krafterlabs/0x-excali/releases/download/vX.Y.Z/0x-excali-production-linux-amd64-vX.Y.Z.tar.gz"
shasum -a 256 /tmp/tgz
```

2. Edit:

| File | What to change |
|------|----------------|
| `Casks/0x-excali.rb` | `version` and top-level `sha256` |
| `Formula/ox-excali.rb` | `version` and the `sha256` inside the `on_intel` block |

3. Commit, push to `main`. Users can then `brew update && brew upgrade …`.

`desc` must stay under 80 characters. Do not use `bottle :unneeded`.

## Troubleshooting

**`homebrew-homebrew` / Repository not found** — you tapped without the URL:

```bash
brew untap krafterlabs/homebrew 2>/dev/null || true
brew tap krafterlabs/homebrew https://github.com/krafterlabs/homebrew
```

**`SHA256 mismatch`** — tap not updated for the latest upstream release yet (see [How releases work](#how-releases-work)).

## Optional: rename for the short tap command

GitHub → **Settings → General → Repository name** → rename to `homebrew-tap`, then:

```bash
brew tap krafterlabs/tap
```
