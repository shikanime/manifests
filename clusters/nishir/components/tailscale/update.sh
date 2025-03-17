#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Define an array of Tailscale device to connect
HOSTS=(
  "kaltashar"
  "nishir"
)

# Process hosts in parallel
for INDEX in "${!HOSTS[@]}"; do
  HOST="${HOSTS[$INDEX]}"
  echo "[${HOST}] Updating DNS configuration..."

  # Get DNS name from Tailscale
  DNS_NAME=$(
    tailscale status -json |
      jq -r '({("\(.Self.PublicKey)"): .Self} + .Peer)[] | select(.HostName=="'"${HOST}"'") | .DNSName' |
      sed 's/\.$//'
  )

  if [[ -z $DNS_NAME ]]; then
    echo "[${HOST}] Host not found in Tailscale network"
    return 1
  fi

  echo "[${HOST}] Found DNS name: ${DNS_NAME}"

  SVC_FILE="$(dirname "$0")/svc.yaml"
  if [[ -f $SVC_FILE ]]; then
    echo "[${HOST}] Updating $SVC_FILE..."

    # Update the YAML document at the specified index
    yq -i "(select(di == ${INDEX}) | .metadata.name = \"${HOST}\" | .metadata.annotations.\"tailscale.com/hostname\" = \"nishir-egress-${HOST}\" | .metadata.annotations.\"tailscale.com/tailnet-fqdn\" = \"${DNS_NAME}\" | .spec.externalName = \"${DNS_NAME}\") // ." "$SVC_FILE"

    echo "[${HOST}] Updated $SVC_FILE"
  else
    echo "[${HOST}] Service file not found: $SVC_FILE"
  fi
done

wait
