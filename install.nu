#!/usr/bin/env nix
#! nix shell nixpkgs#nushell --command nu

ls **/install.nu
| where type == "file" and name != "install.nu"
| get name
| par-each { |path| ^nu $path }
| ignore
