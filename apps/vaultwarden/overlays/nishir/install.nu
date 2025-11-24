#!/usr/bin/env nix
#! nix shell nixpkgs#nushell --command nu

^sops --decrypt $"($env.FILE_PWD)/vaultwarden/.enc.env" | save --force $"($env.FILE_PWD)/vaultwarden/.env"
