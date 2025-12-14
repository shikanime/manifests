#!/usr/bin/env nix
#! nix shell nixpkgs#nushell --command nu

def get_tailscale_ips [] {
 print "Fetching Tailscale IPs..."
  let peers = (
    ^tailscale status -json
    | from json
    | get Peer
    | values
  )
  let nishir_ip = (
    $peers
    | where HostName == "nishir"
    | get 0
    | get TailscaleIPs
    | get 0
  )
  let fushi_ip = (
    $peers
    | where HostName == "fushi"
    | get 0
    | get TailscaleIPs
    | get 0
  )
  let minish_ip = (
    $peers
    | where HostName == "minish"
    | get 0
    | get TailscaleIPs
    | get 0
  )
  { nishir: $nishir_ip, fushi: $fushi_ip, minish: $minish_ip }
}

def get_longhorn_backup_target [] {
  print "Fetching Longhorn backup target..."
  let backup = (^tofu -chdir=$"($env.FILE_PWD)/../../infra/nishir-services" output -json longhorn_backupstore | from json)
  $"s3://($backup.bucket)@($backup.region)/"
}


def get_latest_chart_version [repo_name: string, chart_name: string, repo_url: string] {
  ^helm repo add $repo_name $repo_url --force-update | ignore
  ^helm repo update | ignore
  let results = ^helm search repo $"($repo_name)/($chart_name)" --output json | from json
  let version = (
    if (($results | length) > 0) {
      $results
      | get 0
      | get version
    } else { null }
  )
  if $version == null or $version == "" or $version == "null" { null } else { $version }
}

def update_hosts [ips: record] {
  let doc = $in
  let hosts = (
    $doc.spec.hosts
    | enumerate
    | each {|it|
      match $it.index {
        0 => {
          $it.item
          | update ssh (
            $it.item.ssh
            | update 'address' $ips.nishir
          )
          | update 'privateAddress' $ips.nishir
        },
        1 => {
          $it.item
          | update ssh (
            $it.item.ssh
            | update 'address' $ips.fushi
          )
          | update 'privateAddress' $ips.fushi
        },
        2 => {
          $it.item
          | update ssh (
            $it.item.ssh
            | update 'address' $ips.minish
          )
          | update 'privateAddress' $ips.minish
        },
        _ => { $it.item }
      }
    }
  )
  $doc
  | upsert spec.hosts $hosts
  | upsert spec.k0s.config.spec.api.address $ips.nishir
}

def update_charts [] {
  let doc = $in
  print "Updating helm chart versions..."
  let repo_map = (
    $doc.spec.k0s.config.spec.extensions.helm.repositories
    | each {|r| { ($r | get name): ($r | get url) } }
    | reduce --fold {} {|acc, row| $acc | merge $row }
  )
  let charts = (
    $doc.spec.k0s.config.spec.extensions.helm.charts
    | par-each {|chart|
      let repo_key = ($chart.chartname | split row "/" | get 0)
      let repo_url = try { $repo_map | get $repo_key } catch { null }
      if $repo_url != null {
        print $"Checking latest version for ($chart.name)..."
        let chart_name_parts = ($chart.chartname | split row "/")
        let latest_version = get_latest_chart_version ($chart_name_parts | get 0) ($chart_name_parts | get 1) ($repo_url)
        if $latest_version != null {
          $chart | update version $latest_version
        } else { $chart }
      } else { $chart }
    }
  )
  $doc | upsert spec.k0s.config.spec.extensions.helm.charts $charts
}

def update_longhorn_charts [backup_target: string] {
  let doc = $in
  let charts = (
    $doc.spec.k0s.config.spec.extensions.helm.charts
    | each {|chart|
      if $chart.name == 'longhorn' {
        let values_doc = (
          $chart.values
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
        $chart | update values ($updated_values_doc | to yaml)
      } else { $chart }
    }
  )
  $doc | upsert spec.k0s.config.spec.extensions.helm.charts $charts
}

def update_multus_manifest [] {
  let doc = $in
  print "Updating Multus CNI manifest..."
  let url = "https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset.yml"
  let content = (http get --raw $url)

  let hosts = (
    $doc.spec.hosts
    | enumerate
    | each {|it|
      if $it.index == 0 {
        let files = (
          $it.item.files
          | each {|f|
            if ($f | get -i name) == "multus-manifests" {
              $f | upsert data $content
            } else { $f }
          }
        )
        $it.item | upsert files $files
      } else { $it.item }
    }
  )

  $doc | upsert spec.hosts $hosts
}

open $"($env.FILE_PWD)/cluster.yaml"
| update_hosts (get_tailscale_ips)
| update_charts
| update_longhorn_charts (get_longhorn_backup_target)
| update_multus_manifest
| to yaml
| save --force $"($env.FILE_PWD)/cluster.yaml"

print "Helm chart version updates completed."
