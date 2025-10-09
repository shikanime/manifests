#!/usr/bin/env nix
#! nix develop --impure --command bash

set -o errexit
set -o nounset
set -o pipefail

sops \
  --decrypt \
  "$(dirname "$0")"/grafana-cloud-logs-k8s-monitoring/.enc.env > \
  "$(dirname "$0")"/grafana-cloud-logs-k8s-monitoring/.env

sops \
  --decrypt \
  "$(dirname "$0")"/grafana-cloud-metrics-k8s-monitoring/.enc.env > \
  "$(dirname "$0")"/grafana-cloud-metrics-k8s-monitoring/.env

sops \
  --decrypt \
  "$(dirname "$0")"/grafana-cloud-otlp-k8s-monitoring/.enc.env > \
  "$(dirname "$0")"/grafana-cloud-otlp-k8s-monitoring/.env
