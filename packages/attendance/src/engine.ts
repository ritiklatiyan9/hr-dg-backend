/** Versioned evidence projection; deliberately contains no payroll/absence decision. */
export const ENGINE_VERSION = 1;
export type SegmentKind = "office" | "field" | "break" | "outside" | "unknown";
export type DutyEvent = {
  id: string;
  kind: string;
  effectiveAt: string | null;
  status: string;
  observation?: "inside" | "outside" | "unknown";
  visitId?: string | null;
};
export type Segment = {
  startsAt: string;
  endsAt: string;
  kind: SegmentKind;
  sourceIds: string[];
  assumption: string;
  visitId: string | null;
};
export type Adjustment = {
  id: string;
  startsAt: string;
  endsAt: string;
  kind: SegmentKind;
};
export function projectDuty(
  events: DutyEvent[],
  now: string,
  policy: { gapSeconds: number; maxSessionHours: number },
  adjustments: Adjustment[] = [],
) {
  const accepted = events
    .filter((e) => e.status === "accepted" && e.effectiveAt)
    .sort((a, b) => Date.parse(a.effectiveAt!) - Date.parse(b.effectiveAt!));
  const first = accepted.find((e) => e.kind === "IN");
  if (!first)
    return {
      segments: [] as Segment[],
      gaps: ["No verified entry"],
      open: false,
      version: ENGINE_VERSION,
    };
  const start = Date.parse(first.effectiveAt!),
    out = accepted.find((e) => e.kind === "OUT");
  const end = Math.max(
    start,
    Math.min(
      Date.parse(out?.effectiveAt ?? now),
      start + policy.maxSessionHours * 3600000,
    ),
  );
  const bounds = new Set([start, end]);
  for (const e of accepted) {
    const t = Date.parse(e.effectiveAt!);
    if (t >= start && t <= end) {
      bounds.add(t);
      bounds.add(Math.min(end, t + policy.gapSeconds * 1000));
    }
  }
  for (const a of adjustments) {
    bounds.add(Math.max(start, Math.min(end, Date.parse(a.startsAt))));
    bounds.add(Math.max(start, Math.min(end, Date.parse(a.endsAt))));
  }
  const ordered = [...bounds].sort((a, b) => a - b),
    segments: Segment[] = [];
  for (let i = 0; i < ordered.length - 1; i++) {
    const from = ordered[i]!,
      to = ordered[i + 1]!;
    if (to <= from) continue;
    const prior = accepted.filter(
      (e) => Date.parse(e.effectiveAt!) <= from && e.kind !== "OUT",
    );
    let resume: SegmentKind = "office";
    let mode: SegmentKind = "office",
      visitId: string | null = null;
    for (const e of prior) {
      if (e.kind === "FIELD_START") mode = "field";
      if (e.kind === "FIELD_END") mode = "office";
      if (e.kind === "BREAK_START") {
        resume = mode;
        mode = "break";
      }
      if (e.kind === "BREAK_END") mode = resume;
      if (e.kind === "VISIT_START") visitId = e.visitId ?? null;
      if (e.kind === "VISIT_END") visitId = null;
    }
    const location = [...prior].reverse().find((e) => e.observation);
    let kind: SegmentKind = mode,
      sourceIds = prior.length ? [prior.at(-1)!.id] : [],
      assumption = "Explicit break; no location inference";
    if (mode !== "break") {
      if (
        !location ||
        location.observation === "unknown" ||
        from - Date.parse(location.effectiveAt!) >= policy.gapSeconds * 1000
      ) {
        kind = "unknown";
        assumption =
          "Location gap; neither absence nor unpaid/outside time is inferred";
      } else {
        kind =
          mode === "field"
            ? "field"
            : location.observation === "inside"
              ? "office"
              : "outside";
        sourceIds = [location.id];
        assumption =
          "Observation held only within configured gap window; GPS/photo is not biometric proof";
      }
    }
    const override = adjustments.find(
      (a) => Date.parse(a.startsAt) <= from && Date.parse(a.endsAt) >= to,
    );
    if (override) {
      kind = override.kind;
      sourceIds = [override.id];
      assumption = "Independently approved adjustment; raw evidence preserved";
    }
    const prev = segments.at(-1);
    if (
      prev &&
      prev.kind === kind &&
      prev.assumption === assumption &&
      prev.visitId === visitId &&
      prev.sourceIds.join() === sourceIds.join()
    )
      prev.endsAt = new Date(to).toISOString();
    else
      segments.push({
        startsAt: new Date(from).toISOString(),
        endsAt: new Date(to).toISOString(),
        kind,
        sourceIds,
        assumption,
        visitId,
      });
  }
  const gaps = [
    ...new Set([
      ...(out ? [] : ["Missed exit / session remains open"]),
      ...events
        .filter((e) => e.status !== "accepted")
        .map(() => "Raw events await verification"),
      ...(segments.some((s) => s.kind === "unknown")
        ? ["Unknown location intervals"]
        : []),
    ]),
  ];
  return { segments, gaps, open: !out, version: ENGINE_VERSION };
}
export function stateAfter(kinds: string[]) {
  let state = "off",
    resume = "office",
    visiting = false;
  for (const kind of kinds) {
    if (kind === "VISIT_START") {
      if (state !== "field" || visiting) return null;
      visiting = true;
      continue;
    }
    if (kind === "VISIT_END") {
      if (state !== "field" || !visiting) return null;
      visiting = false;
      continue;
    }
    if (kind === "BREAK_START" && ["office", "field"].includes(state)) {
      if (visiting) return null;
      resume = state;
      state = "break";
      continue;
    }
    if (kind === "BREAK_END" && state === "break") {
      state = resume;
      continue;
    }
    if (kind === "FIELD_END" && visiting) return null;
    const next: Record<string, Record<string, string>> = {
      off: { IN: "office" },
      office: { OUT: "off", FIELD_START: "field", LOCATION: "office" },
      field: { FIELD_END: "office", LOCATION: "field" },
      break: { LOCATION: "break" },
    };
    const value = next[state]?.[kind];
    if (!value) return null;
    state = value;
  }
  return state;
}
