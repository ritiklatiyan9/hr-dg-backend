# AWS RDS PostgreSQL setup

This repository has a prepared configuration for the Mumbai RDS instance shown
in the operator-provided console capture. The endpoint is currently set to
`database-1.c3a6e2caw01a.ap-south-1.rds.amazonaws.com`, port `5432`,
with the administrative database/user `postgres`. Verify the endpoint text in
the AWS console before first use.

For the active deployment and data copy, follow
[Render + RDS deployment](RENDER_RDS_DEPLOYMENT.md). Use `aws:db:prepare-copy`
before restore; the provisioning command below initializes a new application.

The application keeps its existing database security model. The RDS master user
is used only for initial provisioning and reviewed migrations. The API connects
as `hr_runtime` and `hr_auth`; the worker connects as `hr_worker`. Each role has
a separate generated password, owns no application objects, and cannot bypass
row-level security.

## One-time local preparation

`npm run aws:env:init` has already created the ignored `.env.aws` file with mode
`0600` and generated passwords for the three
application roles. Put the RDS master password in
`AWS_RDS_ADMIN_PASSWORD` in that local file. Do not paste it into chat or commit
the file. Also replace `WEB_ORIGIN` before starting a production API.

Copying existing records requires the original source `ENCRYPTION_KEY`; a new
key cannot decrypt existing fields. This session preserved the `.env` key in
`.env.aws`. Do not regenerate it during migration.

The official regional RDS CA bundle is stored at the ignored path
`.local/aws-rds/ap-south-1-bundle.pem`. Refresh it when AWS changes its trust
bundle with:

```sh
npm run aws:rds:ca
```

The connection uses `verify-full`, which checks both the certificate chain and
the RDS endpoint hostname. Do not change it to `require` or disable certificate
verification.

Public accessibility alone does not open the instance. In the RDS security
group, allow inbound TCP `5432` only from the current application host's public
IP (`/32`), or run the application inside the VPC. Do not allow `0.0.0.0/0`.
For production, set `rds.force_ssl=1` in the attached PostgreSQL parameter group.

## Read-only connection check

After saving the RDS master password, run:

```sh
npm run aws:db:check
```

This opens a read-only transaction and reports the database/user, PostgreSQL
version, negotiated TLS version/cipher, `rds.force_ssl`, PostGIS availability,
and whether the master role can create the dedicated database and roles. It does
not create or modify anything and never prints the password or connection URL.

## Explicit provisioning

Review the check result, take an RDS snapshot if the instance already contains
important data, then run the mutating step deliberately:

```sh
npm run aws:db:provision
```

This creates the dedicated `defence_garden_hr` database if absent, creates the
three restricted application roles if absent, applies the repository's additive
checksum-guarded migrations, validates every runtime role, and renders isolated
mode-`0600` environments under `.local/aws-rds/`. It does **not** run the seed,
write synthetic users, drop a database, or alter an existing application's role
password unless `AWS_RDS_ROTATE_APP_ROLE_PASSWORDS=true` was explicitly set.

If the database and roles were provisioned previously, `npm run aws:env:render`
only regenerates the local process files. Start processes with:

```sh
npm run start:aws:api
npm run start:aws:worker
```

The API environment contains only the runtime and authentication database URLs.
The worker environment contains only the worker URL. The migration environment
contains the master URL and must never be supplied to either long-running
process. Complete private object storage, Redis, SMTP and HTTPS reverse-proxy
configuration before treating this as a production deployment.

No production seed command exists. Create the first organization and Super Admin
through a separately reviewed bootstrap procedure after the connection and
migrations pass.
