import test from "node:test";
import assert from "node:assert/strict";
import {
  formatMoney,
  formatDecimalMoney,
} from "../../apps/hr-web/src/components/shared/money-format.js";
test("HR display formats integer paise and authoritative decimals without float conversion or rounding", () => {
  assert.equal(formatMoney("3000000"), "30,000.00");
  assert.equal(formatMoney("-5"), "-0.05");
  assert.equal(formatMoney("900719925474099301"), "9,00,71,99,25,47,40,993.01");
  assert.equal(formatDecimalMoney("42000.00"), "42,000.00");
  assert.equal(formatDecimalMoney("-12345678.125"), "-1,23,45,678.125");
  assert.equal(formatDecimalMoney("not configured"), "—");
});
