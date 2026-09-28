import {
  S3Client,
  ListObjectsV2Command,
  GetObjectCommand,
  PutObjectCommand,
  HeadObjectCommand,
} from "@aws-sdk/client-s3";
import { readFile, mkdtemp, rm } from "node:fs/promises";
import { createReadStream, createWriteStream } from "node:fs";
import { createHash } from "node:crypto";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { pipeline } from "node:stream/promises";
import { parseEnv } from "node:util";

const option = (name) =>
  process.argv.find((v) => v.startsWith(`--${name}=`))?.slice(name.length + 3);
const copy = process.argv.includes("--copy");
const required = (env, key) => {
  if (!env[key]) throw Error(`${key} is required`);
  return env[key];
};
const hash = async (stream) => {
  const digest = createHash("sha256");
  for await (const chunk of stream) digest.update(chunk);
  return digest.digest("hex");
};
let temporary;
let sourceClient, targetClient;
try {
  if (copy && !process.argv.includes("--writers-stopped"))
    throw Error(
      "Stop source and target writers and pass --writers-stopped before copying files",
    );
  const source = parseEnv(
    await readFile(option("source-env") ?? ".env", "utf8"),
  );
  const target = parseEnv(await readFile(".env.aws", "utf8"));
  const destination = new URL(required(target, "S3_ENDPOINT"));
  if (
    destination.protocol !== "https:" ||
    !destination.hostname.endsWith(".amazonaws.com")
  )
    throw Error("Destination must be a private AWS S3 bucket over HTTPS");
  if (
    source.S3_ENDPOINT === target.S3_ENDPOINT &&
    source.S3_BUCKET === target.S3_BUCKET
  )
    throw Error("Source and destination bucket must differ");
  const client = (env) =>
    new S3Client({
      endpoint: required(env, "S3_ENDPOINT"),
      region: env.S3_REGION || "us-east-1",
      forcePathStyle: true,
      credentials: {
        accessKeyId: required(env, "S3_ACCESS_KEY"),
        secretAccessKey: required(env, "S3_SECRET_KEY"),
      },
    });
  sourceClient = client(source);
  targetClient = client(target);
  const sourceBucket = required(source, "S3_BUCKET"),
    targetBucket = required(target, "S3_BUCKET");
  temporary = await mkdtemp(join(tmpdir(), "hr-object-copy-"));
  let token,
    objects = 0,
    copied = 0,
    missing = 0;
  do {
    const page = await sourceClient.send(
      new ListObjectsV2Command({
        Bucket: sourceBucket,
        ContinuationToken: token,
      }),
    );
    for (const item of page.Contents ?? []) {
      const Key = item.Key;
      if (!Key) continue;
      let exists = true;
      try {
        await targetClient.send(
          new HeadObjectCommand({ Bucket: targetBucket, Key }),
        );
      } catch (error) {
        if (error.$metadata?.httpStatusCode === 404) exists = false;
        else throw error;
      }
      if (!exists && !copy) {
        missing++;
        objects++;
        continue;
      }
      const original = await sourceClient.send(
        new GetObjectCommand({ Bucket: sourceBucket, Key }),
      );
      let expected;
      if (!exists) {
        const file = join(temporary, "object");
        await pipeline(original.Body, createWriteStream(file, { mode: 0o600 }));
        expected = await hash(createReadStream(file));
        await targetClient.send(
          new PutObjectCommand({
            Bucket: targetBucket,
            Key,
            Body: createReadStream(file),
            ContentLength: original.ContentLength,
            ContentType: original.ContentType,
            ContentDisposition: original.ContentDisposition,
            ContentEncoding: original.ContentEncoding,
            CacheControl: original.CacheControl,
            Metadata: original.Metadata,
            IfNoneMatch: "*",
          }),
        );
        await rm(file);
        copied++;
      } else expected = await hash(original.Body);
      const restored = await targetClient.send(
        new GetObjectCommand({ Bucket: targetBucket, Key }),
      );
      if ((await hash(restored.Body)) !== expected)
        throw Error(
          "Object checksum mismatch; an existing object was not overwritten",
        );
      objects++;
    }
    token = page.IsTruncated ? page.NextContinuationToken : undefined;
  } while (token);
  console.log(
    JSON.stringify({
      objects,
      copied,
      missing,
      status: missing ? "INCOMPLETE" : "VERIFIED",
      check:
        "SHA-256 of each source/destination object; no keys or content logged",
    }),
  );
  if (missing) process.exitCode = 1;
} catch (error) {
  console.error(
    error instanceof Error && !("$metadata" in error) && !("code" in error)
      ? error.message
      : "Storage copy failed; check endpoints, credentials, access and source availability. Provider details suppressed.",
  );
  process.exitCode = 1;
} finally {
  sourceClient?.destroy();
  targetClient?.destroy();
  if (temporary) await rm(temporary, { recursive: true, force: true });
}
