import {
  S3Client,
  PutObjectCommand,
  GetObjectCommand,
} from "@aws-sdk/client-s3";
import sharp from "sharp";
import { createHash } from "node:crypto";
import { createConnection } from "node:net";
import type { Actor } from "../../../packages/authz/src/index.js";
import { fail } from "../../../packages/authz/src/index.js";
import type { Operations } from "./operations.js";
export function objectStorage() {
  if (
    !process.env.S3_ENDPOINT ||
    !process.env.S3_ACCESS_KEY ||
    !process.env.S3_SECRET_KEY
  )
    fail("STORAGE_UNAVAILABLE", "Private storage is not configured", 503);
  return new S3Client({
    endpoint: process.env.S3_ENDPOINT,
    region: process.env.S3_REGION ?? "us-east-1",
    forcePathStyle: true,
    credentials: {
      accessKeyId: process.env.S3_ACCESS_KEY,
      secretAccessKey: process.env.S3_SECRET_KEY,
    },
  });
}
async function scan(bytes: Buffer): Promise<string> {
  if (!process.env.CLAMAV_HOST) return "unavailable";
  return new Promise((resolve, reject) => {
    const socket = createConnection({
      host: process.env.CLAMAV_HOST!,
      port: Number(process.env.CLAMAV_PORT ?? 3310),
    });
    let response = "";
    socket.setTimeout(10000, () => socket.destroy(new Error("SCAN_TIMEOUT")));
    socket.on("connect", () => {
      socket.write(Buffer.from("zINSTREAM\0"));
      for (let i = 0; i < bytes.length; i += 65536) {
        const chunk = bytes.subarray(i, i + 65536),
          length = Buffer.alloc(4);
        length.writeUInt32BE(chunk.length);
        socket.write(length);
        socket.write(chunk);
      }
      socket.write(Buffer.alloc(4));
    });
    socket.on("data", (data) => {
      response += data.toString();
      if (response.includes("\0")) {
        socket.end();
        resolve(response.includes(" OK") ? "clean" : "infected");
      }
    });
    socket.on("error", () => reject(new Error("SCAN_UNAVAILABLE")));
  });
}
// Profile photos: a decoded, metadata-free 512 px JPEG, or rejected.
export async function profilePhoto(bytes: Buffer) {
  try {
    const image = sharp(bytes, {
      limitInputPixels: 24000000,
      failOn: "warning",
    });
    const { format } = await image.metadata();
    if (format !== "jpeg" && format !== "png") throw Error("format");
    return await image
      .rotate()
      .resize(512, 512, { fit: "cover" })
      .jpeg({ quality: 82 })
      .toBuffer();
  } catch {
    return fail("BAD_INPUT", "Choose a JPEG or PNG photo");
  }
}
export async function uploadFile(
  domain: Operations,
  actor: Actor,
  siteId: string,
  id: string,
  bytes: Buffer,
) {
  return domain.site(actor, siteId, async (c) => {
    const f = (
      await c.query(
        "SELECT * FROM app.private_files WHERE id=$1 AND owner_id=app.actor_id() FOR UPDATE",
        [id],
      )
    ).rows[0];
    if (!f) fail("NOT_FOUND", "Upload intent unavailable", 404);
    if (f.purpose === "hr") {
      if (
        !(await c.query("SELECT app.hr_visible($1,'edit') ok", [f.parent_id]))
          .rows[0].ok ||
        !(
          await c.query(
            "SELECT 1 FROM app.hr_records WHERE id=$1 AND status='draft'",
            [f.parent_id],
          )
        ).rowCount
      )
        fail("FORBIDDEN", "HR draft is not editable", 403);
    } else if (f.purpose === "dwr") {
      const report = (
        await c.query(
          "SELECT status,employee_id,user_id FROM app.dwr_reports WHERE id=$1",
          [f.parent_id],
        )
      ).rows[0];
      if (
        !report ||
        report.user_id !== actor.id ||
        !["draft", "returned"].includes(report.status)
      )
        fail("FORBIDDEN", "DWR draft is not editable", 403);
      await domain.allowed(c, "my_dwr.edit", report.employee_id);
    } else if (f.purpose === "task") {
      const task = (
        await c.query(
          "SELECT assignee_id,employee_id FROM app.work_tasks WHERE id=$1",
          [f.parent_id],
        )
      ).rows[0];
      if (!task) fail("NOT_FOUND", "Task unavailable", 404);
      await domain.allowed(
        c,
        task.assignee_id === actor.id ? "tasks.submit" : "tasks.edit",
        task.employee_id,
      );
    } else
      await domain.allowed(
        c,
        f.purpose === "visit" ? "field_duty.submit" : "my_attendance.create",
        f.employee_id,
      );
    const digest = createHash("sha256").update(bytes).digest("hex");
    if (f.original_hash && f.original_hash !== digest)
      fail("CONFLICT", "Original evidence is immutable", 409);
    if (f.status === "ready") {
      return { id, status: "ready", scanResult: f.scan_result };
    }
    if (
      Date.parse(f.expires_at) < Date.now() ||
      bytes.length !== f.byte_limit ||
      bytes.length > 8 * 1024 * 1024
    )
      fail("BAD_INPUT", "Upload size or expiry does not match intent");
    const s3 = objectStorage(),
      bucket = process.env.S3_BUCKET ?? "hr-private";
    // Keep the original private raw evidence; normal access serves a metadata-stripped derivative.
    await s3.send(
      new PutObjectCommand({
        Bucket: bucket,
        Key: `${f.object_key}/quarantine`,
        Body: bytes,
        ContentType: "application/octet-stream",
      }),
    );
    let scanResult: string;
    try {
      scanResult = await scan(bytes);
    } catch {
      scanResult = "scanner_error";
    }
    let status = "quarantined",
      clean: Buffer | undefined,
      type = f.declared_type;
    if (scanResult === "infected") status = "rejected";
    else if (type.startsWith("image/") && scanResult !== "scanner_error") {
      try {
        const image = sharp(bytes, {
          limitInputPixels: 24000000,
          failOn: "warning",
        });
        const metadata = await image.metadata();
        if (
          !["jpeg", "png"].includes(metadata.format ?? "") ||
          (type === "image/jpeg") !== (metadata.format === "jpeg")
        )
          fail("BAD_INPUT", "Photo format does not match intent");
        clean = await image.rotate().jpeg({ quality: 95 }).toBuffer();
        type = "image/jpeg";
        status = "ready";
        scanResult =
          scanResult === "unavailable"
            ? "image_decoded_scanner_unavailable"
            : scanResult;
      } catch {
        status = "rejected";
        scanResult = "invalid_image";
      }
    } else if (
      type === "application/pdf" &&
      scanResult === "clean" &&
      bytes.subarray(0, 5).toString() === "%PDF-"
    ) {
      clean = bytes;
      status = "ready";
    }
    if (clean)
      await s3.send(
        new PutObjectCommand({
          Bucket: bucket,
          Key: `${f.object_key}/content`,
          Body: clean,
          ContentType: type,
        }),
      );
    await c.query(
      "UPDATE app.private_files SET status=$2,scan_result=$3,original_hash=$4,content_hash=$5 WHERE id=$1",
      [
        id,
        status,
        scanResult,
        digest,
        clean ? createHash("sha256").update(clean).digest("hex") : null,
      ],
    );
    return { id, status, scanResult };
  });
}
export async function downloadFile(
  domain: Operations,
  actor: Actor,
  siteId: string,
  id: string,
) {
  return domain.site(actor, siteId, async (c) => {
    const f = (
      await c.query(
        "SELECT * FROM app.private_files WHERE id=$1 AND status='ready'",
        [id],
      )
    ).rows[0];
    if (!f) fail("NOT_FOUND", "Attachment unavailable", 404);
    if (f.purpose === "hr") {
      if (
        !(await c.query("SELECT app.hr_visible($1) ok", [f.parent_id])).rows[0]
          .ok
      )
        fail("FORBIDDEN", "Attachment unavailable", 403);
      const record = (
        await c.query("SELECT kind FROM app.hr_records WHERE id=$1", [
          f.parent_id,
        ])
      ).rows[0];
      if (
        ["document", "policy"].includes(record?.kind) &&
        !(await c.query("SELECT app.hr_visible($1,'export') ok", [f.parent_id]))
          .rows[0].ok
      )
        fail("FORBIDDEN", "Document download permission required", 403);
      await domain.auditOperation(c, "hr.download", f.parent_id, [
        "attachment",
      ]);
    } else if (f.purpose === "dwr") {
      if (
        !(await c.query("SELECT app.dwr_visible($1) ok", [f.parent_id])).rows[0]
          .ok
      )
        fail("FORBIDDEN", "DWR attachment unavailable", 403);
    } else if (f.purpose === "task") {
      const task = (
        await c.query("SELECT employee_id FROM app.work_tasks WHERE id=$1", [
          f.parent_id,
        ])
      ).rows[0];
      if (!task) fail("NOT_FOUND", "Task unavailable");
      await domain.allowed(c, "tasks.view", task.employee_id);
    } else
      await domain.allowed(
        c,
        f.purpose === "visit"
          ? "field_duty.view"
          : f.owner_id === actor.id
            ? "my_attendance.view"
            : "attendance.view",
        f.employee_id,
      );
    const object = await objectStorage().send(
      new GetObjectCommand({
        Bucket: process.env.S3_BUCKET ?? "hr-private",
        Key: `${f.object_key}/content`,
      }),
    );
    const bytes = await object.Body?.transformToByteArray();
    if (!bytes) fail("NOT_FOUND", "Object unavailable");
    return {
      bytes: Buffer.from(bytes),
      type: f.declared_type.startsWith("image/")
        ? "image/jpeg"
        : "application/pdf",
    };
  });
}
