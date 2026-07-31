# krafterlabs/homebrew

A private [Homebrew tap](https://docs.brew.sh/Taps) for installing internal tools with one command.

```bash
brew tap krafterlabs/homebrew
brew install --cask 0x-excali   # macOS desktop app
brew install 0x-excali          # Linux CLI/desktop binary
```

This repository distributes binaries from private GitHub releases. Because the tap and source repositories are private, you need a GitHub token before Homebrew can access them.

---

## Quick Start

### 1. Create a GitHub Personal Access Token (PAT)

You need a token with **read access to private repositories**.

#### Classic PAT (recommended for simplicity)

1. Open **GitHub → Settings → Developer settings → [Personal access tokens](https://github.com/settings/tokens)**
2. Click **Generate new token (classic)**
3. Set a note, e.g. `homebrew-private-tap`
4. Select scope: **`repo`** (Full control of private repositories — read is sufficient)
5. Click **Generate token** and copy the value (`ghp_...`)

#### Fine-grained PAT (alternative)

1. Open **GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens**
2. Grant **Repository access** to `krafterlabs/homebrew` and any project repos you install from
3. Permissions: **Contents → Read-only**

> Keep your token secret. Never commit it to a repo or share it in chat.

---

### 2. Export the token in your shell

Homebrew reads `HOMEBREW_GITHUB_API_TOKEN` to authenticate against private GitHub repos.

**macOS / Linux (bash/zsh)** — add to `~/.zshrc` or `~/.bashrc`:

```bash
export HOMEBREW_GITHUB_API_TOKEN="ghp_your_token_here"
```

Reload your shell:

```bash
source ~/.zshrc   # or source ~/.bashrc
```

Verify:

```bash
echo $HOMEBREW_GITHUB_API_TOKEN | head -c 10
# Should print the first characters of your token (not empty)
```

---

### 3. Tap this repository

```bash
brew tap krafterlabs/homebrew https://github.com/krafterlabs/homebrew
```

Shorthand (works once GitHub auth is configured):

```bash
brew tap krafterlabs/homebrew
```

---

### 4. Install a tool

**macOS desktop app (Cask):**

```bash
brew install --cask 0x-excali
```

**Linux binary (Formula):**

```bash
brew install 0x-excali
```

List everything available in this tap:

```bash
brew search krafterlabs/homebrew/
```

Get details:

```bash
brew info --cask 0x-excali   # macOS
brew info 0x-excali           # Linux
```

Upgrade when new versions are released:

```bash
brew update
brew upgrade --cask 0x-excali  # macOS
brew upgrade 0x-excali         # Linux
```

---

## Available Tools

| Name | Type | Description |
|------|------|-------------|
| `0x-excali` | Cask (macOS) / Formula (Linux) | Desktop app for drawings with GitHub sync |
| `example-cli` | Formula | Example CLI (scaffold placeholder) |

> macOS GUI apps use `brew install --cask <name>`. Linux binaries use `brew install <name>`.

---

## Troubleshooting

### `Error: Repository not found` or `404 Not Found`

These errors almost always mean Homebrew cannot authenticate to the private tap or release assets.

**Checklist:**

1. **Token is set in the current shell**
   ```bash
   echo $HOMEBREW_GITHUB_API_TOKEN
   ```
   If empty, export it (see step 2 above) and open a new terminal.

2. **Token has not expired**
   - Classic PATs can expire. Generate a new one and update your shell profile.

3. **Token has `repo` scope** (classic) or **Contents read** on the relevant repos (fine-grained).

4. **You have access to the repositories**
   - Ask your admin to grant you read access to `krafterlabs/homebrew` and the project repo.

5. **Re-tap after fixing auth**
   ```bash
   brew untap krafterlabs/homebrew
   brew tap krafterlabs/homebrew
   ```

---

### `SHA256 mismatch` or `Checksum verification failed`

The formula checksum does not match the downloaded release asset. This is a maintainer-side issue — open an issue or ask in your team channel. A new release may have been published without updating the tap.

**Workaround (not recommended for production):**

```bash
brew install --force-bottle project-x
# or
brew fetch --force project-x && brew install project-x
```

---

### `No available formula with the name "project-x"`

The formula may not exist yet, or you may have tapped the wrong org.

```bash
brew untap krafterlabs/homebrew
brew tap krafterlabs/homebrew
brew search krafterlabs/homebrew/
```

---

### Token works for `git clone` but not for `brew install`

Homebrew does **not** use your `git` credentials. It requires `HOMEBREW_GITHUB_API_TOKEN` specifically.

```bash
export HOMEBREW_GITHUB_API_TOKEN="ghp_..."
brew install project-x
```

---

### Still stuck?

1. Run with verbose output and share the log with your team:
   ```bash
   brew install -v project-x
   ```
2. Confirm you can reach the API:
   ```bash
   curl -s -H "Authorization: Bearer $HOMEBREW_GITHUB_API_TOKEN" \
     https://api.github.com/repos/krafterlabs/homebrew | jq .name
   ```
   Expected: `"homebrew"`. If you see `"Not Found"`, fix token/access first.

---

## For Maintainers

See [docs/PROJECT_REPO_INTEGRATION.md](docs/PROJECT_REPO_INTEGRATION.md) for registering projects, release automation, and the full integration guide.

### Formula quality checklist

Before merging or releasing a formula change, confirm:

- [ ] `desc` is strictly under 80 characters
- [ ] `license` is set (e.g. `MIT` or `LicenseRef-Proprietary`)
- [ ] Each platform has explicit `url` and `sha256` (no checksum-less downloads)
- [ ] Pre-built binary formulas include `bottle :unneeded`
- [ ] Runtime and build-time `depends_on` stanzas are separate (if any)
- [ ] No deprecated Homebrew DSL (`option`, legacy install patterns)
- [ ] `test` block runs a simple smoke test (`--version` or `--help`)
- [ ] `./scripts/audit-formula.sh` passes (or CI audit step is green)

### Scripts

| Script | Purpose |
|--------|---------|
| `scripts/fetch-release-metadata.sh` | Fetch release assets and sha256 flags from GitHub |
| `scripts/update-formula.sh` | Update `Formula/<project>.rb` with a new version |
| `scripts/compute-sha256.sh` | Compute sha256 for a single release asset |
| `scripts/generate-formula.sh` | Bootstrap a new formula from the template |
| `scripts/audit-formula.sh` | Validate desc lengths and run `brew audit` |

---

## Repository Layout

```
.
├── Formula/          # One .rb file per installable CLI tool
├── Casks/            # macOS GUI apps (optional)
├── Aliases/          # Formula shortcuts (optional)
├── config/           # Project registry (projects.yaml)
├── scripts/          # Formula update automation
├── templates/        # Formula template for new projects
└── .github/workflows/  # Tap auto-update on release
```

---

## License

Internal use only. All distributed software remains subject to its respective project licenses.
