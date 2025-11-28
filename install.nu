#!/usr/bin/env nix
#! nix shell nixpkgs#nushell --command nu

^sops --decrypt "apps/sonarr/overlays/nishir/sonarr/.enc.env" | save --force "apps/sonarr/overlays/nishir/sonarr/.env"
^sops --decrypt "apps/sonarr/overlays/nishir/sonarr/config.enc.xml" | save --force "apps/sonarr/overlays/nishir/sonarr/config.xml"

^sops --decrypt "apps/radarr/overlays/nishir/radarr/.enc.env" | save --force "apps/radarr/overlays/nishir/radarr/.env"
^sops --decrypt "apps/radarr/overlays/nishir/radarr/config.enc.xml" | save --force "apps/radarr/overlays/nishir/radarr/config.xml"

^sops --decrypt "apps/lidarr/overlays/nishir/lidarr/.enc.env" | save --force "apps/lidarr/overlays/nishir/lidarr/.env"
^sops --decrypt "apps/lidarr/overlays/nishir/lidarr/config.enc.xml" | save --force "apps/lidarr/overlays/nishir/lidarr/config.xml"

^sops --decrypt "apps/whisparr/overlays/nishir/whisparr/.enc.env" | save --force "apps/whisparr/overlays/nishir/whisparr/.env"
^sops --decrypt "apps/whisparr/overlays/nishir/whisparr/config.enc.xml" | save --force "apps/whisparr/overlays/nishir/whisparr/config.xml"

^sops --decrypt "apps/jellyfin/overlays/nishir/jellyfin/.enc.env" | save --force "apps/jellyfin/overlays/nishir/jellyfin/.env"
^sops --decrypt "apps/jellyfin/overlays/nishir/metatube/.enc.env" | save --force "apps/jellyfin/overlays/nishir/metatube/.env"

^sops --decrypt "apps/prowlarr/overlays/nishir/prowlarr/.enc.env" | save --force "apps/prowlarr/overlays/nishir/prowlarr/.env"

^sops --decrypt "apps/vaultwarden/overlays/nishir/vaultwarden/.enc.env" | save --force "apps/vaultwarden/overlays/nishir/vaultwarden/.env"

^sops --decrypt "apps/ftp/overlays/nishir/ftp/.enc.env" | save --force "apps/ftp/overlays/nishir/ftp/.env"

^sops --decrypt "apps/webdav/overlays/nishir/webdav/.enc.env" | save --force "apps/webdav/overlays/nishir/webdav/.env"

^sops --decrypt "apps/kratos/overlays/nishir-tailnet/kratos/.enc.env" | save --force "apps/kratos/overlays/nishir-tailnet/kratos/.env"
^sops --decrypt "apps/kratos/overlays/nishir-tailnet/kratos-postgres/.enc.env" | save --force "apps/kratos/overlays/nishir-tailnet/kratos-postgres/.env"

^sops --decrypt "apps/matrix/overlays/nishir-tailnet/synapse/homeserver.enc.yaml" | save --force "apps/matrix/overlays/nishir-tailnet/synapse/homeserver.yaml"

^sops --decrypt "apps/matrix/overlays/nishir-tailnet/mautrix-discord/config.enc.yaml" | save --force "apps/matrix/overlays/nishir-tailnet/mautrix-discord/config.yaml"
^sops --decrypt "apps/matrix/overlays/nishir-tailnet/mautrix-discord/registration.enc.yaml" | save --force "apps/matrix/overlays/nishir-tailnet/mautrix-discord/registration.yaml"

^sops --decrypt "apps/matrix/overlays/nishir-tailnet/mautrix-signal/config.enc.yaml" | save --force "apps/matrix/overlays/nishir-tailnet/mautrix-signal/config.yaml"
^sops --decrypt "apps/matrix/overlays/nishir-tailnet/mautrix-signal/registration.enc.yaml" | save --force "apps/matrix/overlays/nishir-tailnet/mautrix-signal/registration.yaml"

^sops --decrypt "apps/matrix/overlays/nishir-tailnet/mautrix-whatsapp/config.enc.yaml" | save --force "apps/matrix/overlays/nishir-tailnet/mautrix-whatsapp/config.yaml"
^sops --decrypt "apps/matrix/overlays/nishir-tailnet/mautrix-whatsapp/registration.enc.yaml" | save --force "apps/matrix/overlays/nishir-tailnet/mautrix-whatsapp/registration.yaml"

^sops --decrypt "apps/matrix/overlays/nishir-tailnet/mautrix-slack/config.enc.yaml" | save --force "apps/matrix/overlays/nishir-tailnet/mautrix-slack/config.yaml"
^sops --decrypt "apps/matrix/overlays/nishir-tailnet/mautrix-slack/registration.enc.yaml" | save --force "apps/matrix/overlays/nishir-tailnet/mautrix-slack/registration.yaml"

^sops --decrypt "apps/matrix/overlays/nishir-tailnet/mautrix-meta/config.enc.yaml" | save --force "apps/matrix/overlays/nishir-tailnet/mautrix-meta/config.yaml"
^sops --decrypt "apps/matrix/overlays/nishir-tailnet/mautrix-meta/registration.enc.yaml" | save --force "apps/matrix/overlays/nishir-tailnet/mautrix-meta/registration.yaml"

^sops --decrypt "apps/matrix/overlays/nishir-tailnet/mautrix-googlechat/config.enc.yaml" | save --force "apps/matrix/overlays/nishir-tailnet/mautrix-googlechat/config.yaml"
^sops --decrypt "apps/matrix/overlays/nishir-tailnet/mautrix-googlechat/registration.enc.yaml" | save --force "apps/matrix/overlays/nishir-tailnet/mautrix-googlechat/registration.yaml"

^sops --decrypt "clusters/nishir/components/tailscale/operator-oauth/.enc.env" | save --force "clusters/nishir/components/tailscale/operator-oauth/.env"
^sops --decrypt "clusters/nishir/components/nishir/hetzner/.enc.env" | save --force "clusters/nishir/components/nishir/hetzner/.env"
^sops --decrypt "clusters/nishir/components/longhorn/longhorn-hetzner-backups/.enc.env" | save --force "clusters/nishir/components/longhorn/longhorn-hetzner-backups/.env"

^sops --decrypt "clusters/telsha/components/tailscale/operator-oauth/.enc.env" | save --force "clusters/telsha/components/tailscale/operator-oauth/.env"

^sops --decrypt "apps/copyparty/overlays/nishir-tailnet/copyparty/config.enc.conf" | save --force "apps/copyparty/overlays/nishir-tailnet/copyparty/config.conf"
