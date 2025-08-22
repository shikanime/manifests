#!/usr/bin/env nix
#! nix develop --impure --command bash

set -o errexit
set -o nounset
set -o pipefail

# Get the directory where this script is located
CLUSTER_YAML="$(dirname "$0")/cluster.yaml"

# Get Tailscale IPs for all three nodes
echo "Fetching Tailscale IPs..."
NISHIR_IP=$(tailscale status -json | jq -r '.Peer[] | select(.HostName == "nishir") | .TailscaleIPs[0]')
FUSHI_IP=$(tailscale status -json | jq -r '.Peer[] | select(.HostName == "fushi") | .TailscaleIPs[0]')
MINISH_IP=$(tailscale status -json | jq -r '.Peer[] | select(.HostName == "minish") | .TailscaleIPs[0]')

# Update the cluster.yaml file using yq
yq eval ".spec.hosts[0].ssh.address = \"$NISHIR_IP\"" -i "$CLUSTER_YAML"
yq eval ".spec.hosts[1].ssh.address = \"$FUSHI_IP\"" -i "$CLUSTER_YAML"
yq eval ".spec.hosts[2].ssh.address = \"$MINISH_IP\"" -i "$CLUSTER_YAML"

# Get the longhorn_backupstore output from nishir-services
BACKUP_CONFIG=$(tofu -chdir="$(dirname "$0")/../../infra/nishir-services" output -json longhorn_backupstore)

# Extract bucket and region
BUCKET=$(echo "$BACKUP_CONFIG" | jq -r '.bucket')
REGION=$(echo "$BACKUP_CONFIG" | jq -r '.region')

# Update the cluster.yaml file
sed -i \
  -e "s|backupTarget:.*$|backupTarget: s3://${BUCKET}@${REGION}/|g" \
  "$(dirname "$0")/cluster.yaml"

# Function to get latest helm chart version
get_latest_chart_version() {
  local repo_url="$1"
  local chart_name="$2"

  # Add the helm repository temporarily
  local repo_name="temp-$(echo "$repo_url" | sed 's|[^a-zA-Z0-9]|-|g')"
  helm repo add "$repo_name" "$repo_url" --force-update >/dev/null 2>&1
  helm repo update >/dev/null 2>&1

  # Get the latest version
  local latest_version
  latest_version=$(helm search repo "$repo_name/$chart_name" --output json | jq -r '.[0].version')

  # Clean up the temporary repository
  helm repo remove "$repo_name" >/dev/null 2>&1

  echo "$latest_version"
}

# Update helm chart versions
echo "Updating helm chart versions..."

# Define chart repositories and their charts
declare -A CHART_REPOS=(
  ["https://charts.jetstack.io"]="cert-manager"
  ["https://kubernetes-sigs.github.io/cluster-api-operator"]="cluster-api-operator"
  ["https://kubernetes-sigs.github.io/descheduler"]="descheduler"
  ["https://charts.longhorn.io"]="longhorn"
  ["https://kubernetes-sigs.github.io/node-feature-discovery/charts"]="node-feature-discovery"
  ["https://charts.fairwinds.com/stable"]="vpa"
  ["https://pkgs.tailscale.com/helmcharts"]="tailscale-operator"
)

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
      yq eval ".spec.k0s.config.spec.extensions.helm.charts[] | select(.name == \"cert-manager\") | .version = \"$latest_version\"" -i "$CLUSTER_YAML"
      ;;
    "cluster-api-operator")
      yq eval ".spec.k0s.config.spec.extensions.helm.charts[] | select(.name == \"cluster-api-operator\") | .version = \"$latest_version\"" -i "$CLUSTER_YAML"
      ;;
    "descheduler")
      yq eval ".spec.k0s.config.spec.extensions.helm.charts[] | select(.name == \"descheduler\") | .version = \"$latest_version\"" -i "$CLUSTER_YAML"
      ;;
    "longhorn")
      yq eval ".spec.k0s.config.spec.extensions.helm.charts[] | select(.name == \"longhorn\") | .version = \"$latest_version\"" -i "$CLUSTER_YAML"
      ;;
    "node-feature-discovery")
      yq eval ".spec.k0s.config.spec.extensions.helm.charts[] | select(.name == \"node-feature-discovery\") | .version = \"$latest_version\"" -i "$CLUSTER_YAML"
      ;;
    "vpa")
      yq eval ".spec.k0s.config.spec.extensions.helm.charts[] | select(.name == \"vpa\") | .version = \"$latest_version\"" -i "$CLUSTER_YAML"
      ;;
    "tailscale-operator")
      yq eval ".spec.k0s.config.spec.extensions.helm.charts[] | select(.name == \"tailscale-operator\") | .version = \"$latest_version\"" -i "$CLUSTER_YAML"
      ;;
    esac
  else
    echo "Warning: Could not fetch latest version for $chart_name"
  fi
done

echo "Helm chart version updates completed."
