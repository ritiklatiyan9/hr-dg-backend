import {
  randomBytes,
  scrypt as scryptCb,
  timingSafeEqual,
  createHash,
  createCipheriv,
  createDecipheriv,
} from "node:crypto";
import * as OTPAuth from "otpauth";
const scrypt = (
  password: string,
  salt: string,
  length: number,
  options: { N: number; r: number; p: number; maxmem: number },
) =>
  new Promise<Buffer>((resolve, reject) =>
    scryptCb(password, salt, length, options, (error, key) =>
      error ? reject(error) : resolve(key),
    ),
  );
export const token = () => randomBytes(32).toString("base64url");
export const digest = (value: string) =>
  createHash("sha256").update(value).digest("hex");
export function constantEqual(a: string, b: string) {
  const aa = Buffer.from(a),
    bb = Buffer.from(b);
  return aa.length === bb.length && timingSafeEqual(aa, bb);
}
export async function passwordHash(password: string) {
  const salt = randomBytes(16).toString("hex");
  const hash = (await scrypt(password, salt, 64, {
    N: 32768,
    r: 8,
    p: 1,
    maxmem: 64 * 1024 * 1024,
  })) as Buffer;
  return `scrypt$32768$${salt}$${hash.toString("hex")}`;
}
export async function passwordValid(password: string, encoded: string | null) {
  const parts = (encoded ?? "").split("$");
  const salt = parts[2] ?? "00000000000000000000000000000000";
  const hash = (await scrypt(password, salt, 64, {
    N: 32768,
    r: 8,
    p: 1,
    maxmem: 64 * 1024 * 1024,
  })) as Buffer;
  return (
    parts[0] === "scrypt" && constantEqual(hash.toString("hex"), parts[3] ?? "")
  );
}
export function encrypt(value: string, key: string) {
  const iv = randomBytes(12),
    cipher = createCipheriv("aes-256-gcm", Buffer.from(key, "hex"), iv);
  const encrypted = Buffer.concat([
    cipher.update(value, "utf8"),
    cipher.final(),
  ]);
  return [iv, cipher.getAuthTag(), encrypted]
    .map((v) => v.toString("base64url"))
    .join(".");
}
export function decrypt(value: string, key: string) {
  const [iv, tag, data] = value
    .split(".")
    .map((v) => Buffer.from(v, "base64url"));
  if (!iv || !tag || !data) throw new Error("Invalid ciphertext");
  const cipher = createDecipheriv("aes-256-gcm", Buffer.from(key, "hex"), iv);
  cipher.setAuthTag(tag);
  return Buffer.concat([cipher.update(data), cipher.final()]).toString("utf8");
}
export function totp(secret?: string, label = "Defence Garden") {
  return new OTPAuth.TOTP({
    issuer: "Defence Garden HR",
    label,
    algorithm: "SHA1",
    digits: 6,
    period: 30,
    secret: secret
      ? OTPAuth.Secret.fromBase32(secret)
      : new OTPAuth.Secret({ size: 20 }),
  });
}
