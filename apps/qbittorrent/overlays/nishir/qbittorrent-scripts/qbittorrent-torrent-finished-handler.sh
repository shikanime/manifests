#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

if [ -z "$1" ]; then
    echo "ERROR: Category is empty. Configure qBittorrent to pass the category (%L) as the first argument." >&2
    exit 1
fi

if [ -z "$2" ]; then
    echo "ERROR: Content Path is empty. Configure qBittorrent to pass the content path (%F) as the second argument." >&2
    exit 1
fi

if [ "$1" == "prowlarr" ]; then
    cp -r "$2" "/data/staging/Downloads"
fi
