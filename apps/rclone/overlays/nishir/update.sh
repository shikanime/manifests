#!/usr/bin/env nix
#! nix develop --impure --command bash

set -o errexit
set -o nounset
set -o pipefail

# Get current password if it exists
CURRENT_PASSWORD=$(grep -m1 '^password=' "$(dirname "$0")"/rclone-ftp/.env 2>/dev/null | cut -d= -f2 || echo "")
# Generate new password only if current password is empty
if [ -z "$CURRENT_PASSWORD" ]; then
  PASSWORD=$(openssl rand -base64 14)
else
  PASSWORD="$CURRENT_PASSWORD"
fi

# Generate bcrypt hash for htpasswd (using cost 10)
BCRYPT_HASH=$(htpasswd -bnBC 10 "" "$PASSWORD" | tr -d ':')

# Update password in secrets
sed -i \
  -e "s|^password=.*|password=$PASSWORD|" \
  "$(dirname "$0")"/rclone-ftp/.env

# Update rclone-htpasswd/.env
sed -i \
  -e "s|^htpasswd=.*|htpasswd=rclone:$BCRYPT_HASH|" \
  "$(dirname "$0")"/rclone-htpasswd/.env

sops \
  --encrypt \
  "$(dirname "$0")"/rclone-ftp/.env > \
  "$(dirname "$0")"/rclone-ftp/.enc.env

sops \
  --encrypt \
  "$(dirname "$0")"/rclone-htpasswd/.env > \
  "$(dirname "$0")"/rclone-htpasswd/.enc.env
