
import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/business.dart';
import '../models/quotation.dart';

class QuotationPdfService {
  static const String defaultTemplateId = 'standard_blue';

  static const List<Map<String, String>> templates = [
    {'id': 'minimal', 'name': 'Minimal', 'category': 'free'},
    {'id': 'standard_blue', 'name': 'Standard Blue', 'category': 'free'},
    {'id': 'modern_green', 'name': 'Modern Green', 'category': 'free'},
    {'id': 'navy_gold', 'name': 'Navy & Gold', 'category': 'pro'},
    {'id': 'professional_grey', 'name': 'Professional Grey', 'category': 'pro'},
    {'id': 'elegant_teal', 'name': 'Elegant Teal', 'category': 'pro'},
    {'id': 'modern_orange', 'name': 'Modern Orange', 'category': 'pro'},
    {'id': 'dark_premium', 'name': 'Dark Premium', 'category': 'pro'},
    {'id': 'construction', 'name': 'Construction', 'category': 'pro'},
    {'id': 'professional_red', 'name': 'Professional Red', 'category': 'pro'},
  ];

  static const Map<String, List<int>> _paletteValues = {
    'minimal': [0xFF333333, 0xFFF3F3F3, 0xFF666666],
    'standard_blue': [0xFF29486F, 0xFFEAF0F8, 0xFF547AA5],
    'modern_green': [0xFF236B50, 0xFFE9F4EF, 0xFF579477],
    'navy_gold': [0xFF172B4D, 0xFFF5F0E5, 0xFFC49A45],
    'professional_grey': [0xFF454B54, 0xFFEDEFF2, 0xFF858D98],
    'elegant_teal': [0xFF087E83, 0xFFE7F4F3, 0xFF48A6A3],
    'modern_orange': [0xFFB85C18, 0xFFFFF1E5, 0xFFE28A43],
    'dark_premium': [0xFF252525, 0xFFECECEC, 0xFF777777],
    'construction': [0xFF263746, 0xFFFFF1D6, 0xFFE3A52B],
    'professional_red': [0xFF9E3038, 0xFFF9EDEF, 0xFFD36A70],
  };

