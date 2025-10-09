#!/usr/bin/env nix
#! nix develop --impure --command bash

set -o errexit
set -o nounset
set -o pipefail

sops \
  --encrypt \
  "$(dirname "$0")"/grafana-cloud-logs-k8s-monitoring/.env > \
  "$(dirname "$0")"/grafana-cloud-logs-k8s-monitoring/.enc.env

sops \
  --encrypt \
  "$(dirname "$0")"/grafana-cloud-metrics-k8s-monitoring/.env > \
  "$(dirname "$0")"/grafana-cloud-metrics-k8s-monitoring/.enc.env

sops \
  --encrypt \
  "$(dirname "$0")"/grafana-cloud-otlp-k8s-monitoring/.env > \
  "$(dirname "$0")"/grafana-cloud-otlp-k8s-monitoring/.enc.env
