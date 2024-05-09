#!/bin/bash

set -e

postgres_metatube_db=${POSTGRES_METATUBE_DB:-metatube}
postgres_metatube_user=${POSTGRES_METATUBE_USER:-metatube}
postgres_metatube_password=$POSTGRES_METATUBE_PASSWORD

psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER:-postgres}" --dbname "${POSTGRES_DB:-postgres}" <<-EOSQL
    CREATE USER "$postgres_metatube_user" WITH PASSWORD "$postgres_metatube_password";
    CREATE DATABASE "$postgres_metatube_db" OWNER "$postgres_metatube_user";
EOSQL
