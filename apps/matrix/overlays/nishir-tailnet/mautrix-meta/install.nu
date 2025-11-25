#!/usr/bin/env nix
#! nix shell nixpkgs#nushell --command nu

^sops --decrypt $"($env.FILE_PWD)/config.enc.yaml" | save --force $"($env.FILE_PWD)/config.yaml"
^sops --decrypt $"($env.FILE_PWD)/registration.enc.yaml" | save --force $"($env.FILE_PWD)/registration.yaml"
