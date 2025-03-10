#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Get SSH keys from OpenTofu JSON output
output=$(tofu output -json)
echo "${output}" | jq -r '.ssh_private_key.value' >"$HOME/.ssh/shana_ed25519"
echo "${output}" | jq -r '.ssh_public_key.value' >"$HOME/.ssh/shana_ed25519.pub"

# Set correct permissions
chmod 600 ~/.ssh/shana_ed25519
chmod 644 ~/.ssh/shana_ed25519.pub
