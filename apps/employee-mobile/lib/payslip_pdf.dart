import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'ui/components.dart' show formatInr;

/// Native PDF of a published payslip in the site's saved design. Mirrors
/// packages/contracts/payslip.ts (the web/print renderer): same sections,
/// toggles and layouts. Amounts come only from the published snapshot.
const _months = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July', //
  'August', 'September', 'October', 'November', 'December',
];
String payslipDay(String d) =>
    '${int.parse(d.substring(8, 10))} ${_months[int.parse(d.substring(5, 7)) - 1].substring(0, 3)} ${d.substring(0, 4)}';

/// "September 2026" for a whole calendar month, otherwise the date range.
String payslipPeriod(String start, String finish) {
  final y = int.parse(start.substring(0, 4)), m = int.parse(start.substring(5, 7));
  final last = DateTime.utc(y, m + 1, 0).day;
  return start.substring(8) == '01' &&
          finish == '${start.substring(0, 8)}${last.toString().padLeft(2, '0')}'
      ? '${_months[m - 1]} $y'
      : '${payslipDay(start)} – ${payslipDay(finish)}';
}

const _ones = [
  'Zero', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', //
  'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen',
  'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen',
];
const _tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];
String _words(int n) {
  if (n < 20) return _ones[n];
  if (n < 100) return '${_tens[n ~/ 10]}${n % 10 > 0 ? ' ${_ones[n % 10]}' : ''}';
  for (final (unit, name) in const [
    (10000000, 'Crore'),
    (100000, 'Lakh'),
    (1000, 'Thousand'),
    (100, 'Hundred'),
  ]) {
    if (n >= unit) {
      return '${_words(n ~/ unit)} $name${n % unit > 0 ? ' ${_words(n % unit)}' : ''}';
    }
  }
  return '';
}

/// "3000050" → "Rupees Thirty Thousand and Fifty Paise Only".
String amountInWords(String paise) {
  final v = int.parse(paise), r = v ~/ 100, p = v % 100;
  return 'Rupees ${_words(r)}${p > 0 ? ' and ${_words(p)} Paise' : ''} Only';
}

const _methods = {
  'bank_transfer': 'Bank transfer',
  'upi': 'UPI',
  'cheque': 'Cheque',
  'cash': 'Cash',
};
const _kinds = {
  'overtime': 'Overtime',
  'bonus': 'Bonus',
  'reimbursement': 'Reimbursement',
  'adjustment': 'Adjustment',
};

