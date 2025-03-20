#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Fetch all outputs at once and save them to terraform.tfvars.json
tofu -chdir="$(dirname "$0")/../nishir-services" output -json |
  jq 'with_entries(
    select(.key | IN(
      "tailscale_operator"
    )) |
    .value = .value.value
  )' >"$(dirname "$0")/terraform.tfvars.json"

# Set secure permissions for the tfvars file
chmod 600 "$(dirname "$0")/terraform.tfvars.json"
