#!/usr/bin/env nix
#! nix shell nixpkgs#nushell --command nu

^sops --decrypt $"($env.FILE_PWD)/homeserver.enc.yaml" | save --force $"($env.FILE_PWD)/homeserver.yaml"
