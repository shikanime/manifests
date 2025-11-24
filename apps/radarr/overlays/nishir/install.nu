#!/usr/bin/env nix
#! nix shell nixpkgs#nushell --command nu

^sops --decrypt $"($env.FILE_PWD)/radarr/.enc.env" | save --force $"($env.FILE_PWD)/radarr/.env"
