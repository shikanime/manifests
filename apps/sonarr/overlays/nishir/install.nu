#!/usr/bin/env nix
#! nix develop --impure --command nu

^sops --decrypt $"($env.FILE_PWD)/sonarr/.enc.env" | save --force $"($env.FILE_PWD)/sonarr/.env"
