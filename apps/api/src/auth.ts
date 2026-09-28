import type pg from "pg";
import { randomUUID } from "node:crypto";
import { z } from "zod";
import { transaction } from "../../../packages/db/src/index.js";
import { fail, type Actor } from "../../../packages/authz/src/index.js";
import {
  constantEqual,
  decrypt,
  digest,
  encrypt,
  passwordHash,
  passwordValid,
  token,
  totp,
} from "./security.js";
import type { Config } from "../../../packages/config/src/index.js";
export const loginInput = z.object({
  organizationId: z.uuid(),
  email: z
    .email()
    .max(254)
    .transform((v) => v.toLowerCase()),
  password: z.string().min(1).max(256),
  kind: z.enum(["web", "mobile"]),
  deviceId: z.uuid().optional(),
});
export const newPassword = z.string().min(12).max(128);
export class AuthService {
  constructor(
    readonly pool: pg.Pool,
    readonly config: Config,
  ) {}
  async lookup(access: string): Promise<Actor | null> {
    if (access.length > 256) return null;
    const { rows } = await this.pool.query(
      `SELECT s.*,u.permission_version,(u.requires_mfa OR u.mfa_enabled) AS requires_mfa FROM auth.sessions s JOIN auth.users u
   ON (u.organization_id,u.id)=(s.organization_id,s.user_id)
   WHERE access_hash=$1 AND s.revoked_at IS NULL AND s.expires_at>now() AND s.absolute_expires_at>now() AND u.active`,
      [digest(access)],
    );
    const r = rows[0];
    return r
      ? {
          id: r.user_id,
          organizationId: r.organization_id,
          sessionId: r.id,
          permissionVersion: r.permission_version,
          kind: r.kind,
          csrfHash: r.csrf_hash,
          mfaVerified: r.mfa_verified,
          requiresMfa: r.requires_mfa,
        }
      : null;
  }
  async login(input: z.infer<typeof loginInput>) {
    const result = await this.pool.query(
      "SELECT * FROM auth.users WHERE organization_id=$1 AND email=$2",
      [input.organizationId, input.email],
    );
    const user = result.rows[0];
    const valid = await passwordValid(
      input.password,
      user?.password_hash ?? null,
    );
    if (!user || !valid || !user.active)
      fail("INVALID_CREDENTIALS", "Email or password is incorrect", 401);
    const access = token(),
      csrf = token(),
      refresh = input.kind === "mobile" ? token() : null;
    const mfaRequired = Boolean(user.requires_mfa || user.mfa_enabled);
    await transaction(this.pool, async (c) => {
      // Recheck active status under lock to prevent a password-reset/login race.
      const locked = (
        await c.query("SELECT * FROM auth.users WHERE id=$1 FOR UPDATE", [
          user.id,
        ])
      ).rows[0];
      if (!locked.active || locked.password_hash !== user.password_hash)
        fail("INVALID_CREDENTIALS", "Sign in again", 401);
      if (input.kind === "mobile") {
        if (!input.deviceId) fail("BAD_INPUT", "Device ID required");
        const bound = await c.query(
          `INSERT INTO auth.devices(id,organization_id,user_id,label) VALUES($1,$2,$3,'Employee app')
     ON CONFLICT(id) DO UPDATE SET last_seen_at=now() WHERE devices.organization_id=$2 AND devices.user_id=$3`,
          [input.deviceId, user.organization_id, user.id],
        );
        // A device ID belongs to one account; the app keeps one per account.
        if (!bound.rowCount)
          fail("DEVICE_IN_USE", "This device ID belongs to another account", 409);
      }
      await c.query(
        `INSERT INTO auth.sessions(organization_id,user_id,kind,access_hash,csrf_hash,refresh_hash,device_id,mfa_verified,expires_at,absolute_expires_at)
    VALUES($1,$2,$3,$4,$5,$6,$7,$8,now()+$9::interval,now()+$10::interval)`,
        [
          user.organization_id,
          user.id,
          input.kind,
          digest(access),
          digest(csrf),
          refresh ? digest(refresh) : null,
          input.kind === "mobile" ? input.deviceId : null,
          false,
          mfaRequired
            ? "10 minutes"
            : input.kind === "web"
              ? "8 hours"
              : "15 minutes",
          input.kind === "web" ? "8 hours" : "30 days",
        ],
      );
      await c.query(
        "INSERT INTO auth.events(organization_id,user_id,action) VALUES($1,$2,$3)",
        [user.organization_id, user.id, "auth.login"],
      );
    });
    return {
      accessToken: access,
      csrfToken: csrf,
      refreshToken: refresh,
      mfaRequired,
      enrollmentRequired: mfaRequired && !user.mfa_enabled,
    };
  }
  async setupMfa(actor: Actor) {
    return transaction(this.pool, async (c) => {
      const { rows } = await c.query(
        "SELECT * FROM auth.users WHERE id=$1 AND organization_id=$2 FOR UPDATE",
        [actor.id, actor.organizationId],
      );
      const u = rows[0];
      if (u.mfa_enabled)
        fail("CONFLICT", "Two-step verification is already configured", 409);
      const otp = totp(
        u.mfa_secret
          ? decrypt(u.mfa_secret, this.config.ENCRYPTION_KEY)
          : undefined,
        u.email,
      );
      await c.query("UPDATE auth.users SET mfa_secret=$1 WHERE id=$2", [
        encrypt(otp.secret.base32, this.config.ENCRYPTION_KEY),
        actor.id,
      ]);
      return { secret: otp.secret.base32, uri: otp.toString() };
    });
  }
  async verifyMfa(actor: Actor, code: string) {
    await transaction(this.pool, async (c) => {
      const u = (
        await c.query("SELECT * FROM auth.users WHERE id=$1 FOR UPDATE", [
          actor.id,
        ])
      ).rows[0];
      if (!u.mfa_secret)
        fail("MFA_REQUIRED", "Set up an authenticator first", 403);
      const delta = totp(
        decrypt(u.mfa_secret, this.config.ENCRYPTION_KEY),
      ).validate({ token: code, window: 1 });
      const step = Math.floor(Date.now() / 30000) + (delta ?? 0);
      if (delta === null || step <= Number(u.last_totp_step))
        fail("INVALID_MFA", "Invalid or already used code", 401);
      await c.query(
        "UPDATE auth.users SET mfa_enabled=true,last_totp_step=$1 WHERE id=$2",
        [step, actor.id],
      );
      await c.query(
        "UPDATE auth.sessions SET mfa_verified=true,expires_at=LEAST(absolute_expires_at,now()+CASE WHEN kind='web' THEN interval '8 hours' ELSE interval '15 minutes' END) WHERE id=$1 AND revoked_at IS NULL",
        [actor.sessionId],
      );
      await c.query(
        "INSERT INTO auth.events(organization_id,user_id,action) VALUES($1,$2,'auth.mfa_verified')",
        [actor.organizationId, actor.id],
      );
    });
  }
  async refresh(value: string) {
    const access = token(),
      refresh = token(),
      csrf = token();
    const result = await transaction(this.pool, async (c) => {
      const hash = digest(value);
      const { rows } = await c.query(
        `SELECT s.*,(u.requires_mfa OR u.mfa_enabled) AS requires_mfa FROM auth.sessions s JOIN auth.users u ON u.id=s.user_id
    WHERE refresh_hash=$1 AND s.kind='mobile' AND u.active FOR UPDATE OF s`,
        [hash],
      );
      const s = rows[0];
      if (!s) {
        await c.query(
          "UPDATE auth.sessions SET revoked_at=now() WHERE id IN (SELECT session_id FROM auth.refresh_history WHERE token_hash=$1)",
          [hash],
        );
        return false; // commit replay revocation before returning an error
      }
      if (
        s.revoked_at ||
        new Date(s.absolute_expires_at) <= new Date() ||
        (s.requires_mfa && !s.mfa_verified)
      )
        return false;
      await c.query(
        "INSERT INTO auth.refresh_history(token_hash,session_id) VALUES($1,$2)",
        [hash, s.id],
      );
      await c.query(
        "UPDATE auth.sessions SET access_hash=$1,refresh_hash=$2,csrf_hash=$3,expires_at=LEAST(absolute_expires_at,now()+interval '15 minutes') WHERE id=$4",
        [digest(access), digest(refresh), digest(csrf), s.id],
      );
      return true;
    });
    if (!result) fail("UNAUTHENTICATED", "Sign in again", 401);
    return { accessToken: access, refreshToken: refresh, csrfToken: csrf };
  }
  async logout(actor: Actor, all = false) {
    await transaction(this.pool, async (c) => {
      await c.query(
        `UPDATE auth.sessions SET revoked_at=now() WHERE organization_id=$1 AND user_id=$2 ${all ? "" : "AND id=$3"}`,
        all
          ? [actor.organizationId, actor.id]
          : [actor.organizationId, actor.id, actor.sessionId],
      );
      await c.query(
        "INSERT INTO auth.events(organization_id,user_id,action) VALUES($1,$2,$3)",
        [
          actor.organizationId,
          actor.id,
          all ? "auth.logout_all" : "auth.logout",
        ],
      );
    });
  }
  async issueAction(
    organizationId: string,
    email: string,
    purpose: "recovery" | "invitation",
  ) {
    await transaction(this.pool, async (c) => {
      const u = (
        await c.query(
          "SELECT * FROM auth.users WHERE organization_id=$1 AND email=$2 AND active FOR UPDATE",
          [organizationId, email.toLowerCase()],
        )
      ).rows[0];
      if (!u) return;
      const raw = token();
      await c.query(
        "UPDATE auth.action_tokens SET used_at=now() WHERE user_id=$1 AND used_at IS NULL",
        [u.id],
      );
      await c.query(
        "INSERT INTO auth.action_tokens(token_hash,organization_id,user_id,purpose,expires_at) VALUES($1,$2,$3,$4,now()+interval '30 minutes')",
        [digest(raw), organizationId, u.id, purpose],
      );
      // A fragment keeps bearer credentials out of proxy access logs and referrers.
      const url = `${this.config.WEB_ORIGIN}/#action=${raw}`;
      await c.query(
        "INSERT INTO auth.mail_outbox(encrypted_payload) VALUES($1)",
        [
          encrypt(
            JSON.stringify({
              to: u.email,
              subject:
                purpose === "invitation"
                  ? "Your Defence Garden HR invitation"
                  : "Reset your password",
              text: `Open ${url}\nThis single-use link expires in 30 minutes. If you did not request it, ignore this message.`,
            }),
            this.config.ENCRYPTION_KEY,
          ),
        ],
      );
      await c.query(
        "INSERT INTO auth.events(organization_id,user_id,action) VALUES($1,$2,$3)",
        [organizationId, u.id, `auth.${purpose}_requested`],
      );
    });
  }
  async redeemAction(raw: string, password: string) {
    const hashed = await passwordHash(password);
    await transaction(this.pool, async (c) => {
      const a = (
        await c.query(
          "SELECT * FROM auth.action_tokens WHERE token_hash=$1 AND used_at IS NULL AND expires_at>now() FOR UPDATE",
          [digest(raw)],
        )
      ).rows[0];
      if (!a)
        fail("INVALID_TOKEN", "This link has expired or was already used", 400);
      await c.query(
        "UPDATE auth.users SET password_hash=$1 WHERE id=$2 AND organization_id=$3 AND active",
        [hashed, a.user_id, a.organization_id],
      );
      await c.query(
        "UPDATE auth.action_tokens SET used_at=now() WHERE user_id=$1 AND used_at IS NULL",
        [a.user_id],
      );
      await c.query(
        "UPDATE auth.sessions SET revoked_at=now() WHERE user_id=$1",
        [a.user_id],
      );
      await c.query(
        "INSERT INTO auth.events(organization_id,user_id,action) VALUES($1,$2,$3)",
        [a.organization_id, a.user_id, `auth.${a.purpose}_completed`],
      );
    });
  }
  csrf(actor: Actor, value: string | undefined) {
    if (!value || !constantEqual(digest(value), actor.csrfHash))
      fail("CSRF_INVALID", "Refresh the page and try again", 403);
  }
}
