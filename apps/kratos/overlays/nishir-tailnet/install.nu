#!/usr/bin/env nix
#! nix develop --impure --command nu

^sops --decrypt $"($env.FILE_PWD)/kratos/.enc.env" | save --force $"($env.FILE_PWD)/kratos/.env"
^sops --decrypt $"($env.FILE_PWD)/kratos-postgres/.enc.env" | save --force $"($env.FILE_PWD)/kratos-postgres/.env"
