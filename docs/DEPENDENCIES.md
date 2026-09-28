# Verified dependency baseline

Checked against official documentation and registry metadata on 2026-09-21.
Exact JS resolutions are locked in package-lock.json; Dart resolutions in
apps/employee-mobile/pubspec.lock. "Stable" does not mean every major is latest;
compatible supported majors are kept together and validated by compilation/tests.

| Component                 | Resolved/observed version                         | Compatibility evidence                                                                                                                                                                                          |
| ------------------------- | ------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Node                      | local 24.16.0; deployment Node 24 LTS             | [Official release schedule](https://github.com/nodejs/Release); Node 24 is active LTS                                                                                                                           |
| Fastify / Mercurius       | 5.12.5 / 16.10.0                                  | [Fastify v5 requirements](https://fastify.dev/docs/latest/Guides/Migration-Guide-V5/), [Mercurius manifest](https://github.com/mercurius-js/mercurius/blob/master/package.json) supports Fastify 5 / GraphQL 16 |
| GraphQL / TypeScript      | 16.14.2 / 5.9.3                                   | Schema codegen and both TS builds verified                                                                                                                                                                      |
| PostgreSQL / PostGIS      | official postgis/postgis:17-3.5; PG 17.5 observed | [PostGIS image](https://github.com/postgis/docker-postgis); [PostgreSQL RLS](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)                                                                      |
| pg / Drizzle              | 8.23.0 / 0.45.3                                   | [Drizzle node-postgres adapter](https://orm.drizzle.team/docs/get-started-postgresql)                                                                                                                           |
| React / Vite              | 19.3.0 / 7.3.6                                    | [Vite Node requirements](https://vite.dev/guide/); Node 24 satisfies requirements                                                                                                                               |
| Tailwind                  | 4.3.3                                             | [shadcn Vite integration](https://ui.shadcn.com/docs/installation/vite)                                                                                                                                         |
| TanStack Query / Table    | 5.103.2 / 8.21.3                                  | Locked and compiled in HR panel                                                                                                                                                                                 |
| BullMQ                    | 5.81.5                                            | [Connection requirements](https://docs.bullmq.io/guide/connections)                                                                                                                                             |
| Nodemailer                | 10.0.10                                           | [Official docs](https://nodemailer.com/); upgraded from initial 7.x after npm audit; final installation reported zero vulnerabilities                                                                           |
| Zod                       | 4.6.5                                             | API request validation compiled/tested                                                                                                                                                                          |
| Flutter / Dart            | 3.47.5 / 3.13.4                                   | [Flutter stable archive](https://docs.flutter.dev/install/archive), local SDK output                                                                                                                            |
| Riverpod / go_router      | 3.4.3 / 17.5.0                                    | [Riverpod package](https://pub.dev/packages/flutter_riverpod), [go_router](https://pub.dev/packages/go_router)                                                                                                  |
| graphql / graphql_codegen | 5.2.4 / 3.0.2                                     | [Client](https://pub.dev/packages/graphql), [generator](https://pub.dev/packages/graphql_codegen)                                                                                                               |
| Dio / secure storage      | 5.11.1 / 10.3.4                                   | [Dio](https://pub.dev/packages/dio), [secure storage](https://pub.dev/packages/flutter_secure_storage)                                                                                                          |
| Drift                     | 2.35.0                                            | [Official package](https://pub.dev/packages/drift)                                                                                                                                                              |
| SeaweedFS                 | 4.47                                              | [Official S3 quickstart](https://github.com/seaweedfs/seaweedfs), [release](https://github.com/seaweedfs/seaweedfs/releases/tag/4.47)                                                                           |

GraphQL's stable Dart client currently resolves alpha-labelled internal gql_exec
and gql_dedupe_link dependencies. The same compatible transport interfaces are
used directly; their exact versions are locked. No independently experimental
application framework was introduced.

MinIO's initially attempted old Docker image was unavailable. Its official
repository is archived and community binaries are no longer maintained, so local
S3 uses SeaweedFS instead. No paid storage account was provisioned.

Before production, refresh supported minor security patches (including the Node
and PostgreSQL local baseline), pin deployment image digests, review transitive
dependencies, and rerun the complete suite. These local image choices are not a
claim of production deployment readiness.

## Phase 2 additions

The existing Node/npm lockfile and authentication libraries are retained. Flutter
adds `flutter_localizations` and the dev-only `integration_test`/`flutter_driver`
SDK test infrastructure from the installed Flutter 3.47.5 SDK. Regenerated
GraphQL models compile with the existing locked Dart stack. No hosted service,
AI provider or new third-party authentication package was introduced.
