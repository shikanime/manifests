#!/usr/bin/env nix
#! nix develop --impure --command bash

set -o errexit
set -o nounset
set -o pipefail

sops \
  --encrypt \
  --encrypted-regex "^(literals)$" \
  "$(dirname "$0")"/kustomization.yaml > \
  "$(dirname "$0")"/kustomization.enc.yaml
# Define chart repositories and their charts
declare -A CHART_REPOS=(
  ["https://kubernetes-sigs.github.io/descheduler"]="descheduler"
  ["https://charts.hetzner.cloud"]="hcloud"
  ["https://charts.fairwinds.com/stable"]="vpa"
)

# Helper to fetch latest chart version
get_latest_chart_version() {
  local repo_url="$1"
  local chart_name="$2"
  helm repo add tmp-repo "$repo_url" >/dev/null 2>&1
  helm repo update tmp-repo >/dev/null 2>&1
  helm search repo tmp-repo/"$chart_name" --output json |
    jq -r '.[0].version'
  helm repo remove tmp-repo >/dev/null 2>&1
}

# Path to the k0s-worker-config-template (adjust if needed)
CLUSTER_YAML="$(dirname "$0")/k0s-worker-config-template"

# Update each chart version
for repo_url in "${!CHART_REPOS[@]}"; do
  chart_name="${CHART_REPOS[$repo_url]}"
  echo "Checking latest version for $chart_name..."

  latest_version=$(get_latest_chart_version "$repo_url" "$chart_name")

  if [[ -n $latest_version && $latest_version != "null" ]]; then
    echo "Updating $chart_name to version $latest_version"

    # Update the version in cluster.yaml based on chart name
    case "$chart_name" in
    "cert-manager")
      yq eval ".spec.k0s.config.spec.extensions.helm.charts[0].version = \"$latest_version\"" -i "$CLUSTER_YAML"
      ;;
    "cluster-api-operator")
      yq eval ".spec.k0s.config.spec.extensions.helm.charts[1].version = \"$latest_version\"" -i "$CLUSTER_YAML"
      ;;
    "descheduler")
      yq eval ".spec.k0s.config.spec.extensions.helm.charts[2].version = \"$latest_version\"" -i "$CLUSTER_YAML"
      ;;
    "longhorn")
      yq eval ".spec.k0s.config.spec.extensions.helm.charts[3].version = \"$latest_version\"" -i "$CLUSTER_YAML"
      ;;
    "node-feature-discovery")
      yq eval ".spec.k0s.config.spec.extensions.helm.charts[4].version = \"$latest_version\"" -i "$CLUSTER_YAML"
      ;;
    "tailscale-operator")
      yq eval ".spec.k0s.config.spec.extensions.helm.charts[5].version = \"$latest_version\"" -i "$CLUSTER_YAML"
      ;;
    "trust-manager")
      yq eval ".spec.k0s.config.spec.extensions.helm.charts[6].version = \"$latest_version\"" -i "$CLUSTER_YAML"
      ;;
    "vpa")
      yq eval ".spec.k0s.config.spec.extensions.helm.charts[7].version = \"$latest_version\"" -i "$CLUSTER_YAML"
      ;;
    esac
  else
    echo "Warning: Could not fetch latest version for $chart_name"
  fi
done

echo "Helm chart version updates completed."
