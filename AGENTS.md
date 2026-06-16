# Manifests

Kubernetes manifests and GitOps configurations for shikanime infrastructure.

**Language:** YAML

## Structure

- `clusters/` — Cluster-specific overlays
- `base/` — Shared base manifests
- `kustomize/` — Kustomize configurations

## Commit Style

- Plain-text capitalized title, no conventional-commit prefix
- Body with labels: `Design:`, `Related:`, `Closes #`
- Keep Markdown lines wrapped at 80 columns and run `nix fmt` before shipping

## Stack

- 1 commit == 1 PR via ghstack
- Amend + `ghstack` to resubmit
- `ghstack land` on head PR to land the entire stack
- Never `gh pr merge` (creates poisoned commits)
- Never force-push ghstack branches
- ghstack only works on HEAD commit chains, not detached HEADs

## Protect `main`

- Require 1 approving review
- Require linear history (no merge commits)
- Require signed commits
- Squash+rebase merge only

Managed via FluxCD. Ensure all manifests are linted before committing
