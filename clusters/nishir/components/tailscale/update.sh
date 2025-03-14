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
  DNS_NAME=$(tailscale status -json | jq -r '({("\(.Self.PublicKey)"): .Self} + .Peer)[] | select(.HostName=="'"${HOST}"'") | .DNSName' | sed 's/\.$//')

  if [[ -z $DNS_NAME ]]; then
    echo "[${HOST}] Host not found in Tailscale network"
    return 1
  fi

  echo "[${HOST}] Found DNS name: ${DNS_NAME}"

  SVC_FILE="$(dirname "$0")/svc.yaml"
  if [[ -f $SVC_FILE ]]; then
    echo "[${HOST}] Updating $SVC_FILE..."
    OCCURRENCE=$((INDEX + 1))

    NAMN_LINE=$(grep -n "name:" "$SVC_FILE" | cut -d: -f1 | sed -n "${OCCURRENCE}p")
    ANNOTATION_LINE=$(grep -n "tailscale.com/tailnet-fqdn:" "$SVC_FILE" | cut -d: -f1 | sed -n "${OCCURRENCE}p")
    EXTENRAL_NAME_LINE=$(grep -n "externalName:" "$SVC_FILE" | cut -d: -f1 | sed -n "${OCCURRENCE}p")

    sed -i \
      -e "${NAMN_LINE}s|name:.*|name: ${HOST}|" \
      -e "${ANNOTATION_LINE}s|tailscale.com/tailnet-fqdn: .*|tailscale.com/tailnet-fqdn: ${DNS_NAME}|" \
      -e "${EXTENRAL_NAME_LINE}s|externalName: .*|externalName: ${DNS_NAME}|" \
      "$SVC_FILE"

    echo "[${HOST}] Updated $SVC_FILE"
  else
    echo "[${HOST}] Service file not found: $SVC_FILE"
  fi
done

wait
