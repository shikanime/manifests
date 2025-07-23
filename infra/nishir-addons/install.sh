#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Configure Kubeconfig
mkdir -p "$(dirname "$0")/.terraform/tmp/kubernetes"
k0sctl kubeconfig -c "$(dirname "$0")/../../machines/nishir/cluster.yaml" \
  > "$(dirname "$0")/.terraform/tmp/kubernetes/config"

# Fetch all outputs at once and save them to terraform.tfvars.json
tofu -chdir="$(dirname "$0")/../nishir-services" output -json |
  jq 'with_entries(
    select(.key | IN(
      "name",
      "endpoints",
      "loki",
      "longhorn_backupstore",
      "prometheus",
      "pyroscope",
      "tailscale_operator",
      "tempo",
      "vaultwarden"
    )) |
    .value = .value.value
  )' \
    >"$(dirname "$0")/terraform.tfvars.json"

# Set secure permissions for the tfvars file
chmod 600 "$(dirname "$0")/terraform.tfvars.json"
