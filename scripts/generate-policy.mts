import { writeFile } from "node:fs/promises";
import { catalogue, templateRules } from "../packages/authz/src/catalogue.js";
const quote = (v: string) => `'${v.replaceAll("'", "''")}'`;
let sql = `-- Generated catalogue from packages/authz/src/catalogue.ts; policy below is reviewed SQL.\n`;
sql += `CREATE TABLE app.module_catalogue(id text PRIMARY KEY,name text NOT NULL,hindi text NOT NULL,section text NOT NULL,phase int NOT NULL,actions text[] NOT NULL,fields text[] NOT NULL,dependencies text[] NOT NULL);\n`;
sql += `CREATE TABLE app.permission_catalogue(key text PRIMARY KEY,module_id text NOT NULL REFERENCES app.module_catalogue(id),action text NOT NULL);\n`;
sql += `CREATE TABLE app.role_templates(role text NOT NULL,key text NOT NULL REFERENCES app.permission_catalogue(key),scope text NOT NULL CHECK(scope IN ('own','team','site','organization')),PRIMARY KEY(role,key));\n`;
for (const m of catalogue) {
  const arr = (v: readonly string[]) =>
    `ARRAY[${v.map(quote).join(",")}]::text[]`;
  sql += `INSERT INTO app.module_catalogue VALUES(${[m.id, m.name, m.hindi, m.group].map(quote).join(",")},${m.phase},${arr(m.actions)},${arr(m.fields)},${arr(m.dependencies)});\n`;
  for (const a of [...m.actions, ...m.fields.map((f) => `field.${f}`)])
    sql += `INSERT INTO app.permission_catalogue VALUES(${quote(`${m.id}.${a}`)},${quote(m.id)},${quote(a)});\n`;
}
for (const r of templateRules)
  sql += `INSERT INTO app.role_templates VALUES(${quote(r.role)},${quote(r.key)},${quote(r.scope)});\n`;
const output = process.argv[2];
if (!output)
  throw new Error(
    "Supply a NEW output file for review; existing migrations are immutable.",
  );
await writeFile(output, sql, { flag: "wx" });
