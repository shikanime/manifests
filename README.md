<!-- markdownlint-disable first-line-heading MD041 -->

![header.png](https://raw.githubusercontent.com/shikanime/shikanime/main/assets/github-header.png)

<!-- markdownlint-enable first-line-heading -->

# Manifests

Hey 🌸 I'm Shikanime Deva, this repository contains the Kubernetes
manifests for my clusters.

## What’s In Here

This repo is organized around Kustomize:

- `apps/` contains application manifests (bases, optional components, and
  per-cluster overlays)
- `clusters/` contains cluster entrypoints that compose shared cluster bits +
  app overlays
- `skaffold.yaml` provides renderable profiles that point at the cluster overlay
  entrypoints

### Repository Layout

#### Apps

Each app is typically structured like:

- `apps/<app>/base/`: app resources that are common everywhere
- `apps/<app>/components/`: optional Kustomize components (e.g. `tls/`, `ftp/`,
  `v4l/`)
- `apps/<app>/overlays/<cluster>/`: cluster-specific patches/config
- `apps/<app>/overlays/<cluster>-tailnet/`: cluster-specific overlays for the
  “tailnet” flavor (when applicable)

#### Clusters

Each cluster typically looks like:

- `clusters/<cluster>/base/`: namespaces, shared PVCs, default policies, etc.
- `clusters/<cluster>/components/`: cluster-wide components (e.g. `tls/`,
  `tailscale/`, `longhorn/`)
- `clusters/<cluster>/overlays/<overlay>/`: build entrypoints that compose
  cluster components + selected app overlays

For example, `clusters/nishir/overlays/tailnet/kustomization.yaml` pulls in
cluster components and a list of `apps/*/overlays/nishir-tailnet`, plus the
cluster `base`.

### Getting A Dev Environment

This repo ships a Nix flake + `direnv` integration so you can get consistent
tooling (`kustomize`, `kubectl`, `helm`, `skaffold`, `sops`, …).

- With `direnv`:
  - `nix run nixpkgs#direnv allow`
- Without `direnv`:
  - `nix develop --accept-flake-config --no-pure-eval`

### Rendering Manifests

You can render via Skaffold (preferred for the predefined profiles) or directly
with Kustomize.

- Render with Skaffold:
  - `skaffold render --profile nishir-tailnet`
  - `skaffold render --profile telsha-tailnet`
- Render with Kustomize:
  - `kustomize build clusters/nishir/overlays/tailnet`
  - `kustomize build clusters/telsha/overlays/tailnet`

### Secrets (SOPS)

Secrets/config files are stored encrypted on disk using SOPS and Age.

- Encrypted files follow the pattern `*.enc.*` (for example `.enc.env`,
  `config.enc.yaml`)
- When working locally inside the dev shell, a decrypt task writes decrypted
  siblings by removing `.enc.` from the filename (for example `.enc.env` → `.env`)
- Decrypted files are treated as generated/sensitive and are ignored (or should
  be kept ignored) by git

CI runs with `SOPS_AGE_KEY` provided as a secret to allow decryption when
evaluating the flake.

### CI / Checks

The main “does this repo still evaluate and render?” check is:

- `nix flake check --accept-flake-config --no-pure-eval`