  Future<Uint8List> build({
    required Business business,
    required Quotation quote,
    String templateId = defaultTemplateId,
  }) async {
    final selectedId = _paletteValues.containsKey(templateId)
        ? templateId
        : 'standard_blue';

    final values = _paletteValues[selectedId]!;
    final primary = PdfColor.fromInt(values[0]);
    final pale = PdfColor.fromInt(values[1]);
    final accent = PdfColor.fromInt(values[2]);

    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final moneyFormat = NumberFormat('#,##0.00');

    String cash(double value) =>
        '${quote.currency} ${moneyFormat.format(value)}';

    Uint8List? logoBytes;

    // The logo is read from the business profile.
    // It will be connected to the company settings in Step 2.
    try {
      final encodedLogo = business.logoBase64;
      if (encodedLogo.isNotEmpty) {
        logoBytes = base64Decode(encodedLogo);
      }
    } catch (_) {
      logoBytes = null;
    }

    pw.Widget sectionTitle(String title) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(
          horizontal: 9,
          vertical: 7,
        ),
        decoration: pw.BoxDecoration(
          color: primary,
          border: pw.Border(
            left: pw.BorderSide(color: accent, width: 3),
          ),
        ),
        child: pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            color: PdfColors.white,
            fontSize: 8.5,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );
    }

    pw.Widget infoBox(String title, List<String> lines) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(9),
        decoration: pw.BoxDecoration(
          color: pale,
          border: pw.Border.all(
            color: PdfColors.grey300,
            width: 0.5,
          ),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title.toUpperCase(),
              style: pw.TextStyle(
                color: primary,
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            ...lines
                .where((line) => line.trim().isNotEmpty)
                .map(
                  (line) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 3),
                    child: pw.Text(
                      line,
                      style: const pw.TextStyle(fontSize: 7.5),
                    ),
                  ),
                ),
          ],
        ),
      );
    }

    pw.Widget totalRow(String label, String value) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 5,
        ),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            left: pw.BorderSide(color: PdfColors.grey300),
            right: pw.BorderSide(color: PdfColors.grey300),
            bottom: pw.BorderSide(color: PdfColors.grey300),
          ),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Text(
                label,
                style: const pw.TextStyle(fontSize: 7.5),
              ),
            ),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget bankDetails() {
      final bankName = business.bankName;
      final accountName = business.bankAccountName;
      final accountNumber = business.bankAccountNumber;
      final branch = business.bankBranch;
      final branchCode = business.bankBranchCode;
      final instructions = business.paymentInstructions;

      final hasBankDetails = [
        bankName,
        accountName,
        accountNumber,
        branch,
        branchCode,
      ].any((value) => value.trim().isNotEmpty);

      if (!hasBankDetails) {
        return pw.SizedBox();
      }

      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: pale,
          border: pw.Border.all(color: accent, width: 0.8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'BANK DETAILS FOR DEPOSIT PAYMENT',
              style: pw.TextStyle(
                color: primary,
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  children: [
                    _bankCell('BANK NAME', bankName),
                    _bankCell('ACCOUNT NAME', accountName),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _bankCell('ACCOUNT NUMBER', accountNumber),
                    _bankCell('BRANCH', branch),
                  ],
                ),
                if (branchCode.isNotEmpty)
                  pw.TableRow(
                    children: [
                      _bankCell('BRANCH CODE', branchCode),
                      pw.SizedBox(),
                    ],
                  ),
              ],
            ),
            if (instructions.isNotEmpty) ...[
              pw.SizedBox(height: 6),
              pw.Text(
                instructions,
                style: const pw.TextStyle(
                  fontSize: 7,
                  color: PdfColors.grey700,
                ),
              ),
            ],
            pw.SizedBox(height: 5),
            pw.Text(
              'Please use quotation number ${quote.quotationNumber} '
              'as your payment reference.',
              style: pw.TextStyle(
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
                color: primary,
              ),
            ),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(34, 35, 34, 42),
        maxPages: 100,
        header: (context) {
          // Small continuation header on pages after the first.
          if (context.pageNumber == 1) {
            return pw.SizedBox();
          }

          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.only(bottom: 7),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: accent, width: 1.5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  business.name,
                  style: pw.TextStyle(
                    color: primary,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'QUOTATION ${quote.quotationNumber}',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          );
        },
        footer: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 7),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: accent, width: 0.8),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  business.name,
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Text(
                  '${quote.quotationNumber}  |  '
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(
                    fontSize: 7,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          );
        },
        build: (context) {
          return [
            // FIRST PAGE COMPANY HEADER
            pw.Container(
              padding: const pw.EdgeInsets.all(13),
              decoration: pw.BoxDecoration(
                color: pale,
                border: pw.Border(
                  bottom: pw.BorderSide(color: accent, width: 3),
                ),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoBytes != null)
                    pw.Container(
                      width: 65,
                      height: 58,
                      margin: const pw.EdgeInsets.only(right: 12),
                      child: pw.Image(
                        pw.MemoryImage(logoBytes),
                        fit: pw.BoxFit.contain,
                      ),
                    )
                  else
                    pw.Container(
                      width: 65,
                      height: 58,
                      margin: const pw.EdgeInsets.only(right: 12),
                      alignment: pw.Alignment.center,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: accent),
                      ),
                      child: pw.Text(
                        business.name.isEmpty
                            ? 'LOGO'
                            : business.name
                                .split(' ')
                                .where((part) => part.isNotEmpty)
                                .take(2)
                                .map((part) => part[0].toUpperCase())
                                .join(),
                        style: pw.TextStyle(
                          color: primary,
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          business.name,
                          style: pw.TextStyle(
                            fontSize: 15,
                            fontWeight: pw.FontWeight.bold,
                            color: primary,
                          ),
                        ),
                        if (business.website.isNotEmpty)
                          pw.Text(
                            business.website,
                            style: const pw.TextStyle(
                              fontSize: 7,
                              color: PdfColors.grey700,
                            ),
                          ),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'QUOTATION',
                        style: pw.TextStyle(
                          fontSize: 19,
                          fontWeight: pw.FontWeight.bold,
                          color: primary,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        quote.quotationNumber,
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: accent,
                        ),
                      ),
                      pw.Text(
                        dateFormat.format(quote.issueDate),
                        style: const pw.TextStyle(fontSize: 7),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(7),
              color: primary,
              child: pw.Text(
                [
                  business.address,
                  business.phone,
                  business.email,
                  if (business.taxRegistrationNumber.isNotEmpty)
                    'TIN: ${business.taxRegistrationNumber}',
                ].where((value) => value.trim().isNotEmpty).join('  |  '),
                style: const pw.TextStyle(
                  fontSize: 7,
                  color: PdfColors.white,
                ),
              ),
            ),

            pw.SizedBox(height: 12),

            // CUSTOMER AND QUOTATION INFORMATION
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.grey300,
                width: 0.5,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  children: [
                    infoBox(
                      'Quotation prepared for',
                      [
                        quote.customerName,
                        quote.customerCompany,
                        quote.customerAddress,
                        quote.customerEmail,
                        quote.customerPhone,
                        if (quote.customerNumber.isNotEmpty)
                          'Customer No: ${quote.customerNumber}',
                      ],
                    ),
                    infoBox(
                      'Quotation details',
                      [
                        'Quotation: ${quote.quotationNumber}',
                        'Issue date: ${dateFormat.format(quote.issueDate)}',
                        'Valid until: ${dateFormat.format(quote.validUntil)}',
                        'Project: ${quote.projectName}',
                        if (quote.projectAddress.isNotEmpty)
                          'Site: ${quote.projectAddress}',
                      ],
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 12),

            sectionTitle('Description of works'),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 9),
              child: pw.Text(
                quote.description.isEmpty
                    ? quote.projectName
                    : quote.description,
                style: const pw.TextStyle(
                  fontSize: 8.5,
                  lineSpacing: 2,
                ),
              ),
            ),

            sectionTitle('Quotation items'),
            pw.SizedBox(height: 5),

            // MultiPage automatically continues this table.
            // The table header repeats when it continues to another page.
            pw.TableHelper.fromTextArray(
              headers: [
                'DESCRIPTION',
                'QTY',
                'UNIT',
                'UNIT RATE',
                'TOTAL',
              ],
              data: quote.items.map((item) {
                return [
                  item.name +
                      (item.description.isEmpty
                          ? ''
                          : '\n${item.description}'),
                  item.quantity.toStringAsFixed(
                    item.quantity % 1 == 0 ? 0 : 2,
                  ),
                  item.unit,
                  cash(item.unitRate),
                  cash(item.directCost),
                ];
              }).toList(),
              headerCount: 1,
              headerDecoration: pw.BoxDecoration(color: primary),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(fontSize: 7.2),
              cellAlignments: {
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
              },
              border: pw.TableBorder.all(
                color: PdfColors.grey300,
                width: 0.5,
              ),
              oddRowDecoration: pw.BoxDecoration(color: pale),
              cellPadding: const pw.EdgeInsets.all(6),
            ),

            pw.SizedBox(height: 10),

            // TOTALS
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 245,
                child: pw.Column(
                  children: [
                    totalRow('Direct cost', cash(quote.directCost)),
                    if (quote.markupPercent > 0)
                      totalRow(
                        'Markup (${quote.markupPercent}%)',
                        cash(quote.markupAmount),
                      ),
                    if (quote.discount > 0)
                      totalRow('Discount', '- ${cash(quote.discount)}'),
                    totalRow('Subtotal', cash(quote.subtotal)),
                    totalRow(
                      'Tax (${quote.taxPercent}%)',
                      cash(quote.taxAmount),
                    ),
                    pw.Container(
                      color: primary,
                      padding: const pw.EdgeInsets.all(9),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'TOTAL DUE',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            cash(quote.grandTotal),
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (quote.notes.trim().isNotEmpty) ...[
              pw.SizedBox(height: 13),
              sectionTitle('Additional notes'),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Text(
                  quote.notes,
                  style: const pw.TextStyle(
                    fontSize: 8,
                    lineSpacing: 2,
                  ),
                ),
              ),
            ],

            pw.SizedBox(height: 13),
            sectionTitle('Terms and conditions'),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Text(
                quote.termsAndConditions,
                style: const pw.TextStyle(
                  fontSize: 8,
                  lineSpacing: 2,
                ),
              ),
            ),

            pw.SizedBox(height: 13),
            sectionTitle('Bank details for deposit payment'),
            pw.SizedBox(height: 7),
            bankDetails(),

            pw.SizedBox(height: 13),
            sectionTitle('Acceptance'),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Text(
                'By accepting this quotation, the customer confirms '
                'agreement with the scope of works, pricing and terms '
                'stated in this document.',
                style: const pw.TextStyle(
                  fontSize: 8,
                  lineSpacing: 2,
                ),
              ),
            ),

            // Keep the signature area together where possible.
            pw.Container(
              padding: const pw.EdgeInsets.only(top: 12),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: _signatureBox('Customer signature / Date'),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    child: _signatureBox('For ${business.name}'),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 16),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(9),
              color: pale,
              child: pw.Text(
                'Thank you for the opportunity to provide this quotation.',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  color: primary,
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _bankCell(String label, String value) {
    if (value.trim().isEmpty) {
      return pw.SizedBox();
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7, right: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 6.5,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _signatureBox(String label) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          height: 27,
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey700),
            ),
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 7),
        ),
      ],
    );
  }
}