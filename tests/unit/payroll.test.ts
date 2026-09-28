import { test } from "node:test";
import assert from "node:assert/strict";
import {
  calculatePayroll,
  importPayrollCsv,
  csvCell,
  money,
  rupeesToPaise,
} from "../../packages/contracts/payroll.js";
const policy = {
  rounding: "half_up_line",
  accountantReview: true,
  policyVersion: "SYNTHETIC-NOT-COMPANY",
  assumptions: "Synthetic accountant-reviewed fixture only",
};
const line = (
  code: string,
  paise: string,
  kind = "earning",
  numerator = 1,
  denominator = 1,
) => ({ code, label: code, paise, kind, numerator, denominator });
test("exact payroll: full/partial month, overtime, bonus, reimbursement and deductions reconcile", () => {
  const r = calculatePayroll({
    ...policy,
    lines: [
      line("BASE", "3000000", "earning", 15, 30),
      line("OT", "15000", "overtime", 5),
      line("BONUS", "50000", "bonus"),
      line("EXP", "20000", "reimbursement"),
      line("ARREARS", "101", "adjustment"),
      line("DEDUCTION", "10000", "deduction"),
    ],
  });
  assert.equal(r.netPaise, "1635101");
  assert.equal(money(r.netPaise), "16351.01");
  assert.equal(
    calculatePayroll({ ...policy, lines: [line("BASE", "3000000")] }).netPaise,
    "3000000",
  );
  assert.equal(
    calculatePayroll({ ...policy, lines: [line("HALF", "1", "earning", 1, 2)] })
      .netPaise,
    "1",
  );
  assert.equal(
    calculatePayroll({ ...policy, lines: [line("LARGE", "99999999999999")] })
      .netPaise,
    "99999999999999",
  );
});
test("reject floats, guessed policies, duplicate codes, malformed/partial imports, negative net", () => {
  for (const lines of [
    [line("B", "1.5")],
    [line("B", "1"), line("B", "2")],
    [line("B", "1"), line("D", "2", "deduction")],
  ])
    assert.throws(() => calculatePayroll({ ...policy, lines }));
  assert.throws(() => calculatePayroll({ lines: [line("B", "1")] }));
  const header = "code,label,kind,paise,numerator,denominator\n";
  assert.equal(
    importPayrollCsv(header + 'BASE,"Base, salary",earning,100,1,2')[0]?.label,
    "Base, salary",
  );
  for (const text of [
    "wrong\n1,2",
    header + "B,b,earning,100,1,1\nD,bad,deduction,1.1,1,1",
    header + 'B,"unfinished',
  ])
    assert.throws(() => importPayrollCsv(text));
});
test("CSV exports neutralize formula prefixes and escape quoted/newline text", () => {
  for (const value of [
    "=SUM(1,2)",
    " +cmd",
    "-1",
    "@example",
    '\t=HYPERLINK("x")',
  ])
    assert.ok(csvCell(value).startsWith("\"'"));
  assert.equal(csvCell('a"b'), '"a""b"');
});
test("rupee input converts exactly to paise and rejects ambiguous amounts", () => {
  assert.equal(rupeesToPaise("30000"), "3000000");
  assert.equal(rupeesToPaise(" 30,000.5 "), "3000050");
  assert.equal(rupeesToPaise("0.07"), "7");
  assert.equal(rupeesToPaise("999999999999.99"), "99999999999999");
  assert.equal(money(rupeesToPaise("16351.01")), "16351.01");
  for (const bad of [
    "",
    "-1",
    "1.001",
    "1e3",
    "₹10",
    "1.",
    ".5",
    "1000000000000",
  ])
    assert.throws(() => rupeesToPaise(bad), bad);
});
