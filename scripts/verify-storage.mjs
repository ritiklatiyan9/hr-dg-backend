import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import {
  S3Client,
  HeadBucketCommand,
  PutObjectCommand,
  GetObjectCommand,
  DeleteObjectCommand,
} from "@aws-sdk/client-s3";
const endpoint = process.env.S3_ENDPOINT;
if (
  !endpoint ||
  !["localhost", "127.0.0.1"].includes(new URL(endpoint).hostname)
)
  throw new Error("This smoke test only permits local storage");
const client = new S3Client({
  endpoint,
  forcePathStyle: true,
  region: "us-east-1",
  credentials: {
    accessKeyId: process.env.S3_ACCESS_KEY,
    secretAccessKey: process.env.S3_SECRET_KEY,
  },
});
const Bucket = process.env.S3_BUCKET,
  Key = `synthetic-verification/${randomUUID()}.txt`;
try {
  await client.send(new HeadBucketCommand({ Bucket }));
  await client.send(
    new PutObjectCommand({
      Bucket,
      Key,
      Body: "Synthetic private storage verification",
    }),
  );
  const data = await client.send(new GetObjectCommand({ Bucket, Key }));
  assert.equal(
    await data.Body.transformToString(),
    "Synthetic private storage verification",
  );
  const anonymous = await fetch(`${endpoint}/${Bucket}/${Key}`);
  assert.equal(anonymous.status, 403);
  console.log("PASS: private S3 write/read; anonymous object access denied.");
} finally {
  await client.send(new DeleteObjectCommand({ Bucket, Key }));
  client.destroy();
}
