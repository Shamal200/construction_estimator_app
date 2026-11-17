
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
                initialValue: selectedTemplate,
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

      final pdfBytes = await InvoicePdfService().build(
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

  Future<double?> _enterPartialPayment(
    BuildContext context,
    Invoice invoice,
  ) async {
    final controller = TextEditingController(
      text: invoice.amountPaid > 0
          ? invoice.amountPaid.toStringAsFixed(2)
          : '',
    );

    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        String? errorText;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Record partial payment'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Invoice total: ${CurrencyFormatter.format(
                    invoice.total,
                    currency: invoice.currency,
                  )}'),
                  const SizedBox(height: 6),
                  Text('Already paid: ${CurrencyFormatter.format(
                    invoice.amountPaid,
                    currency: invoice.currency,
                  )}'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Total amount received',
                      prefixText: '${invoice.currency} ',
                      border: const OutlineInputBorder(),
                      errorText: errorText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Enter the total amount received so far, '
                    'including any previous payments.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final amount = double.tryParse(
                      controller.text.trim().replaceAll(',', ''),
                    );

                    if (amount == null || amount <= 0) {
                      setDialogState(() {
                        errorText = 'Enter a valid payment amount.';
                      });
                      return;
                    }

                    if (amount >= invoice.total) {
                      setDialogState(() {
                        errorText =
                            'For full payment, select Paid instead.';
                      });
                      return;
                    }

                    Navigator.pop(dialogContext, amount);
                  },
                  child: const Text('Save payment'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    return result;
  }

  Future<void> _changePaymentStatus(
    BuildContext context,
    InvoiceService service,
    String businessId,
    Invoice invoice,
    InvoiceStatus? newStatus,
  ) async {
    if (newStatus == null || newStatus == invoice.status) return;

    double amountPaid;

    switch (newStatus) {
      case InvoiceStatus.unpaid:
        amountPaid = 0;
        break;

      case InvoiceStatus.paid:
        amountPaid = invoice.total;
        break;

      case InvoiceStatus.partiallyPaid:
        final enteredAmount = await _enterPartialPayment(
          context,
          invoice,
        );

        if (enteredAmount == null || !context.mounted) return;

        amountPaid = enteredAmount;
        break;
    }

    try {
      await service.updatePayment(
        businessId: businessId,
        invoiceId: invoice.id,
        amountPaid: amountPaid,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Invoice payment status updated.'),
            ),
          );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Unable to update payment: $e'),
            ),
          );
      }
    }
  }

  Future<Customer?> _getCustomer(
    String businessId,
    String customerId,
  ) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('customers')
        .doc(customerId)
        .get();

    if (!snapshot.exists) return null;

    return Customer.fromMap(snapshot.data()!);
  }

  @override
  Widget build(BuildContext context) {
    final business = context.watch<AuthProvider>().activeBusiness;

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
            'Manage customer invoices and record payments.',
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
                  separatorBuilder: (_, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final invoice = invoices[index];

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final compact = constraints.maxWidth < 650;

                            final customerInfo = FutureBuilder<Customer?>(
                              future: _getCustomer(
                                business.id,
                                invoice.customerId,
                              ),
                              builder: (context, customerSnapshot) {
                                final customer = customerSnapshot.data;

                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      invoice.invoiceNumber,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    if (customerSnapshot.connectionState ==
                                        ConnectionState.waiting)
                                      const Text(
                                        'Loading customer...',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      )
                                    else ...[
                                      Text(
                                        customer?.fullName ??
                                            'Customer not found',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if ((customer?.companyName ?? '')
                                          .isNotEmpty)
                                        Text(
                                          customer!.companyName,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      Text(
                                        customer?.address ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 7),
                                    Text(
                                      'Total: ${CurrencyFormatter.format(
                                        invoice.total,
                                        currency: invoice.currency,
                                      )}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      'Balance: ${CurrencyFormatter.format(
                                        invoice.balance,
                                        currency: invoice.currency,
                                      )}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );

                            final paymentSelector = Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'PAYMENT STATUS',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                DropdownButton<InvoiceStatus>(
                                  value: invoice.status,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  items: const [
                                    DropdownMenuItem(
                                      value: InvoiceStatus.unpaid,
                                      child: Text('Unpaid'),
                                    ),
                                    DropdownMenuItem(
                                      value: InvoiceStatus.partiallyPaid,
                                      child: Text('Partially Paid'),
                                    ),
                                    DropdownMenuItem(
                                      value: InvoiceStatus.paid,
                                      child: Text('Paid'),
                                    ),
                                  ],
                                  onChanged: (value) =>
                                      _changePaymentStatus(
                                    context,
                                    service,
                                    business.id,
                                    invoice,
                                    value,
                                  ),
                                ),
                                if (invoice.status ==
                                    InvoiceStatus.partiallyPaid)
                                  Text(
                                    'Paid: ${CurrencyFormatter.format(
                                      invoice.amountPaid,
                                      currency: invoice.currency,
                                    )}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            );

                            final pdfButton = OutlinedButton.icon(
                              onPressed: () => _generatePdf(
                                context,
                                business,
                                invoice,
                              ),
                              icon: const Icon(Icons.picture_as_pdf_outlined),
                              label: const Text('Generate PDF'),
                            );

                            if (compact) {
                              return Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  customerInfo,
                                  const Divider(height: 22),
                                  paymentSelector,
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: pdfButton,
                                  ),
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: customerInfo,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 3,
                                  child: paymentSelector,
                                ),
                                const SizedBox(width: 12),
                                pdfButton,
                              ],
                            );
                          },
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
}
