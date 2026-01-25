#!/usr/bin/env sh

set -o errexit
set -o nounset
set -o pipefail

# Install dependencies
echo "Installing dependencies..."
apk add curl jq

# Create a temporary file for the cookie
COOKIE_FILE=$(mktemp)
trap 'rm -f "$COOKIE_FILE"' EXIT

# Perform login and save cookie to file
echo "Logging in..."
curl \
  --show-error \
  --fail \
  --cookie-jar "$COOKIE_FILE" \
  --data-urlencode "username=${QBT_USER}" \
  --data-urlencode "password=${QBT_PASSWORD}" \
  "${QBT_URL}/api/v2/auth/login"

# Get list of errored torrents and extract hashes joined by pipes
echo "Checking for errored torrents..."
HASHES=$(curl \
  --show-error \
  --fail \
  --cookie "$COOKIE_FILE" \
  "${QBT_URL}/api/v2/torrents/info?filter=errored" |
  jq --raw-output '.[].hash' |
  paste -sd '|' -)

if [ -n "$HASHES" ]; then
  echo "Resuming torrents: $HASHES"
  curl \
    --show-error \
    --fail \
    --cookie "$COOKIE_FILE" \
    --request POST \
    --data-urlencode "hashes=$HASHES" \
    "${QBT_URL}/api/v2/torrents/resume"
  echo "Resume command sent."
else
  echo "No errored torrent found."
fi
