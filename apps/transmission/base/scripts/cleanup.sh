#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Allowed labels for deletion
ALLOWED_LABELS="Prowlarr|Radarr|Sonarr|Whisparr"

if [ -z "$TR_TORRENT_ID" ]; then
  echo "ERROR: TR_TORRENT_ID environment variable not set. Aborting."
  exit 1
fi

# Get torrent info from transmission-remote to check labels
torrent_info=$(transmission-remote --torrent "$TR_TORRENT_ID" --info)

# Extract the label
label=$(echo "$torrent_info" | grep "^Label:" | awk '{print $2}')

# Check if the label matches any of the allowed labels
if [[ "$label" =~ $ALLOWED_LABELS ]]; then
  transmission-remote \
    --torrent "$TR_TORRENT_ID" \
    --remove-and-delete
fi
