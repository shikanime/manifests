#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Configure Kubeconfig
mkdir -p "$(dirname "$0")/.terraform/tmp/kubernetes"
KUBECONFIG="$(dirname "$0")/.terraform/tmp/kubernetes/config" \
  tailscale configure kubeconfig nishir-k8s-operator

# Fetch all outputs at once and save them to terraform.tfvars.json
tofu -chdir="$(dirname "$0")/../nishir-services" output -json |
  jq 'with_entries(
    select(.key | IN(
      "name",
      "endpoints",
      "etcd_snapshot",
      "longhorn_backupstore",
      "prometheus",
      "loki",
      "tempo",
      "vaultwarden"
    )) |
    .value = .value.value
  )' \
    >"$(dirname "$0")/terraform.tfvars.json"

# Set secure permissions for the tfvars file
chmod 600 "$(dirname "$0")/terraform.tfvars.json"
