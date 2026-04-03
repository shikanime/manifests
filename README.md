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
- `bootstraps/` contains cluster bootstrap inputs (controllers/operators
  installation lives here)
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
  cluster base + components + selected app overlays

For example, `clusters/nishir/overlays/tailnet/kustomization.yaml` pulls in
cluster components and a list of `apps/*/overlays/nishir-tailnet`, plus the
cluster `base`.

## Architecture

This repository is intentionally split into two concerns:

- Compose and configure cluster services and apps with Kustomize (`clusters/` +
  `apps/`)
- Bootstrap the controllers/operators those manifests depend on (`bootstraps/`)

### Bootstrap

The Kustomize overlays assume the underlying controllers/operators already
exist. Those are installed out-of-band using the manifests in `bootstraps/`.

- `bootstraps/nishir/` contains a k0sctl cluster definition
  ([cluster.yaml](bootstraps/nishir/cluster.yaml))
- `bootstraps/telsha/` contains `HelmChart` resources
  ([helmchart.yaml](bootstraps/telsha/helmchart.yaml))

### Clusters

This repo currently defines two cluster trees:

- `clusters/nishir/` (overlay: `tailnet`, components: grafana, longhorn,
  node-feature, tailscale, tls)
- `clusters/telsha/` (overlay: `tailnet`, component: tailscale)

### Cluster Services (Add-ons)

The “cluster services” in this repo are mostly configuration and glue for
controllers installed during bootstrap.

- TLS / trust distribution:
  - cert-manager resources (issuers/certs) under `clusters/<cluster>/components/tls/`
  - trust-manager `Bundle` to publish CA material to workloads as a ConfigMap
- Tailnet ingress:
  - Tailscale Operator credentials under `clusters/<cluster>/components/tailscale/`
  - app overlays patch `Ingress` to use `ingressClassName: tailscale` and set
    `ProxyClass`
- Storage:
  - Longhorn settings, storage class, and recurring jobs under `clusters/<cluster>/components/longhorn/`
- Observability:
  - Grafana k8s monitoring / Alloy remote config secrets under
    `clusters/<cluster>/components/grafana/`
- Scheduling / hardware discovery:
  - Node Feature Discovery rules under `clusters/<cluster>/components/node-feature/`
- Vertical Pod Autoscaler:
  - many apps include `vpa.yaml` and expect a VPA controller to be present

### How Apps Plug In

Most apps follow the same pattern:

- Workload: `Deployment` or `StatefulSet` in `apps/<app>/base/`
- Network: `Service` + `Ingress` in `apps/<app>/base/`, patched per overlay
  - tailnet overlays typically set `ingressClassName: tailscale` and attach a
    `ProxyClass`
    (example:
    [patch-ingress.yaml](apps/jellyfin/overlays/nishir-tailnet/patch-ingress.yaml))
- Storage: a `PVC` in `apps/<app>/overlays/<cluster>/` (or `*-tailnet/`) bound to
  a Longhorn `PV`
- Secrets/config: stored as `*.enc.*` and fed into `secretGenerator` (see
  [Secrets (SOPS)](#secrets-sops))

Hardware-dependent apps can also add scheduling constraints via components (example:
[patch-sts.yaml](apps/jellyfin/components/v4l/patch-sts.yaml)), which rely on NFD
labels from
[nodefeature.yaml](clusters/nishir/components/node-feature/nodefeature.yaml).
