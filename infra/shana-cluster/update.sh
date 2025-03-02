#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Get SSH keys from OpenTofu outputs
tofu output -raw ssh_private_key > ~/.ssh/shana_ed25519
tofu output -raw ssh_public_key > ~/.ssh/shana_ed25519.pub

# Set correct permissions
chmod 600 ~/.ssh/shana_ed25519
chmod 644 ~/.ssh/shana_ed25519.pub
