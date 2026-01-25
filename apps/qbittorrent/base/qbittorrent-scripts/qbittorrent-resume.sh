#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# Install dependencies
echo "Installing dependencies..."
apk add --no-cache curl jq

# Create a temporary file for the cookie
COOKIE_FILE=$(mktemp)
trap 'rm -f "$COOKIE_FILE"' EXIT

# Perform login and save cookie to file
echo "Logging in..."
curl -k -s -c "$COOKIE_FILE" -d "username=${QBT_USER}&password=${QBT_PASSWORD}" "${QBT_URL}/api/v2/auth/login" >/dev/null

# Get list of errored torrents and extract hashes joined by pipes
echo "Checking for errored torrents..."
HASHES=$(curl -k -s -b "$COOKIE_FILE" "${QBT_URL}/api/v2/torrents/info?filter=errored" | jq -r '.[].hash' | paste -sd '|' -)

if [ -n "$HASHES" ]; then
  echo "Resuming torrents: $HASHES"
  curl -k -s -b "$COOKIE_FILE" -X POST -d "hashes=$HASHES" "${QBT_URL}/api/v2/torrents/resume"
  echo "Resume command sent."
else
  echo "No errored torrent found."
fi
