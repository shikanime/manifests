#!/bin/bash

set -e

postgres_gitea_db=${POSTGRES_GITEA_DB:-gitea}
postgres_gitea_user=${POSTGRES_GITEA_USER:-gitea}
postgres_gitea_password=$POSTGRES_GITEA_PASSWORD

psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER:-postgres}" --dbname "${POSTGRES_DB:-postgres}" <<-EOSQL
    CREATE USER "$postgres_gitea_user" WITH PASSWORD "$postgres_gitea_password";
    CREATE DATABASE "$postgres_gitea_db" OWNER "$postgres_gitea_user";
EOSQL
