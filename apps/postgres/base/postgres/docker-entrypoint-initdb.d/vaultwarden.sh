#!/bin/bash

set -e

postgres_vaultwarden_db=${POSTGRES_VAULTWARDEN_DB:-vaultwarden}
postgres_vaultwarden_user=${POSTGRES_VAULTWARDEN_USER:-vaultwarden}
postgres_vaultwarden_password=$POSTGRES_VAULTWARDEN_PASSWORD

psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER:-postgres}" --dbname "${POSTGRES_DB:-postgres}" <<-EOSQL
    CREATE USER "$postgres_vaultwarden_user" WITH PASSWORD "$postgres_vaultwarden_password";
    CREATE DATABASE "$postgres_vaultwarden_db" OWNER "$postgres_vaultwarden_user";
EOSQL
