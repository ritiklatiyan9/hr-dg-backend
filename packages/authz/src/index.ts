import { GraphQLError } from "graphql";
export interface Actor {
  id: string;
  organizationId: string;
  permissionVersion: number;
  sessionId: string;
  kind: "web" | "mobile";
  csrfHash: string;
  mfaVerified: boolean;
  requiresMfa: boolean;
}
export function fail(code: string, message: string, statusCode = 400): never {
  throw Object.assign(new GraphQLError(message, { extensions: { code } }), {
    code,
    statusCode,
  });
}
export function requireActor(actor: Actor | null): Actor {
  if (!actor) fail("UNAUTHENTICATED", "Please sign in", 401);
  if (actor.requiresMfa && !actor.mfaVerified)
    fail("MFA_REQUIRED", "Complete two-step verification", 403);
  return actor;
}
export function workDate(instant: Date, timezone: string) {
  return new Intl.DateTimeFormat("en-CA", {
    timeZone: timezone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(instant);
}
