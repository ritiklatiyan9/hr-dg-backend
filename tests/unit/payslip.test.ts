import { test } from "node:test";
import assert from "node:assert/strict";
import {
  amountInWords,
  defaultPayslipDesign,
  inr,
  payPeriod,
  payslipDesign,
  renderPayslipHtml,
  type PayslipData,
} from "../../packages/contracts/payslip.js";
test("payslip money: exact Indian grouping and words", () => {
  assert.equal(inr("0"), "0.00");
  assert.equal(inr("99999"), "999.99");
  assert.equal(inr("3000050"), "30,000.50");
  assert.equal(inr("12345678900"), "12,34,56,789.00");
  assert.equal(inr(-150n), "-1.50");
  assert.equal(amountInWords("3000000"), "Rupees Thirty Thousand Only");
  assert.equal(
    amountInWords("12345678950"),
    "Rupees Twelve Crore Thirty Four Lakh Fifty Six Thousand Seven Hundred Eighty Nine and Fifty Paise Only",
  );
  assert.equal(amountInWords("5"), "Rupees Zero and Five Paise Only");
  assert.equal(payPeriod("2026-02-01", "2026-02-28"), "February 2026");
  assert.equal(payPeriod("2026-09-01", "2026-09-15"), "1 Sep 2026 – 15 Sep 2026");
});
test("payslip design: validated, escaped and faithful to the snapshot", () => {
  const data: PayslipData = {
    id: "r1",
    start: "2026-09-01",
    finish: "2026-09-30",
    revision: 1,
    publishedAt: "2026-09-30T20:00:00Z",
    snapshot: {
      lines: [
        { label: "Base <b>", kind: "earning", calculatedPaise: "3000000" },
        { label: "OT", kind: "overtime", calculatedPaise: "50000" },
        { label: "Advance", kind: "deduction", calculatedPaise: "100000" },
      ],
      grossPaise: "3050000",
      deductionPaise: "100000",
      netPaise: "2950000",
      employeeName: "Asha <script>",
      employeeCode: "DG-9",
      legalEmployer: "Demo Pvt Ltd",
    },
    payments: [
      {
        kind: "payment",
        paise: "1000000",
        method: "upi",
        reference: "UTR1",
        paidOn: "2026-10-01",
      },
    ],
    paidPaise: "1000000",
  };
  const html = renderPayslipHtml(
    { ...defaultPayslipDesign, companyName: "Acme & Co", layout: "modern" },
    data,
  );
  assert.ok(html.includes("Acme &amp; Co"));
  assert.ok(html.includes("Asha &lt;script&gt;") && !html.includes("<script>"));
  assert.ok(html.includes("Base &lt;b&gt;"));
  assert.ok(html.includes("₹29,500.00") && html.includes("Partially paid"));
  assert.ok(html.includes("Rupees Twenty Nine Thousand Five Hundred Only"));
  assert.ok(html.includes('class="modern"') && html.includes("September 2026"));
  // Company falls back to the legal employer; hidden sections disappear.
  const plain = renderPayslipHtml(
    {
      ...defaultPayslipDesign,
      show: { ...defaultPayslipDesign.show, payments: false, amountInWords: false },
    },
    data,
  );
  assert.ok(plain.includes("<h1>Demo Pvt Ltd</h1>"));
  assert.ok(!plain.includes("Payments recorded") && !plain.includes("Rupees"));
  for (const bad of [
    { accent: "red;}body{display:none" },
    { logo: "data:image/svg+xml;base64,PHN2Zz4=" },
    { layout: "fancy" },
    { extra: 1 },
  ])
    assert.equal(
      payslipDesign.safeParse({ ...defaultPayslipDesign, ...bad }).success,
      false,
    );
});
