#!/usr/bin/env nix
#! nix develop --impure --command nu

^sops --decrypt $"($env.FILE_PWD)/radarr/.enc.env" | save --force $"($env.FILE_PWD)/radarr/.env"
