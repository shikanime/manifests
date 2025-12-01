#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

CATEGORY="${1:-}"
CONTENT_PATH="${2:-}"

if [ -z "$CATEGORY" ]; then
  echo "ERROR: Category is empty. Configure qBittorrent to pass the category (%L) as the first argument." >&2
  exit 1
fi

if [ -z "$CONTENT_PATH" ]; then
  echo "ERROR: Content Path is empty. Configure qBittorrent to pass the content path (%F) as the second argument." >&2
  exit 1
fi

if [ "$CATEGORY" == "prowlarr" ]; then
  cp -r "$CONTENT_PATH" "/data/staging/Downloads"
fi
