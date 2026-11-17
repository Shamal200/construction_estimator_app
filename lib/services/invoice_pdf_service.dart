
import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/business.dart';
import '../models/customer.dart';
import '../models/invoice.dart';

class InvoicePdfService {
  static const String defaultTemplateId = 'standard_blue';

  static const Map<String, List<int>> _palettes = {
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
    required Customer customer,
    required Invoice invoice,
    String templateId = defaultTemplateId,
  }) async {
    final palette = _palettes[templateId] ??
        _palettes[defaultTemplateId]!;

    final primary = PdfColor.fromInt(palette[0]);
    final pale = PdfColor.fromInt(palette[1]);
    final accent = PdfColor.fromInt(palette[2]);

    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final moneyFormat = NumberFormat('#,##0.00');

    String cash(double value) =>
        '${invoice.currency} ${moneyFormat.format(value)}';

    Uint8List? logoBytes;

    try {
      if (business.logoBase64.isNotEmpty) {
        logoBytes = base64Decode(business.logoBase64);
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

    pw.Widget bankCell(String label, String value) {
      if (value.trim().isEmpty) return pw.SizedBox();

      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6, right: 8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 6.5,
                color: primary,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 7.5),
            ),
          ],
        ),
      );
    }

    pw.Widget bankDetails() {
      final hasBankDetails = [
        business.bankName,
        business.bankAccountName,
        business.bankAccountNumber,
        business.bankBranch,
        business.bankBranchCode,
      ].any((value) => value.trim().isNotEmpty);

      if (!hasBankDetails) return pw.SizedBox();

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
              'BANK DETAILS FOR PAYMENT',
              style: pw.TextStyle(
                color: primary,
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      bankCell('BANK NAME', business.bankName),
                      bankCell(
                        'ACCOUNT NUMBER',
                        business.bankAccountNumber,
                      ),
                      bankCell(
                        'BRANCH CODE',
                        business.bankBranchCode,
                      ),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      bankCell(
                        'ACCOUNT NAME',
                        business.bankAccountName,
                      ),
                      bankCell('BRANCH', business.bankBranch),
                    ],
                  ),
                ),
              ],
            ),
            if (business.paymentInstructions.trim().isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                business.paymentInstructions,
                style: const pw.TextStyle(
                  fontSize: 7,
                  color: PdfColors.grey700,
                ),
              ),
            ],
            pw.SizedBox(height: 5),
            pw.Text(
              'Please use invoice number ${invoice.invoiceNumber} '
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
                  'INVOICE ${invoice.invoiceNumber}',
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
                  '${invoice.invoiceNumber}  |  '
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
                        'INVOICE',
                        style: pw.TextStyle(
                          fontSize: 19,
                          fontWeight: pw.FontWeight.bold,
                          color: primary,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        invoice.invoiceNumber,
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: accent,
                        ),
                      ),
                      pw.Text(
                        dateFormat.format(invoice.issueDate),
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
                      'Bill to',
                      [
                        customer.fullName,
                        customer.companyName,
                        customer.address,
                        customer.email,
                        customer.phoneNumber,
                        if (customer.customerNumber.isNotEmpty)
                          'Customer No: ${customer.customerNumber}',
                      ],
                    ),
                    infoBox(
                      'Invoice details',
                      [
                        'Invoice: ${invoice.invoiceNumber}',
                        'Issue date: ${dateFormat.format(invoice.issueDate)}',
                        'Due date: ${dateFormat.format(invoice.dueDate)}',
                        if (invoice.projectName.isNotEmpty)
                          'Project: ${invoice.projectName}',
                        if (invoice.quotationNumber.isNotEmpty)
                          'Quotation: ${invoice.quotationNumber}',
                      ],
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 12),

            sectionTitle('Invoice items'),
            pw.SizedBox(height: 5),

            pw.TableHelper.fromTextArray(
              headers: [
                'DESCRIPTION',
                'QTY',
                'UNIT',
                'UNIT RATE',
                'TOTAL',
              ],
              data: invoice.items.map((item) {
                return [
                  item.name +
                      (item.description.trim().isEmpty
                          ? ''
                          : '\n${item.description}'),
                  item.quantity.toStringAsFixed(
                    item.quantity % 1 == 0 ? 0 : 2,
                  ),
                  item.unit,
                  cash(item.unitRate),
                  cash(item.total),
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

            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 245,
                child: pw.Column(
                  children: [
                    totalRow('Subtotal', cash(invoice.subtotal)),
                    if (invoice.discount > 0)
                      totalRow(
                        'Discount',
                        '- ${cash(invoice.discount)}',
                      ),
                    totalRow('Tax', cash(invoice.tax)),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(9),
                      color: primary,
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'TOTAL',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            cash(invoice.total),
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    totalRow('Amount paid', cash(invoice.amountPaid)),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(9),
                      decoration: pw.BoxDecoration(
                        color: pale,
                        border: pw.Border.all(color: accent, width: 0.8),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'BALANCE DUE',
                            style: pw.TextStyle(
                              color: primary,
                              fontSize: 8.5,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            cash(invoice.balance),
                            style: pw.TextStyle(
                              color: primary,
                              fontSize: 9,
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

            pw.SizedBox(height: 14),

            sectionTitle('Payment information'),
            pw.SizedBox(height: 7),
            bankDetails(),

            pw.SizedBox(height: 12),

            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(9),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: PdfColors.grey300,
                  width: 0.5,
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Thank you for your business.',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: primary,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Please contact us if you have any questions '
                    'regarding this invoice.',
                    style: const pw.TextStyle(
                      fontSize: 7.5,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
