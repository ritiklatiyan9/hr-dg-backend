import { randomBytes } from "node:crypto";
import { readFile, writeFile } from "node:fs/promises";

const source = new URL("../.env.aws.example", import.meta.url);
const destination = new URL("../.env.aws", import.meta.url);
let content = await readFile(source, "utf8");

const replaceBlank = (name, value) => {
  const marker = `${name}=`;
  const next = content.replace(`${marker}\n`, `${marker}${value}\n`);
  if (next === content)
    throw new Error(`Missing blank ${name} in .env.aws.example`);
  content = next;
};

replaceBlank("ENCRYPTION_KEY", randomBytes(32).toString("hex"));
replaceBlank("RUNTIME_DB_PASSWORD", randomBytes(32).toString("base64url"));
replaceBlank("AUTH_DB_PASSWORD", randomBytes(32).toString("base64url"));
replaceBlank("WORKER_DB_PASSWORD", randomBytes(32).toString("base64url"));

try {
  await writeFile(destination, content, {
    encoding: "utf8",
    flag: "wx",
    mode: 0o600,
  });
  console.log(
    "Created .env.aws with generated application secrets (mode 0600).",
  );
  console.log(
    "Add the RDS admin password and replace deployment placeholders locally.",
  );
} catch (error) {
  if (
    error &&
    typeof error === "object" &&
    "code" in error &&
    error.code === "EEXIST"
  )
    throw new Error(
      ".env.aws already exists; refusing to overwrite credentials",
    );
  throw error;
}