/// [design] is the saved design (defaults when none); [p] is the payslip JSON
/// from /payroll/:id/json.
Future<Uint8List> buildPayslipPdf(
  Map<String, dynamic> design,
  Map<String, dynamic> p,
) async {
  pw.Font font(String name) => pw.Font.ttf(_fonts[name]!);
  for (final name in [
    'Manrope-Regular',
    'Manrope-Bold',
    'NotoSansDevanagari-Regular',
  ]) {
    _fonts[name] ??= await rootBundle.load('assets/fonts/$name.ttf');
  }
  final s = Map<String, dynamic>.from(p['snapshot'] as Map),
      show = Map<String, dynamic>.from(design['show'] as Map),
      layout = design['layout'],
      modern = layout == 'modern',
      compact = layout == 'compact',
      accent = PdfColor.fromHex('${design['accent']}'),
      tint = PdfColor(
        accent.red * .1 + .9,
        accent.green * .1 + .9,
        accent.blue * .1 + .9,
      ),
      ink = PdfColor.fromHex('#1C2621'),
      muted = PdfColor.fromHex('#5D6B64'),
      line = PdfColor.fromHex('#DFE5E1'),
      size = compact ? 9.0 : 10.0;
  final lines = (s['lines'] as List)
      .map((l) => Map<String, dynamic>.from(l as Map))
      .toList();
  final earnings = lines.where((l) => l['kind'] != 'deduction').toList(),
      deductions = lines.where((l) => l['kind'] == 'deduction').toList(),
      net = BigInt.parse('${s['netPaise']}'),
      paid = BigInt.parse('${p['paidPaise']}'),
      status = paid <= BigInt.zero
          ? 'Unpaid'
          : paid >= net
          ? 'Paid'
          : 'Partially paid',
      payments = (p['payments'] as List? ?? const [])
          .map((x) => Map<String, dynamic>.from(x as Map))
          .toList();
  String amt(dynamic v) => formatInr(v).replaceFirst('₹', '');
  final logo = design['logo'] == null
      ? null
      : pw.MemoryImage(base64Decode('${design['logo']}'.split(',').last));
  final company = '${design['companyName']}'.isEmpty
      ? '${s['legalEmployer']}'
      : '${design['companyName']}';
  final published = p['publishedOn'] == null
      ? '—'
      : payslipDay('${p['publishedOn']}');
  final details = <(String, String)>[
    ('Employee name', '${s['employeeName']}'),
    if (show['employeeCode'] == true) ('Employee code', '${s['employeeCode']}'),
    if (show['designation'] == true && p['jobTitle'] != null)
      ('Designation', '${p['jobTitle']}'),
    if (show['department'] == true && p['department'] != null)
      ('Department', '${p['department']}'),
    ('Pay period', '${payslipDay(p['start'])} – ${payslipDay(p['finish'])}'),
    if (show['legalEmployer'] == true) ('Employer', '${s['legalEmployer']}'),
    ('Published on', published),
    if (show['revision'] == true) ('Revision', '${p['revision']}'),
  ];
  final cols = compact ? 3 : 2;
  final onBand = modern ? PdfColors.white : ink;
  final header = pw.Container(
    padding: modern ? const pw.EdgeInsets.all(16) : const pw.EdgeInsets.only(bottom: 12),
    decoration: modern
        ? pw.BoxDecoration(color: accent, borderRadius: pw.BorderRadius.circular(6))
        : pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: accent, width: compact ? 1 : 3)),
          ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (logo != null) ...[
          pw.Container(
            height: 44,
            width: 120,
            padding: modern ? const pw.EdgeInsets.all(3) : null,
            color: modern ? PdfColors.white : null,
            child: pw.Image(logo, fit: pw.BoxFit.contain, alignment: pw.Alignment.centerLeft),
          ),
          pw.SizedBox(width: 12),
        ],
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(company, style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: onBand)),
              if ('${design['companyAddress']}'.isNotEmpty)
                pw.Text('${design['companyAddress']}',
                    style: pw.TextStyle(fontSize: 9, color: modern ? PdfColors.grey200 : muted)),
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('${design['title']}'.toUpperCase(),
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: modern ? PdfColors.white : accent)),
            pw.Text(payslipPeriod(p['start'], p['finish']),
                style: pw.TextStyle(fontSize: 9, color: modern ? PdfColors.grey200 : muted)),
          ],
        ),
      ],
    ),
  );
  pw.Widget cell(String text, {bool bold = false, bool right = false, PdfColor? color}) => pw.Padding(
    padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: compact ? 4 : 6),
    child: pw.Text(text,
        textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : null, color: color)),
  );
  String label(Map<String, dynamic> l) {
    final kind = _kinds[l['kind']];
    return kind == null || '${l['label']}'.toLowerCase().contains('${l['kind']}')
        ? '${l['label']}'
        : '${l['label']} ($kind)';
  }

  final rows = [earnings.length, deductions.length, 1].reduce((a, b) => a > b ? a : b);
  final headStyle = modern ? accent : ink;
  final table = pw.Table(
    border: modern || compact
        ? pw.TableBorder(horizontalInside: pw.BorderSide(color: line), bottom: pw.BorderSide(color: line))
        : pw.TableBorder.all(color: line),
    columnWidths: const {
      0: pw.FlexColumnWidth(3),
      1: pw.FlexColumnWidth(2),
      2: pw.FlexColumnWidth(3),
      3: pw.FlexColumnWidth(2),
    },
    children: [
      pw.TableRow(
        decoration: modern || compact ? null : pw.BoxDecoration(color: tint),
        children: [
          cell('EARNINGS', bold: true, color: headStyle),
          cell('AMOUNT (₹)', bold: true, right: true, color: headStyle),
          cell('DEDUCTIONS', bold: true, color: headStyle),
          cell('AMOUNT (₹)', bold: true, right: true, color: headStyle),
        ],
      ),
      for (var i = 0; i < rows; i++)
        pw.TableRow(children: [
          cell(i < earnings.length ? label(earnings[i]) : ''),
          cell(i < earnings.length ? amt(earnings[i]['calculatedPaise']) : '', right: true),
          cell(i < deductions.length ? label(deductions[i]) : ''),
          cell(i < deductions.length ? amt(deductions[i]['calculatedPaise']) : '', right: true),
        ]),
      pw.TableRow(
        decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F7F9F8')),
        children: [
          cell('Gross earnings', bold: true),
          cell(amt(s['grossPaise']), bold: true, right: true),
          cell('Total deductions', bold: true),
          cell(amt(s['deductionPaise']), bold: true, right: true),
        ],
      ),
    ],
  );
  final onNet = modern ? PdfColors.white : ink;
  final netBox = pw.Container(
    margin: const pw.EdgeInsets.only(top: 14, bottom: 4),
    padding: pw.EdgeInsets.symmetric(horizontal: 14, vertical: compact ? 7 : 11),
    decoration: pw.BoxDecoration(
      color: modern ? accent : null,
      border: modern ? null : pw.Border.all(color: accent, width: compact ? 1 : 2),
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Row(children: [
      pw.Text('Net pay  ', style: pw.TextStyle(color: onNet)),
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: pw.BoxDecoration(
          color: modern ? PdfColors.white : tint,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Text(status, style: pw.TextStyle(fontSize: 8, color: accent, fontWeight: pw.FontWeight.bold)),
      ),
      pw.Spacer(),
      pw.Text('₹${amt(s['netPaise'])}',
          style: pw.TextStyle(fontSize: compact ? 15 : 18, fontWeight: pw.FontWeight.bold, color: modern ? PdfColors.white : accent)),
    ]),
  );
  final doc = pw.Document(title: '${design['title']} · ${s['employeeName']}');
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.copyWith(
        marginLeft: 36, marginRight: 36, marginTop: 36, marginBottom: 36,
      ),
      theme: pw.ThemeData.withFont(
        base: font('Manrope-Regular'),
        bold: font('Manrope-Bold'),
        fontFallback: [font('NotoSansDevanagari-Regular')],
      ).copyWith(defaultTextStyle: pw.TextStyle(fontSize: size, color: ink)),
      build: (_) => [
        header,
        pw.SizedBox(height: 12),
        pw.Table(children: [
          for (var i = 0; i < details.length; i += cols)
            pw.TableRow(children: [
              for (var j = i; j < i + cols; j++)
                j < details.length
                    ? pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 6, right: 12),
                        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                          pw.Text(details[j].$1, style: pw.TextStyle(fontSize: 8, color: muted)),
                          pw.Text(details[j].$2, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ]),
                      )
                    : pw.SizedBox(),
            ]),
        ]),
        pw.SizedBox(height: 8),
        table,
        netBox,
        if (show['amountInWords'] == true)
          pw.Text(amountInWords('${s['netPaise']}'),
              style: pw.TextStyle(color: muted)),
        if (show['payments'] == true && payments.isNotEmpty) ...[
          pw.SizedBox(height: 14),
          pw.Text('Payments recorded', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder(horizontalInside: pw.BorderSide(color: line), bottom: pw.BorderSide(color: line)),
            children: [
              pw.TableRow(children: [
                cell('Date', bold: true),
                cell('Method', bold: true),
                cell('Reference', bold: true),
                cell('Amount (₹)', bold: true, right: true),
              ]),
              for (final x in payments)
                pw.TableRow(children: [
                  cell(payslipDay('${x['paidOn']}')),
                  cell('${_methods[x['method']] ?? x['method']}${x['kind'] == 'reversal' ? ' (reversed)' : ''}'),
                  cell('${x['reference']}'),
                  cell('${x['kind'] == 'reversal' ? '-' : ''}${amt(x['paise'])}', right: true),
                ]),
            ],
          ),
        ],
        if (show['notes'] == true && '${s['assumptions'] ?? ''}'.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          pw.Text('${s['assumptions']}${s['policyVersion'] == null ? '' : ' · Policy ${s['policyVersion']}'}',
              style: pw.TextStyle(fontSize: 8, color: muted)),
        ],
        if (show['signature'] == true)
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 170,
              margin: const pw.EdgeInsets.only(top: 34),
              padding: const pw.EdgeInsets.only(top: 4),
              decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: ink))),
              child: pw.Column(children: [
                pw.Text('${design['signatory']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('${design['signatoryTitle']}', style: pw.TextStyle(fontSize: 9, color: muted)),
              ]),
            ),
          ),
        pw.SizedBox(height: 18),
        pw.Divider(color: line),
        if ('${design['footer']}'.isNotEmpty)
          pw.Text('${design['footer']}', style: pw.TextStyle(fontSize: 8, color: muted)),
        pw.Text(
          'Ref ${p['id']} · Payments are recorded by the payroll team after they are made; this app does not transfer money. Saved copies cannot be remotely revoked.',
          style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
        ),
      ],
    ),
  );
  return doc.save();
}

final _fonts = <String, ByteData>{};
