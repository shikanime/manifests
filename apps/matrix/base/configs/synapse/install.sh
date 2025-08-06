#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

sops --decrypt "$(dirname "$0")"/homeserver.enc.yaml >homeserver.yaml
