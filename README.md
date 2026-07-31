# krafterlabs/homebrew

Private Homebrew tap for krafterlabs tools.

```bash
export HOMEBREW_GITHUB_API_TOKEN="ghp_..."   # PAT with repo read (tap is private)
brew tap krafterlabs/homebrew
brew install --cask 0x-excali                 # macOS
brew install ox-excali                        # Linux amd64
```

## Token setup

1. GitHub → Settings → Developer settings → [Personal access tokens](https://github.com/settings/tokens)
2. Classic PAT with **`repo`** scope (or fine-grained: Contents read on `krafterlabs/homebrew`)
3. Add to `~/.zshrc` / `~/.bashrc`:

```bash
export HOMEBREW_GITHUB_API_TOKEN="ghp_your_token_here"
```

Homebrew does **not** use your `git` credentials — only this env var.

## Available packages

| Install | Platform | Notes |
|---------|----------|-------|
| `brew install --cask 0x-excali` | macOS | Universal DMG |
| `brew install ox-excali` | Linux amd64 | Needs WebKitGTK (`libwebkit2gtk-4.1-0`) |

## Troubleshooting

**`Repository not found` / `404`** — token missing, expired, or lacking access:

```bash
echo $HOMEBREW_GITHUB_API_TOKEN
brew untap krafterlabs/homebrew && brew tap krafterlabs/homebrew
curl -s -H "Authorization: Bearer $HOMEBREW_GITHUB_API_TOKEN" \
  https://api.github.com/repos/krafterlabs/homebrew | jq .name
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
