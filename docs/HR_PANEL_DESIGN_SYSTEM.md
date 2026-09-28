# HR panel design system

The authenticated web panel uses the existing React/Tailwind application and an
original restrained green / warm-neutral design. Implementation:
`apps/hr-web/src/design-system.css`, `ui.tsx`, `components/ui/button.tsx`,
`components/shared/data-table.tsx`, `components/shared/formatting.tsx`, and
`layouts/site-switcher.tsx`, shared FilterBar/Timeline, and `hooks/use-url-choice.ts`. Backend identity and authorization remain unchanged.

## Foundation

Semantic light/dark CSS variables cover background, foreground, card, popover,
primary, secondary, muted, accent, border, input, ring and status colors. Existing
legacy `ink/surface/line` names alias semantic tokens. Muted surface and muted text
are distinct. Font stack uses Inter when available, then system sans; no remote
font request. Titles 26px, section titles 18px, body/table 13–14px, metadata 12px.
Buttons use 6px radius, panels 8px, overlays 10px. Numeric data uses tabular figures.

The shell is 248px expanded, 72px collapsed; only navigation scrolls. Collapse is a
180ms CSS transition, disabled by reduced-motion preference. Below 1000px navigation
uses a focus-trapped Sheet. UI-only sidebar preference is persisted; no HR records
are stored in localStorage. Site selector uses Radix Popover + cmdk search, current
selection checkmark, authorized sites only. Mobile navigation has the same guards.

## Shared primitives and coverage

- Button: shadcn-style Radix Slot + CVA variants; existing exports preserved.
- Dialog/Sheet: Radix Dialog Root/Portal/Overlay/Content/Title/Close. Shared adapter
  preserves every existing consumer, modal focus trap, Escape and focus restoration.
- Tabs: Radix Tabs with keyboard navigation. Existing workflows retain their tab IDs.
- Site combobox: Radix Popover + Command/cmdk. Keyboard search and selection.
- Column menu: Radix DropdownMenu checkbox items; no inaccessible custom menu.
- Heading (PageHeader): shared typography, description and primary/secondary actions.
- Badge (StatusBadge): semantic success/warning/danger/info/neutral; statuses remain
  readable text. Existing explicit green/red tones remain compatible.
- DataTable: TanStack Table, stable record IDs, sorting, column visibility, compact
  headers and bounded 20-row pages. Employees retain real server cursors; other
  modules explicitly page only the bounded records already returned by the server.
- FoundationForm: React Hook Form + Zod validation, two-column desktop layout,
  inline error messages, pending action and the existing server validation.
- Skeleton, ErrorState, Empty, Notice, OnlineStatus: one shared feedback language.
- Money formatting uses exact integer-paise conversion and Indian grouping; no
  floating-point calculation was introduced.
- Sonner confirms employee/foundation/HR/payroll mutations after server acknowledgment; inline validation and decision outcomes remain.
- FilterBar uses removable chips; non-sensitive status/view/page/sort choices use URL state. Search text stays in memory.
- Timeline is shared by HR record history and audit. Employee details separate overview from employment/history.
- Tasks use the shared table plus a Sheet, with original status/comment/attachment commands. Leave and inbox use the same table.
- Collapsed sidebar labels use Radix tooltips on hover and keyboard focus.

No giant UI framework, decorative chart, new authorization layer or database schema
was introduced. The dashboard consumes existing deterministic analytics, with each
metric's denominator and limitations; unknown evidence remains unknown.

## shadcn/ui foundation (2026-09-25)

`src/app.css` loads Tailwind first and the legacy panel CSS into a `legacy` cascade
layer (above preflight, below utilities), and maps the existing semantic tokens to
Tailwind colours, so canonical shadcn components compose without restyling existing
screens. `components/ui/` now has Card, Badge, Input, Textarea, Label, NativeSelect,
Switch, Separator, Skeleton, Avatar, Alert, Table, ScrollArea, Tabs, Dialog, Sheet,
DropdownMenu, Tooltip and Command (Radix/cmdk already installed, no new
dependencies); `@/` resolves to `src/` as `components.json` expects. Button keeps
its legacy variants and adds `size` (sm/icon) plus `secondary`/`destructive`. The
DWR module is built entirely from these components.

## Usage rules

Use one heading, a focused toolbar and the table/detail content. Keep sensitive
mutations server-confirmed and preserve reasons/version checks. Detail inspections
use Sheets; complex workflows may remain full routes. Do not hide a feature to
make the page smaller. Downloads retain authenticated endpoints and fresh server
checks. All Sites remains a separate read-only reporting route.

## Explicit coverage limits

The app retains legacy domain-specific input groups and some native tables inside
financial/evidence details. It is not an unmodified shadcn CLI export. Bulk actions
are not synthesized where the backend has no authorized bulk operation. A chart
library was not added: the existing analytics contract contains aggregates, not a
7/30-day time series suitable for the requested attendance chart. These constraints
are tracked in HR_PANEL_REDESIGN_PROGRESS.md.
