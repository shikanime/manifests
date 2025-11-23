#!/usr/bin/env nix
#! nix develop --impure --command nu

print "Fetching Tailscale IPs..."
let peers = (^tailscale status -json | from json | get Peer | values)
let nishir_ip = $peers | where HostName == "nishir" | get 0 | get TailscaleIPs | get 0
let fushi_ip = $peers | where HostName == "fushi" | get 0 | get TailscaleIPs | get 0
let minish_ip = $peers | where HostName == "minish" | get 0 | get TailscaleIPs | get 0

let cluster = open $"($env.FILE_PWD)/cluster.yaml"

let hosts = ($cluster.spec.hosts | enumerate | each {|it|
  match $it.index {
    0 => { $it.item | update ssh ($it.item.ssh | update 'address' $nishir_ip) | update 'privateAddress' $nishir_ip },
    1 => { $it.item | update ssh ($it.item.ssh | update 'address' $fushi_ip) | update 'privateAddress' $fushi_ip },
    2 => { $it.item | update ssh ($it.item.ssh | update 'address' $minish_ip) | update 'privateAddress' $minish_ip },
    _ => { $it.item }
  }
})

let backup = (^tofu -chdir=$"($env.FILE_PWD)/../../infra/nishir-services" output -json longhorn_backupstore | from json)
let backup_target = $"s3://($backup.bucket)@($backup.region)/"

print "Updating helm chart versions..."
let chart_repos = {
  "cert-manager": "https://charts.jetstack.io",
  "cluster-api-operator": "https://kubernetes-sigs.github.io/cluster-api-operator",
  "descheduler": "https://kubernetes-sigs.github.io/descheduler",
  "longhorn": "https://charts.longhorn.io",
  "node-feature-discovery": "https://kubernetes-sigs.github.io/node-feature-discovery/charts",
  "tailscale-operator": "https://pkgs.tailscale.com/helmcharts",
  "trust-manager": "https://charts.jetstack.io",
  "vpa": "https://charts.fairwinds.com/stable"
}

def get_latest_chart_version [repo_url: string, chart_name: string] {
  let repo_name = $"temp-($repo_url | str replace -a -r '[^a-zA-Z0-9]' '-')"
  ^helm repo add $repo_name $repo_url --force-update | ignore
  ^helm repo update | ignore
  let results = ^helm search repo $"($repo_name)/($chart_name)" --output json | from json
  let version = $results | get 0 | get version
  ^helm repo remove $repo_name | ignore
  $version
}

let charts = (
  $cluster.spec.k0s.config.spec.extensions.helm.charts
  | each {|chart|
    let chart_name = $chart.name
    let repo_url = try { $chart_repos | get $chart_name } catch { null }
    let chart_with_version = if $repo_url != null {
      print $"Checking latest version for ($chart_name)..."
      let latest_version = get_latest_chart_version $repo_url $chart_name
      if $latest_version != null and $latest_version != "" and $latest_version != "null" {
        $chart | update version $latest_version
      } else { $chart }
    } else { $chart }
    let chart_final = if $chart_name == 'longhorn' {
    let values_doc = (
      $chart_with_version.values
      | from yaml
    )
    let new_dbs = (
      (try { $values_doc.defaultBackupStore } catch { {} })
      | upsert backupTarget $backup_target
    )
    let updated_values_doc = (
      $values_doc
      | upsert defaultBackupStore $new_dbs
    )
      $chart_with_version
      | update values (
        $updated_values_doc
        | to yaml
      )
    } else { $chart_with_version }
    $chart_final
  }
)

let cluster = (
  $cluster
  | upsert spec.hosts $hosts
  | upsert spec.k0s.config.spec.api.address $nishir_ip
  | upsert spec.k0s.config.spec.extensions.helm.charts $charts
)

print "Helm chart version updates completed."

# Write all changes back to cluster.yaml
$cluster | to yaml | save --force $"($env.FILE_PWD)/cluster.yaml"
