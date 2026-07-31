# AGENTS.md

## Cursor Cloud specific instructions

This repository is a **private Homebrew tap scaffold** (Ruby formulas + Bash maintainer scripts). There is no application server, database, or Node/Python package manager.

### Prerequisites (one-time on a fresh VM)

Homebrew is installed to `/home/linuxbrew/.linuxbrew`. Ensure it is on `PATH`:

```bash
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"
```

System tools used by scripts (`git`, `bash`, `curl`, `jq`, `shasum`) are pre-installed on the Cloud VM image.

### Linking the local tap

`brew tap my-org/tools /workspace` may fail on Cloud VMs with a git hardlink error. Use a symlink instead:

```bash
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv bash)"
mkdir -p "$(brew --repository)/Library/Taps/my-org"
ln -sfn /workspace "$(brew --repository)/Library/Taps/my-org/homebrew-tools"
brew trust my-org/tools
```

### Common commands

| Task | Command |
|------|---------|
| List formulas | `brew search my-org/tools/` |
| Formula info | `brew info my-org/tools/example-cli` |
| Audit formula | `brew audit my-org/tools/example-cli` |
| Ruby style | `brew style Formula/example-cli.rb` |
| Generate new formula | `./scripts/generate-formula.sh <name> <version>` |
| Bump version/checksums | `./scripts/update-formula.sh <name> <version> --sha256-linux-amd64 <hash> --no-commit` |
| Dry-run formula update | add `--dry-run` to `update-formula.sh` |
| Compute SHA256 from GitHub release | `./scripts/compute-sha256.sh <owner> <repo> <tag> <asset>` (requires `HOMEBREW_GITHUB_API_TOKEN` or `GITHUB_TOKEN`) |

### Local E2E install testing (without private GitHub)

The scaffold `example-cli` formula uses placeholder checksums and GitHub URLs — `brew install` will not work until real release assets exist. For local verification:

1. Build a tarball with the binary at the archive root (name must match the formula's asset pattern, e.g. `demo-cli-1.0.0-linux-amd64.tar.gz`).
2. Serve it locally: `python3 -m http.server 8765 --bind 127.0.0.1` (from the directory containing the tarball).
3. Use `./scripts/update-formula.sh` to create/update a test formula with the real SHA256, then point the `linux-amd64` `url` at `http://127.0.0.1:8765/...`.
4. Symlink a temp tap copy or work in `/tmp` so the main repo stays clean.

Homebrew 4+ requires `brew trust my-org/tools` (or `brew trust --formula ...`) before installing from a new tap.

### Gotchas

- **`generate-formula.sh` and URLs in `sed`**: If `homepage` or `description` contains `/`, the template `sed` substitutions can fail. Prefer `update-formula.sh` to bootstrap formulas, or escape slashes in values.
- **Private repos**: Homebrew uses `HOMEBREW_GITHUB_API_TOKEN`, not git credentials. See `README.md` for PAT setup.
- **Linux installs**: Homebrew pulls in `bubblewrap` as a dependency for sandboxed installs.
- **No lint/test CI in-repo**: Validation is `brew audit`, `brew style`, and `brew test <formula>` after a successful install.
