#!/bin/sh
set -eu
# Variables passed through psql literals, never interpolated into SQL syntax.
psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER:-postgres}" --dbname "$POSTGRES_DB" \
 --set=runtime_password="$RUNTIME_DB_PASSWORD" --set=auth_password="$AUTH_DB_PASSWORD" --set=worker_password="$WORKER_DB_PASSWORD" <<'SQL'
CREATE ROLE hr_runtime LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS PASSWORD :'runtime_password';
CREATE ROLE hr_auth LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS PASSWORD :'auth_password';
CREATE ROLE hr_worker LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOBYPASSRLS PASSWORD :'worker_password';
CREATE DATABASE hr_test;
SQL
