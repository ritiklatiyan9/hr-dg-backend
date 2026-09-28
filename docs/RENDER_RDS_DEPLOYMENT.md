# Render backend + existing RDS PostgreSQL

Use the existing Mumbai PostgreSQL 18.3 instance `database-1` at
`database-1.c3a6e2caw01a.ap-south-1.rds.amazonaws.com:5432`. Render hosts the
API/bundled HR panel and a separate background worker. Render Key Value provides
queues/rate limiting; private AWS S3 holds uploaded files. No laptop service is
a runtime dependency. The existing `infra/render.yaml` is the deployment Blueprint.
Its `-staging` names are retained; rename consistently before production setup.
Review the account, service names and paid plans before applying it.

## Connect RDS

For a direct Render connection, in AWS select **RDS → Databases → database-1 →
Modify → Connectivity → Publicly accessible → Yes**. Confirm the DB subnet
group's route tables provide internet connectivity. Open **Connectivity & security
→ VPC security groups → Inbound rules** and allow PostgreSQL TCP 5432 from:

- The operator's current public IP `/32` for setup; remove it after migration.
- All outbound ranges shown in Render for both API and worker.

Do not allow `0.0.0.0/0` or `::/0`. If RDS must remain private, arrange a private
network connection first. Keep `rds.force_ssl=1`. The console's “Internet access
gateway” label alone does not establish public accessibility.
References: [AWS public/private access](https://docs.aws.amazon.com/AmazonRDS/latest/gettingstartedguide/security-public-private.html),
[AWS troubleshooting](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ConnectToPostgreSQLInstance.Troubleshooting.html),
[Render outbound IP ranges](https://render.com/docs/outbound-ip-addresses).

Save the master password as `AWS_RDS_ADMIN_PASSWORD` in the ignored **`.env.aws`**
file. Initial database/user are both `postgres`; the app uses `defence_garden_hr`.
Never upload the complete `.env.aws` file to Render.

```sh
npm ci
npm run aws:rds:ca
npm run aws:db:check
```

The last command is read-only and checks TLS and PostGIS availability. A timeout
occurs before password authentication. TLS verifies the RDS hostname using the
official regional CA; do not disable certificate verification.

## Copy existing records

Use a maintenance window. Stop the source API and worker, prevent writes/uploads,
and keep Render services stopped. Leave the source database/storage available for
reading. Never seed, test against or clean the existing HR data.

The operator needs PostgreSQL 18 client tools (`pg_dump`, `pg_restore`, `psql`).
This Mac has them at `/opt/homebrew/opt/libpq/bin`; `PG_BIN` selects the directory.
Source configuration defaults to `.env`; another source can be selected with
`--source-env=/private/path/source.env` (must include `MIGRATION_DATABASE_URL` and
the original `ENCRYPTION_KEY`).

```sh
# Read-only export. This flag acknowledges that writers have actually stopped.
PG_BIN=/opt/homebrew/opt/libpq/bin npm run aws:copy:backup -- --writers-stopped

# Creates restricted roles, dedicated database and required extensions on RDS.
# Refuses an existing application schema; no application migrations or seed.
npm run aws:db:prepare-copy

# ENCRYPTION_KEY in .env.aws must equal the original source key.
PG_BIN=/opt/homebrew/opt/libpq/bin npm run aws:copy:restore -- --target=defence_garden_hr --writers-stopped
PG_BIN=/opt/homebrew/opt/libpq/bin npm run aws:copy:verify -- --target=defence_garden_hr
```

Backups use `.local/aws-rds/copy/` (0700 directory, 0600 files), refusing overwrite.
Use `--archive=.local/aws-rds/copy-YYYYMMDD` on all commands for another snapshot.
The two archives contain `app`, `auth` and the migration ledger from one exported
snapshot. RDS supplies `postgis`, `pgcrypto` and `btree_gist`; extension-owned data
and unrelated schemas are excluded. This app does not define custom SRIDs.
`source-key.env` preserves the encryption key privately. This session also copied
the original `.env` key into `.env.aws`; never regenerate it during migration.

Restore applies both archives in one transaction, retaining grants, triggers,
RLS/policies and assigning ownership to the migration account. It refuses to drop,
clean or merge an existing HR schema. Verification checks archive hashes, all
table counts, RLS flags/policy counts, ownership, authentication-role isolation,
runtime logins and the encryption key. Counts are not row-by-row data checksums;
complete the functional acceptance below. Treat archives/keys as production secrets.

Do not run `aws:db:provision` before copying: that initializes a fresh application
schema and intentionally prevents restore. If the source is behind the current
code, apply reviewed pending migrations **after** restore/verification:

```sh
node --import tsx --env-file=.local/aws-rds/migration.env packages/db/src/migrate.ts
```

Runtime services never receive migration credentials or run migrations at startup.

## Copy uploaded files

Use a dedicated S3 bucket with Block Public Access, default encryption and
versioning enabled. Set target `S3_ENDPOINT`, `S3_REGION`, `S3_BUCKET`,
`S3_ACCESS_KEY`, `S3_SECRET_KEY` in `.env.aws`. Migration credentials need
ListBucket/GetObject/PutObject for that bucket. Runtime credentials also need
DeleteObject for authorized retention jobs. Do not use an account root access key.
Use the bucket's actual AWS Region for both `S3_REGION` and its regional HTTPS
`S3_ENDPOINT`; it may differ from the Mumbai RDS region. The Render Blueprint
requires those values for both services rather than assuming Mumbai.

```sh
npm run aws:copy:files
npm run aws:copy:files -- --copy --writers-stopped
npm run aws:copy:files
```

Without `--copy` this only checks/inventories objects; missing objects report
INCOMPLETE. The copy preserves keys/content metadata, does not overwrite or delete
destination keys, and compares source/destination bytes with SHA-256. Only counts
are logged. Historical versions, bucket policies and lifecycle rules are separate.

Drain old worker queues before freezing writes. Redis rate limits can reset, but
do not discard undelivered jobs. DB outbox records are copied; do not blindly reset
published events to replay them. Keep source data/files unchanged until cutover.

## Render settings

### Free web preview while S3 is deferred

A standalone Free Render Web Service can build the repo with Dockerfile Path
`infra/Dockerfile`, an empty Root Directory and Docker build context `.`.
The web service still requires its restricted RDS role URLs, verified TLS CA,
HTTPS `WEB_ORIGIN` and a remote `REDIS_URL`. When S3 credentials and the file
copy are intentionally deferred, set `FILE_STORAGE_DISABLED=true` on the API.
This explicitly permits blank S3 settings at API startup and makes file intents,
uploads and downloads return `STORAGE_UNAVAILABLE` (HTTP 503). Remove this flag
and configure S3 before using attachments. The worker never accepts this flag.

This mode is only a preview of the web/API with the existing RDS data. A Free
web service sleeps when idle, does not run the separate background worker, and
cannot send SMTP on standard SMTP ports. Mail delivery, outbox processing and
timed jobs remain unavailable; do not use this mode as a complete HR cutover.

Git is initialized at this workspace root because Docker needs `apps`,
`packages`, `scripts`, and the root npm lockfile together. Do not initialize a
separate repository inside `apps/api`. The first commit should use a **private**
remote unless the operator explicitly approves a public repository. This
operator chose the public `ritiklatiyan9/hr-dg-backend` repository. `.gitignore`
excludes `.env`, `.env.aws`, `.env.test`, `.local`, archives,
keys and local review screenshots. Before pushing, review `git status --short`
and run `node scripts/check-release.mjs`; never push data archives or credentials.
The internal `docs/PROGRESS.md` handoff log stays on this computer because it
contains operational and employee references; it is excluded from the public
Git repository.

This project is already pushed to the operator's GitHub repository on `main`.
For a new remote in another environment, create an empty repository in your
Git provider (without a generated README or `.gitignore`), then run from the
project root:

```sh
git remote add origin <REPOSITORY_URL>
git push -u origin main
```

In Render, connect GitHub and choose **New → Blueprint**, select
`ritiklatiyan9/hr-dg-backend` and `main`, and set **Blueprint Path** to
`infra/render.yaml`. Render defaults to a root-level `render.yaml` if no custom
path is supplied. Review the three resources and their paid plans before
selecting **Deploy Blueprint**. Configure Blueprint Auto Sync to **No** before
future pushes if each infrastructure sync must be reviewed. The per-service
`autoDeployTrigger: off` only controls service code deploys.

The Blueprint creates an API web service, a separate worker, and Key Value;
it does not create PostgreSQL because the existing AWS RDS database is used.
Use `infra/render.yaml`, or these manual settings:

| Resource          | Configuration                                                       |
| ----------------- | ------------------------------------------------------------------- |
| Web Service       | Docker; repo root; Dockerfile `./infra/Dockerfile`                  |
| Web start         | Default image command; API serves built HR panel on the same origin |
| Health path       | `/health/ready`                                                     |
| Background Worker | Same Dockerfile; `node dist/apps/worker/src/index.js`               |
| Key Value         | Same region; internal access; `noeviction`; persistent paid plan    |
| Deploys           | Manual until cutover verification                                   |

Set `.env.aws` `WEB_ORIGIN` to the final Render HTTPS origin (no trailing slash),
`REDIS_URL` to Key Value's internal URL and complete the cloud S3/SMTP settings.
SMTP uses port 465 + `SMTP_SECURE=true` or 587 + `false` (STARTTLS required).

```sh
npm run aws:env:render:cloud
```

Import `.local/aws-rds/render/api.env` into the web service and
`.local/aws-rds/render/worker.env` into the worker. The renderer validates cloud
dependencies and writes role-separated files without the master password.
On **both** services add a Render **Secret File `rds-ca.pem`**, with the contents
of `.local/aws-rds/ap-south-1-bundle.pem`. URLs use `/etc/secrets/rds-ca.pem`, not
a Mac path. The API uses `hr_runtime`/`hr_auth`; worker uses `hr_worker`.
`DEPLOYMENT_TARGET=render-rds` makes startup reject local dependencies, unsafe TLS,
wrong role URLs, missing storage/mail configuration and owner credentials.

Optional: server-only OpenRouter settings; Firebase secret file
`/etc/secrets/firebase.json` with worker `FCM_SERVICE_ACCOUNT_FILE` set to that path.
Real push needs Firebase configuration. PDFs stay quarantined without a reachable
malware scanner; no local ClamAV address is assumed.
References: [Render Blueprint](https://render.com/docs/blueprint-spec),
[Render secrets](https://render.com/docs/configure-environment-variables),
[PostgreSQL restore](https://www.postgresql.org/docs/18/app-pgrestore.html).

## Cutover and rollback

Before employee traffic: check DB/object verification, migration checksums, health,
existing login/MFA, organization/site isolation, directory, attendance/map, private
downloads and worker delivery using an authorized operator. Never run synthetic
integration tests against RDS or real HR records. Rebuild mobile using the final
HTTPS `API_URL`; existing localhost binaries will not switch automatically.

Enable cloud API/worker only after acceptance, retain the source read-only, and
take an RDS snapshot. Before cloud writes, rollback may use the unchanged source.
After cloud writes, freeze and reconcile/export new records and objects before
switching back. Automated backups, restore drills and the business/mobile release
gates in `RELEASE_READINESS.md` remain required.
