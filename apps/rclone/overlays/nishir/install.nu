#!/usr/bin/env nix
#! nix shell nixpkgs#nushell --command nu

^sops --decrypt $"($env.FILE_PWD)/rclone-ftp/.enc.env" | save --force $"($env.FILE_PWD)/rclone-ftp/.env"
^sops --decrypt $"($env.FILE_PWD)/rclone-htpasswd/.enc.env" | save --force $"($env.FILE_PWD)/rclone-htpasswd/.env"
