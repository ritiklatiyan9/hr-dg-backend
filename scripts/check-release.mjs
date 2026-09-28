import { execFileSync } from "node:child_process";
import { readFile, readdir } from "node:fs/promises";
const forbidden = [
  /AKIA[0-9A-Z]{16}/,
  /-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/,
  /sk-(?:or-v1-)?[A-Za-z0-9_-]{32,}/,
];
let files = [];
let tracked = false;
try {
  files = execFileSync("git", ["ls-files", "-z"], {
    encoding: "utf8",
    stdio: ["ignore", "pipe", "ignore"],
  })
    .split("\0")
    .filter(Boolean);
  tracked = true;
} catch {
  for (const root of ["apps", "packages", "scripts", "infra", ".github"])
    for (const file of await readdir(root, { recursive: true }))
      if (
        /\.(?:ts|tsx|mjs|dart|yaml|yml|sql)$/.test(file) &&
        !/(?:node_modules|build|\.dart_tool|\.gradle|generated|\.graphql\.dart)/.test(
          file,
        )
      )
        files.push(`${root}/${file}`);
}
const issues = [];
for (const file of files) {
  if (
    tracked &&
    /(?:^|\/)\.env(?:\.|$)/.test(file) &&
    !file.endsWith(".example")
  ) {
    issues.push(`${file}: tracked environment file`);
    continue;
  }
  if (
    !/\.(?:ts|tsx|js|mjs|dart|yaml|yml|sql|json|pem)$/.test(file) ||
    file.endsWith("check-release.mjs")
  )
    continue;
  let text;
  try {
    text = await readFile(file, "utf8");
  } catch {
    continue;
  }
  if (forbidden.some((r) => r.test(text)))
    issues.push(`${file}: possible credential material (value withheld)`);
}
if (issues.length) throw Error(issues.join("\n"));
console.log(
  `PASS: credential-pattern check on ${files.length} files. ${tracked ? "Tracked environment-file check passed." : "No Git metadata: tracked-file check NOT RUN."} This is not a proof that no secrets exist.`,
);
