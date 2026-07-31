# krafterlabs/homebrew

Private-or-public Homebrew tap for krafterlabs tools.

> **Important:** Homebrew turns `brew tap krafterlabs/NAME` into a clone of
> `github.com/krafterlabs/homebrew-NAME`. This repo is named `homebrew`, so you
> must pass the clone URL explicitly (or rename the repo to `homebrew-tap` and
> use `brew tap krafterlabs/tap`).

```bash
# Tap (URL required until the GitHub repo is renamed to homebrew-tap)
brew tap krafterlabs/homebrew https://github.com/krafterlabs/homebrew

# Install
brew install --cask 0x-excali   # macOS
brew install ox-excali          # Linux amd64
```

## Optional: rename for the short tap command

On GitHub → **Settings → General → Repository name**, rename to `homebrew-tap`.
Then users can run:

```bash
brew tap krafterlabs/tap
```

## Token (only if the tap is private)

```bash
export HOMEBREW_GITHUB_API_TOKEN="ghp_..."   # classic PAT with repo read
```

This repo is **public** — a token is not required to tap or install.

## Available packages

| Install | Platform | Notes |
|---------|----------|-------|
| `brew install --cask 0x-excali` | macOS | Universal DMG |
| `brew install ox-excali` | Linux amd64 | Needs WebKitGTK (`libwebkit2gtk-4.1-0`) |

## Troubleshooting

**`homebrew-homebrew` / Repository not found** — you ran `brew tap krafterlabs/homebrew` without the URL. Use:

```bash
brew untap krafterlabs/homebrew 2>/dev/null || true
brew tap krafterlabs/homebrew https://github.com/krafterlabs/homebrew
```

**`SHA256 mismatch`** — tap not updated for the latest release; ping maintainers.

## Maintainers

Bump versions by editing `Casks/0x-excali.rb` and `Formula/ox-excali.rb` (`version` + `sha256`).

```bash
./scripts/compute-sha256.sh krafterlabs 0x-excali v1.0.5 \
  0x-excali-production-macOS-universal-v1.0.5.dmg
./scripts/compute-sha256.sh krafterlabs 0x-excali v1.0.5 \
  0x-excali-production-linux-amd64-v1.0.5.tar.gz
```

`desc` must stay under 80 characters. Do not use `bottle :unneeded` (removed from Homebrew).
