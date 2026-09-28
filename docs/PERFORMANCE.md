# Performance evidence

2026-09-22. These are local measurements, not a hosting capacity guarantee.
Raw reports and execution plans: [evidence/phase6](evidence/phase6/).

## Workload and method

`PERF_LABEL=final node --env-file=.env.test --import tsx scripts/phase6-workload.ts`
creates and drops a uniquely named local PostGIS database. It refuses production
or non-loopback control URLs. Apple M5, 10 logical cores, 16 GiB, macOS arm64,
Node 24.16.0; PostGIS PostgreSQL 17 in Docker linux/amd64 emulation. Local loopback,
no cloud region or internet/TLS included. Warm database after import/ANALYZE.
Service timings include authorization and database transactions, exclude login,
media upload, external providers and browser rendering. Other development processes
may run on this workstation; this is not an isolated production-capacity laboratory.

500 employees, two sites; 2025-09-01–2026-08-31. Synthetic weekday roster/duty,
129,717 sessions, 389,151 raw events/observations, 518,868 segments, 116,298 DWRs,
5,964 tasks and 497 expense records. The report month is August 2026. Data is
explicitly synthetic and does not assert company rules or verified achievements.

| Application operation           | Runs / concurrency | Final sample p95 ms | Result against initial target               |
| ------------------------------- | ------------------ | ------------------: | ------------------------------------------- |
| Employee directory, 20 rows     | 12 / 2             |                 224 | PASS <=250                                  |
| Task backlog                    | 12 / 2             |                 157 | PASS <=250                                  |
| Attendance month                | 2 / 1              |                 313 | FAIL ordinary-read target                   |
| DWR compliance                  | 2 / 1              |                 184 | PASS in this small sample                   |
| HR expense list, up to 100 rows | 6 / 2              |                 521 | FAIL ordinary-read target                   |
| Complete useful site dashboard  | 2 / 1              |                 769 | PASS ~1,500 ms in this small sample         |
| Small task write                | 12 / 2             |                  18 | PASS <=400                                  |
| Protected employee export       | 4 / 1              |                 425 | Measured separately; no export SLA asserted |
| Location event ingestion        | 12 / 1             |                  35 | PASS <=400                                  |

Final workload errors: zero. Two observations are insufficient for a statistically
stable production p95; here p95 means the nearest-rank sample maximum. A sustained,
networked shift-end load test is still required. Baseline attendance/dashboard each
timed out twice at the 8-second database statement limit. Baseline task p95 was
1,374 ms; DWR 3,508 ms. Adding window indexes alone did not fix attendance. Narrow
authorized-cohort aggregates removed repeated per-sample policy evaluation; the
approval creation-date partial index reduced dashboard ~4,585 ms to ~769 ms.
The final aggregate EXPLAIN ANALYZE measured 136.855 ms; inner candidate-window
index/buffer evidence is recorded separately under owner inspection, not mislabeled
as a runtime RLS query. No partitioning or persistent rollups were introduced.

## Remaining measurement gates

- Real Groq/OpenRouter quality, quotas and speech stop-to-preview p95: NOT RUN.
  Missing approved model/provider settings and credentials. Mocked 429/timeout/
  malformed-output tests are functional evidence only. Never infer quota from free tier.
- Shift-end speech burst: NOT RUN against providers. Before enabling: record account
  RPM/audio/token/concurrency quotas, test synthetic 10–15-second clips at measured
  arrival rate, include 429s and Retry-After, count failures and queue waits, and report
  provider-stage/end-to-end p95 separately. Do not send employee recordings for load.
- Physical Android: Samsung SM-G781B, Android 13/API 33, security patch 2025-10-01.
  The native vault case passed within the initial otherwise-failed profile run.
  Standalone profile rerun stalled; debug rerun did not complete. Thus final native
  encryption acceptance remains FAIL/incomplete; see android-profile.log,
  android-vault.log and android-vault-debug.log. No debug/emulator timing is a release result.
- Cold start <=2.5 seconds, sustained 60 fps, memory and extended field-duty battery:
  NOT RUN successfully. Device is available, but concurrent mobile redesign prevented
  a stable final profile build during this audit. No continuous-tracking claim.
- iOS: NOT RUN; xcodebuild reports only Command Line Tools, no configured Xcode.
- Payroll list (2026-09-25, local synthetic 2,400 results): 612 queries/~930 ms →
  10 queries/~175 ms per 50–100-row keyset page; 100-employee run 1.4 s; 100-item
  bulk payment 0.54 s. Not a staging or production measurement.
- 100-record HR pagination, sustained payroll batches, cross-region latency,
  storage/scanner throughput and large simultaneous site dashboards: incomplete.

Before pilot, repeat on staging and named low/mid-range physical phones with release
configuration, measured network, thermal/battery state and a stable build hash.
Record an extended authorized field session with screen-off intervals, foreground
notification, permission withdrawal, force-stop, gaps and actual battery change.
