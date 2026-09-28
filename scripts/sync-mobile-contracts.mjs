import { mkdir, copyFile } from "node:fs/promises";
const target = "apps/employee-mobile/lib/graphql";
await mkdir(target, { recursive: true });
await copyFile("packages/contracts/schema.graphql", `${target}/schema.graphql`);
await copyFile(
  "packages/contracts/operations.graphql",
  `${target}/operations.graphql`,
);
console.log(
  "Dart sources synced. Generate with: dart run build_runner build --delete-conflicting-outputs",
);
