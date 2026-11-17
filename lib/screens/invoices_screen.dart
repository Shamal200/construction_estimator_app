
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../core/utils/currency_formatter.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../providers/auth_provider.dart';
import '../services/invoice_pdf_service.dart';
import '../services/invoice_service.dart';

class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({super.key});

  static const List<Map<String, String>> _templates = [
    {'id': 'minimal', 'name': 'Minimal', 'category': 'Free'},
    {'id': 'standard_blue', 'name': 'Standard Blue', 'category': 'Free'},
    {'id': 'modern_green', 'name': 'Modern Green', 'category': 'Free'},
    {'id': 'navy_gold', 'name': 'Navy & Gold', 'category': 'Pro'},
    {'id': 'professional_grey', 'name': 'Professional Grey', 'category': 'Pro'},
    {'id': 'elegant_teal', 'name': 'Elegant Teal', 'category': 'Pro'},
    {'id': 'modern_orange', 'name': 'Modern Orange', 'category': 'Pro'},
    {'id': 'dark_premium', 'name': 'Dark Premium', 'category': 'Pro'},
    {'id': 'construction', 'name': 'Construction', 'category': 'Pro'},
    {'id': 'professional_red', 'name': 'Professional Red', 'category': 'Pro'},
  ];

  Future<String?> _selectTemplate(
    BuildContext context,
    String defaultTemplate,
  ) async {
    var selectedTemplate = _templates.any(
      (template) => template['id'] == defaultTemplate,
    )
        ? defaultTemplate
        : InvoicePdfService.defaultTemplateId;

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Choose invoice template'),
            content: SizedBox(
              width: 350,
              child: DropdownButtonFormField<String>(
                value: selectedTemplate,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'PDF template',
                  border: OutlineInputBorder(),
                ),
                items: _templates.map((template) {
                  return DropdownMenuItem<String>(
                    value: template['id'],
                    child: Text(
                      '${template['name']} (${template['category']})',
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      selectedTemplate = value;
                    });
                  }
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(dialogContext, selectedTemplate);
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Generate PDF'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _generatePdf(
    BuildContext context,
    dynamic business,
    Invoice invoice,
  ) async {
    try {
      final selectedTemplate = await _selectTemplate(
        context,
        business.defaultQuotationTemplate,
      );

      if (selectedTemplate == null || !context.mounted) return;

      final customerSnapshot = await FirebaseFirestore.instance
          .collection('businesses')
          .doc(business.id)
          .collection('customers')
          .doc(invoice.customerId)
          .get();

      if (!customerSnapshot.exists) {
        throw Exception(
          'Customer information could not be found. '
          'Please check the customer record.',
        );
      }

      final customer = Customer.fromMap(customerSnapshot.data()!);

      final pdfService = InvoicePdfService();

      final pdfBytes = await pdfService.build(
        business: business,
        customer: customer,
        invoice: invoice,
        templateId: selectedTemplate,
      );

      if (!context.mounted) return;

      await Printing.layoutPdf(
        name: '${invoice.invoiceNumber}.pdf',
        onLayout: (_) async => pdfBytes,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Invoice PDF generation failed: $e'),
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final business =
        context.watch<AuthProvider>().activeBusiness;

    if (business == null) {
      return const Center(
        child: Text('Please select a business.'),
      );
    }

    final service = InvoiceService();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invoices',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 7),
          const Text(
            'View invoices, generate PDFs, track payments and manage outstanding balances.',
          ),
          const SizedBox(height: 18),
          Expanded(
            child: StreamBuilder<List<Invoice>>(
              stream: service.watchInvoices(business.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Unable to load invoices.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final invoices = snapshot.data ?? [];

                if (invoices.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 58,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No invoices yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Convert a quotation to create your first invoice.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: invoices.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final invoice = invoices[index];

                    return Card(
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFEAF0F8),
                          child: Icon(
                            Icons.receipt_long_outlined,
                            color: Color(0xFF29486F),
                          ),
                        ),
                        title: Text(
                          invoice.invoiceNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(invoice.projectName),
                              const SizedBox(height: 4),
                              Text(
                                'Total: ${CurrencyFormatter.format(
                                  invoice.total,
                                  currency: invoice.currency,
                                )}',
                              ),
                              Text(
                                'Balance: ${CurrencyFormatter.format(
                                  invoice.balance,
                                  currency: invoice.currency,
                                )}',
                              ),
                              const SizedBox(height: 6),
                              _StatusLabel(
                                status: invoice.status,
                              ),
                            ],
                          ),
                        ),
                        trailing: Wrap(
                          spacing: 0,
                          children: [
                            IconButton(
                              tooltip: 'Generate invoice PDF',
                              onPressed: () => _generatePdf(
                                context,
                                business,
                                invoice,
                              ),
                              icon: const Icon(
                                Icons.picture_as_pdf_outlined,
                              ),
                            ),
                            IconButton(
                              tooltip: 'View invoice details',
                              onPressed: () => _showInvoiceDetails(
                                context,
                                invoice,
                              ),
                              icon: const Icon(
                                Icons.chevron_right,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showInvoiceDetails(
    BuildContext context,
    Invoice invoice,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(invoice.invoiceNumber),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detail('Project', invoice.projectName),
              _detail('Invoice status', invoice.status.name),
              _detail(
                'Issue date',
                _formatDate(invoice.issueDate),
              ),
              _detail(
                'Due date',
                _formatDate(invoice.dueDate),
              ),
              const Divider(height: 24),
              const Text(
                'Invoice items',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...invoice.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${item.quantity} ${item.unit} × '
                        '${CurrencyFormatter.format(
                          item.unitRate,
                          currency: invoice.currency,
                        )}',
                      ),
                      Text(
                        CurrencyFormatter.format(
                          item.total,
                          currency: invoice.currency,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 24),
              _detail(
                'Subtotal',
                CurrencyFormatter.format(
                  invoice.subtotal,
                  currency: invoice.currency,
                ),
              ),
              _detail(
                'Discount',
                CurrencyFormatter.format(
                  invoice.discount,
                  currency: invoice.currency,
                ),
              ),
              _detail(
                'Tax',
                CurrencyFormatter.format(
                  invoice.tax,
                  currency: invoice.currency,
                ),
              ),
              _detail(
                'Total',
                CurrencyFormatter.format(
                  invoice.total,
                  currency: invoice.currency,
                ),
              ),
              _detail(
                'Amount paid',
                CurrencyFormatter.format(
                  invoice.amountPaid,
                  currency: invoice.currency,
                ),
              ),
              _detail(
                'Outstanding balance',
                CurrencyFormatter.format(
                  invoice.balance,
                  currency: invoice.currency,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _StatusLabel extends StatelessWidget {
  final InvoiceStatus status;

  const _StatusLabel({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      InvoiceStatus.draft => 'Draft',
      InvoiceStatus.sent => 'Sent / Unpaid',
      InvoiceStatus.partiallyPaid => 'Partially Paid',
      InvoiceStatus.paid => 'Paid',
      InvoiceStatus.overdue => 'Overdue',
    };

    final color = switch (status) {
      InvoiceStatus.draft => Colors.blueGrey,
      InvoiceStatus.sent => Colors.orange,
      InvoiceStatus.partiallyPaid => Colors.deepOrange,
      InvoiceStatus.paid => Colors.green,
      InvoiceStatus.overdue => Colors.red,
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
