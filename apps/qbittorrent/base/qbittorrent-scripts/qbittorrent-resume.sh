#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

if ! command -v qbt &>/dev/null; then
  echo "Error: qbt CLI is not installed. Please ensure it is available in the PATH."
  exit 1
fi

echo 'Checking errored torrents...'

# Get list of errored torrents in CSV format
# qbt torrent list returns a header row, so we need to skip it
TORRENTS_CSV=$(qbt torrent list --filter errored --format csv)

if [ -n "$TORRENTS_CSV" ]; then
  # Skip the header line and read the rest
  # We use tail -n +2 to start from the second line
  # We use while loop with IFS=',' to parse the CSV
  echo "$TORRENTS_CSV" | tail -n +2 | while IFS=',' read -r HASH REST; do
    # Clean up HASH (remove quotes if any, though usually not present for hashes)
    HASH="${HASH%\"}"
    HASH="${HASH#\"}"

    if [ -n "$HASH" ]; then
      echo "Resuming $HASH"
      qbt torrent resume "$HASH"
    fi
  done
else
  echo 'Failed to retrieve torrent list or empty response'
fi
