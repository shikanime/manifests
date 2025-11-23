#!/usr/bin/env nix
#! nix develop --impure --command nu

let root = (pwd)

for app_dir in (ls apps/* | where type == "Dir" | get name) {
  let base_script = ($app_dir | path join "base" | path join "install.nu")
  if (path exists $base_script) {
    cd ($app_dir | path join "base")
    ^nu install.nu
    cd $root
  }

  for component_dir in (ls ($app_dir | path join "components" | path join "*") | where type == "Dir" | get name) {
    let script = ($component_dir | path join "install.nu")
    if (path exists $script) {
      cd $component_dir
      ^nu install.nu
      cd $root
    }
  }

  for overlay_dir in (ls ($app_dir | path join "overlays" | path join "*") | where type == "Dir" | get name) {
    let script = ($overlay_dir | path join "install.nu")
    if (path exists $script) {
      cd $overlay_dir
      ^nu install.nu
      cd $root
    }
  }
}

for dir in (ls infra/* | where type == "Dir" | get name) {
  let script = ($dir | path join "install.nu")
  if (path exists $script) {
    cd $dir
    ^nu install.nu
    cd $root
  }
}
