#!/usr/bin/env nix
#! nix shell nixpkgs#nushell --command nu

^sops --decrypt $"($env.FILE_PWD)/whisparr/.enc.env" | save --force $"($env.FILE_PWD)/whisparr/.env"
^sops --decrypt $"($env.FILE_PWD)/whisparr/config.enc.xml" | save --force $"($env.FILE_PWD)/whisparr/config.xml"
