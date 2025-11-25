#!/usr/bin/env nix
#! nix shell nixpkgs#nushell --command nu

^sops --decrypt $"($env.FILE_PWD)/sonarr/.enc.env" | save --force $"($env.FILE_PWD)/sonarr/.env"
^sops --decrypt $"($env.FILE_PWD)/sonarr/config.enc.xml" | save --force $"($env.FILE_PWD)/sonarr/config.xml"
