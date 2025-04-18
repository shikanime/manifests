#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# Start RKE2
systemctl start rke2-server.service
