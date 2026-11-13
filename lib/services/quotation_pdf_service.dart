import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/business.dart';
import '../models/quotation.dart';

class QuotationPdfService {
  static const PdfColor navy = PdfColor.fromInt(0xFF29486F);
  static const PdfColor pale = PdfColor.fromInt(0xFFEAF0F8);
  static const PdfColor grey = PdfColor.fromInt(0xFFF3F5F8);

  Future<Uint8List> build({
    required Business business,
    required Quotation quote,
  }) async {
    final pdf = pw.Document();

    final dateFormat = DateFormat('dd/MM/yyyy');
    final moneyFormat = NumberFormat('#,##0.00');

    String cash(double value) {
      return '${quote.currency} ${moneyFormat.format(value)}';
    }

    pw.Widget sectionBar(String title) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(8),
        color: navy,
        child: pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            color: PdfColors.white,
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );
    }

    pw.Widget informationBox(
      String title,
      List<String> lines,
    ) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(9),
        color: pale,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title.toUpperCase(),
              style: pw.TextStyle(
                color: navy,
                fontSize: 8,
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
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ),
                ),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(
          34,
          32,
          34,
          38,
        ),
        footer: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 7),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(
                  color: PdfColors.grey300,
                ),
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
            // COMPANY HEADER
            pw.Container(
              color: grey,
              padding: const pw.EdgeInsets.all(14),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment:
                          pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          business.name,
                          style: pw.TextStyle(
                            fontSize: 17,
                            fontWeight: pw.FontWeight.bold,
                            color: navy,
                          ),
                        ),
                        if (business.website.isNotEmpty)
                          pw.Text(
                            business.website,
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey700,
                            ),
                          ),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment:
                        pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'QUOTATION',
                        style: pw.TextStyle(
                          fontSize: 21,
                          fontWeight: pw.FontWeight.bold,
                          color: navy,
                        ),
                      ),
                      pw.Text(
                        '${quote.quotationNumber}  |  '
                        '${dateFormat.format(quote.issueDate)}',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // COMPANY CONTACT DETAILS
            pw.Container(
              width: double.infinity,
              color: PdfColors.grey300,
              padding: const pw.EdgeInsets.all(7),
              child: pw.Text(
                [
                  business.email,
                  business.phone,
                  business.address,
                ].where((value) => value.isNotEmpty).join('  |  '),
                style: const pw.TextStyle(
                  fontSize: 7,
                  color: PdfColors.grey700,
                ),
              ),
            ),

            if (business.taxRegistrationNumber.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 5),
                child: pw.Text(
                  'TIN: ${business.taxRegistrationNumber}',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),

            pw.SizedBox(height: 12),

            // FROM / CUSTOMER / QUOTATION DETAILS
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.grey300,
                width: 0.5,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1),
              },
              children: [
                pw.TableRow(
                  children: [
                    informationBox(
                      'From',
                      [
                        business.name,
                        business.address,
                        business.email,
                        business.phone,
                      ],
                    ),
                    informationBox(
                      'Quote to',
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
                    informationBox(
                      'Quote details',
                      [
                        'Quote No: ${quote.quotationNumber}',
                        'Date: ${dateFormat.format(quote.issueDate)}',
                        'Valid until: ${dateFormat.format(quote.validUntil)}',
                        'Project: ${quote.projectName}',
                      ],
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 12),

            // DESCRIPTION OF WORKS
            sectionBar('Description of works'),

            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Text(
                quote.description.isEmpty
                    ? quote.projectName
                    : quote.description,
                style: const pw.TextStyle(
                  fontSize: 9,
                  lineSpacing: 2,
                ),
              ),
            ),

            // LINE ITEMS
            sectionBar('Line items'),

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
              headerDecoration: const pw.BoxDecoration(
                color: navy,
              ),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(fontSize: 7.5),
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
              oddRowDecoration: const pw.BoxDecoration(
                color: grey,
              ),
              cellPadding: const pw.EdgeInsets.all(6),
            ),

            pw.SizedBox(height: 8),

            // TOTALS
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 245,
                child: pw.Column(
                  children: [
                    _totalRow(
                      'Subtotal',
                      cash(quote.directCost),
                    ),
                    if (quote.markupPercent > 0)
                      _totalRow(
                        'Markup (${quote.markupPercent}%)',
                        cash(quote.markupAmount),
                      ),
                    if (quote.discount > 0)
                      _totalRow(
                        'Discount',
                        '- ${cash(quote.discount)}',
                      ),
                    _totalRow(
                      'Subtotal before tax',
                      cash(quote.subtotal),
                    ),
                    _totalRow(
                      'Tax (${quote.taxPercent}%)',
                      cash(quote.taxAmount),
                    ),
                    pw.Container(
                      color: navy,
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Row(
                        mainAxisAlignment:
                            pw.MainAxisAlignment.spaceBetween,
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

            // NOTES
            if (quote.notes.isNotEmpty) ...[
              pw.SizedBox(height: 12),
              sectionBar('Additional notes'),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 7),
                child: pw.Text(
                  quote.notes,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
            ],

            // TERMS
            pw.SizedBox(height: 12),
            sectionBar('Terms & conditions'),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 7),
              child: pw.Text(
                quote.termsAndConditions,
                style: const pw.TextStyle(
                  fontSize: 8,
                  lineSpacing: 2,
                ),
              ),
            ),

            // ACCEPTANCE
            pw.SizedBox(height: 12),
            sectionBar('Acceptance'),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 7),
              child: pw.Text(
                'By accepting this quotation, the customer confirms '
                'agreement with the scope, pricing and terms stated above.',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ),

            pw.SizedBox(height: 22),

            // SIGNATURES
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment:
                        pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        height: 22,
                        width: 190,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(
                              color: PdfColors.grey700,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Customer signature / Date',
                        style: const pw.TextStyle(fontSize: 7),
                      ),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment:
                        pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        height: 22,
                        width: 190,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(
                              color: PdfColors.grey700,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'For ${business.name}',
                        style: const pw.TextStyle(fontSize: 7),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _totalRow(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(
        horizontal: 7,
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
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 7.5),
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
}