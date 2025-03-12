#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Get Tailscale status for FTP device in JSON format
FTP_IP=$(tailscale status -json | jq -r '.Peer[] | select(.HostName=="ftp") | .TailscaleIPs[0]')

# Update the StatefulSet YAML with the new IP
sed -i \
  -e "s/value: \"[0-9.]*\"/value: \"${FTP_IP}\"/" "$(dirname "$0")/sts.yaml"
