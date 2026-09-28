# HR panel performance evidence — 22 September 2026

## Confirmed root causes and changes

The original QueryClient was already singleton. Hash anchors did not reload the
browser. The real causes were zero query retention and freshness, a route-dependent
main key, unconditional broad invalidation after writes, eager module imports,
and an empty-site intermediate state. Auth/session checks were not removed.

- Default/scoped staleTime: 30 seconds; inactive memory retention: 5 minutes.
- Foundation reference freshness: 120 seconds. Permissions still poll/revalidate,
  and server requests independently authorize current access/version.
- Removed the route-dependent main key. The shell/header remain mounted.
- Site switching validates membership, aborts old reads, clears scoped queries,
  and changes directly to the new site. No previous-site placeholder data.
- ScopeBoundary generation checks still discard late responses. Permission events
  immediately hide content and advance a scope epoch before revalidation.
- Visibility changes remove sensitive content and revalidate on return.
- Existing broad mutation invalidation remains deliberately conservative; targeted
  dependency-aware invalidation is not claimed implemented.
- Removed duplicate bootstrap refetch on initial identity hydration.
- DWR summary and main view share a cache key. Foundation reference queries share
  a cache key. Employee search debounces by 250ms.
- Analytics, access, payroll, HR records, DWR, operations, dashboard and foundation
  pages are code-split. Hover/focus preloads analytics/access/payroll code only.
  No sensitive-record prefetch is performed.

## Bundle measurements

Vite production build, Node 24.16.0, local build output (uncompressed bytes):

| Item | Before | After measured snapshot |
| --- | ---: | ---: |
| Eager entry JS | 646,992 | 558,132 |
| CSS | 40,870 | 58,155 |
| Entry gzip | not recorded | 169,820 |
| Lazy foundation | included in entry | 66,372 |
| Shared table | included in entry | 65,638 |
| Lazy schemas | included in entry | 87,050 |

Entry decreases approximately 13.7%, but overall JS and first-directory dependency
transfer increase with Router/Radix/Command/RHF. This is not a total-transfer win.
Vite still warns about the >500 kB entry; the warning was not hidden. Source-map
attribution/CPU profiling and cold-network device lab measurements remain NOT RUN.

## Browser measurement envelope

Local Vite + local API/PostGIS, installed Chrome, synthetic seeded accounts, no
network throttling. `tests/browser/redesign.spec.ts` traverses all 25 sidebar routes
at 1366x768, 1440x900 and 1920x1080. It waits for active-route commit, two animation
frames and local skeleton completion. Timing includes Playwright interaction,
scroll-to-target and assertions; it is not React render duration or a production SLA.
Raw samples: `docs/evidence/hr-redesign/navigation.json`.

Measured snapshot: 25 transitions per size. Median/p95(ms): 1366 = 122/301;
1440 = 104/137; 1920 = 126/134. Later runs may update raw evidence. The requested
<100ms target is NOT established by these samples. Before-change route timing was
not recorded, so no numeric before/after latency claim is made.

The focused cache test verifies zero Employee query requests on a warm revisit,
then switches to River Green and back, asserting the previous site's employee
is absent. The permission-downgrade test narrows a real response at the browser
boundary; this validates frontend removal, while the 86 real-DB integration tests
validate backend authorization. Shell and topbar identity remain unchanged across
all tested normal routes. No browser reload is required for navigation.

## Regression found during this implementation

URL-controlled table pagination initially interacted with TanStack's automatic
page reset, repeatedly pushing URL state and making populated payroll pages
unresponsive. The failing browser run was interrupted (not counted as PASS).
`autoResetPageIndex: false`, bounded derived page indices and memoized sorting
removed the feedback loop. The focused persisted payroll journey then passed in
9.1s. A regression now covers sorting, Back navigation, bounded history writes,
leaving the table, and recovery from a synthetic 503 within the retained shell.

Static contrast evidence: `token-contrast.json`. Eight semantic foreground/background
pairs pass normal-text AA (minimum 4.59:1). This does not establish exhaustive
rendered contrast or screen-reader conformance.
