#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

sops --decrypt kustomization.enc.yaml >kustomization.yaml
