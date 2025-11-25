#!/usr/bin/env nix
#! nix shell nixpkgs#nushell --command nu

^sops --decrypt $"($env.FILE_PWD)/lidarr/.enc.env" | save --force $"($env.FILE_PWD)/lidarr/.env"
^sops --decrypt $"($env.FILE_PWD)/lidarr/config.enc.xml" | save --force $"($env.FILE_PWD)/lidarr/config.xml"
