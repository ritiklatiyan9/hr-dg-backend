import { test } from "node:test";
import assert from "node:assert/strict";
import { buildSchema, parse, validate } from "graphql";
import { boundedQuery } from "../../apps/api/src/query-cost.js";
test("expanded fragment cost and aliases are bounded", () => {
  const schema = buildSchema(
    "type Item { value: String child: Item } type Query { item: Item }",
  );
  assert.equal(
    validate(schema, parse("{item{value}}"), [boundedQuery]).length,
    0,
  );
  const repeated = Array.from(
    { length: 40 },
    (_, i) => `a${i}:item{...F}`,
  ).join(" ");
  assert.ok(
    validate(
      schema,
      parse(
        `{${repeated}} fragment F on Item{a:value b:value c:value d:value}`,
      ),
      [boundedQuery],
    ).length,
  );
  assert.ok(
    validate(schema, parse("{item{...F}} fragment F on Item{...F}"), [
      boundedQuery,
    ]).length,
  );
});
