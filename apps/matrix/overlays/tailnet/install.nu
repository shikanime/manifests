#!/usr/bin/env nix
#! nix develop --impure --command nu

let base = (pwd)
for dir in (ls | where type == "Dir" | get name) {
  let script = ($dir | path join "install.nu")
  if (path exists $script) {
    cd $dir
    ^nu install.nu
    cd $base
  }
}
