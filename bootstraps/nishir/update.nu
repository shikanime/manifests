#!/usr/bin/env nix
#! nix shell nixpkgs#nushell --command nu

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
          if $chart.chartname == "fairwinds-stable/vpa" and $latest_version == "10.2.0" {
            $chart
          } else {
            $chart | update version $latest_version
          }
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

open $"($env.FILE_PWD)/cluster.yaml"
| update_charts
| update_longhorn_charts (get_longhorn_backup_target)
| to yaml
| save --force $"($env.FILE_PWD)/cluster.yaml"

print "Helm chart version updates completed."
