import { mkdir, rename, rm, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";

const url = process.env.AWS_RDS_CA_URL;
const configuredPath = process.env.AWS_RDS_CA_FILE;
if (!url || !configuredPath)
  throw new Error("AWS_RDS_CA_URL and AWS_RDS_CA_FILE are required");
if (!url.startsWith("https://truststore.pki.rds.amazonaws.com/"))
  throw new Error(
    "Refusing to download an RDS CA bundle from an untrusted host",
  );

const destination = resolve(configuredPath);
const temporary = `${destination}.tmp`;
await mkdir(dirname(destination), { recursive: true, mode: 0o700 });
const response = await fetch(url, { redirect: "error" });
if (!response.ok)
  throw new Error(`AWS CA download failed with HTTP ${response.status}`);
const body = await response.text();
const certificates = body.match(/-----BEGIN CERTIFICATE-----/g)?.length ?? 0;
if (certificates < 1 || !body.includes("-----END CERTIFICATE-----"))
  throw new Error("Downloaded AWS CA bundle is not valid PEM content");
try {
  await writeFile(temporary, body, { encoding: "utf8", mode: 0o600 });
  await rename(temporary, destination);
} finally {
  await rm(temporary, { force: true });
}
console.log(
  `Installed the official AWS RDS CA bundle (${certificates} certificates).`,
);
