#!/usr/bin/env nix
#! nix shell nixpkgs#nushell nixpkgs#sops --command nu

glob "**/*.enc.*" --exclude ["**/.git/**"]
| par-each { |f|
  ^sops --decrypt $f | save --force ($f | str replace ".enc." ".")
}
| ignore
