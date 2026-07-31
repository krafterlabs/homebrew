# Integrating a Project Repository with the Tap

This document is for **maintainers** of the 100 private project repos. End-users do not need to read this.

## Overview

When a project cuts a GitHub Release, a workflow in the project repo notifies this tap via `repository_dispatch`. The tap workflow updates `Formula/<project>.rb` and commits the change automatically.

```
Project repo (release published)
        │
        ▼
  repository_dispatch
        │
        ▼
homebrew-tools / update-tap.yml
        │
        ▼
  Formula/<project>.rb updated + committed
```

## One-Time Setup per Project

### 1. Register the project

Add an entry to `config/projects.yaml`:

```yaml
projects:
  - name: project-x
    github_org: my-org
    repo: project-x
    description: "CLI tool for doing X"
    homepage: https://github.com/my-org/project-x
    binary: project-x
    asset_pattern: "project-x-{{ .Version }}-{{ .OS }}-{{ .Arch }}.tar.gz"
```

### 2. Bootstrap the formula (first time only)

```bash
./scripts/generate-formula.sh project-x 1.0.0
# Or let the first release workflow create it via update-formula.sh
```

### 3. Standardize release asset names

Publish tarballs on each release with this naming convention:

```
<repo>-<version>-<os>-<arch>.tar.gz
```

Examples:

- `project-x-1.2.3-darwin-arm64.tar.gz`
- `project-x-1.2.3-darwin-amd64.tar.gz`
- `project-x-1.2.3-linux-arm64.tar.gz`
- `project-x-1.2.3-linux-amd64.tar.gz`

Each archive must contain the binary at the top level (same name as `binary` in `projects.yaml`).

### 4. Add the notify workflow to the project repo

Copy `.github/workflows/examples/project-release-notify-tap.yml` into the project repo as `.github/workflows/notify-homebrew-tap.yml`.

### 5. Configure secrets

In the **project repo**, add:

| Secret | Description |
|--------|-------------|
| `TAP_UPDATE_TOKEN` | PAT or fine-grained token that can dispatch events to `my-org/homebrew-tools` and allows the tap workflow to push commits |

In the **tap repo** (`homebrew-tools`), add:

| Secret | Description |
|--------|-------------|
| `TAP_UPDATE_TOKEN` | PAT with `repo` scope (or fine-grained: Contents read/write on this tap repo). Used by `update-tap.yml` to push formula commits. |

> **Tip:** A machine-user PAT shared across all project repos simplifies operations at scale.

## Manual Formula Update

```bash
export HOMEBREW_GITHUB_API_TOKEN="ghp_..."

# Compute checksums
./scripts/compute-sha256.sh my-org project-x v1.2.3 project-x-1.2.3-darwin-arm64.tar.gz

# Update formula
./scripts/update-formula.sh project-x 1.2.3 \
  --sha256-darwin-arm64 "<hash>" \
  --sha256-darwin-amd64 "<hash>" \
  --sha256-linux-arm64 "<hash>" \
  --sha256-linux-amd64 "<hash>"
```

Or trigger **Actions → Update Tap Formula → Run workflow** in the GitHub UI.

## Go / Node Build Recommendations

### Go

Use `goreleaser` with archive naming:

```yaml
archives:
  - name_template: "{{ .ProjectName }}-{{ .Version }}-{{ .Os }}-{{ .Arch }}"
```

### Node

Package standalone binaries with `pkg` or `nexe`, then upload platform-specific tarballs following the naming convention above.
