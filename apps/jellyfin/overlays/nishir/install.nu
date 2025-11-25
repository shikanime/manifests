#!/usr/bin/env nix
#! nix shell nixpkgs#nushell --command nu

^sops --decrypt $"($env.FILE_PWD)/jellyfin/.enc.env" | save --force $"($env.FILE_PWD)/jellyfin/.env"
^sops --decrypt $"($env.FILE_PWD)/metatube/.enc.env" | save --force $"($env.FILE_PWD)/metatube/.env"
