
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../core/utils/currency_formatter.dart';
import '../models/quotation.dart';
import '../providers/auth_provider.dart';
import '../services/invoice_service.dart';
import '../services/quotation_pdf_service.dart';
import '../services/quotation_service.dart';
import 'quotation_form_screen.dart';

class QuotationsScreen extends StatefulWidget {
  const QuotationsScreen({super.key});

  @override
  State<QuotationsScreen> createState() => _QuotationsScreenState();
}

class _QuotationsScreenState extends State<QuotationsScreen> {
  final _service = QuotationService();
  final _invoiceService = InvoiceService();
  final _pdf = QuotationPdfService();

  final Set<String> _convertingQuotationIds = {};

  Future<void> _create() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const QuotationFormScreen(),
      ),
    );
  }

  Future<void> _edit(Quotation quote) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuotationFormScreen(
          existingQuotation: quote,
        ),
      ),
    );
  }

  Future<void> _print(dynamic business, Quotation quote) async {
    try {
      await Printing.layoutPdf(
        name: '${quote.quotationNumber}.pdf',
        onLayout: (_) => _pdf.build(
          business: business,
          quote: quote,
          templateId: business.defaultQuotationTemplate,
        ),
      );
    } catch (e) {
      if (mounted) {
        _message('PDF generation failed: $e');
      }
    }
  }

  Future<void> _convertToInvoice(
    Quotation quote,
    String businessId,
  ) async {
    if (quote.invoiceId.isNotEmpty) {
      _message('This quotation has already been converted.');
      return;
    }

    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Convert to invoice?'),
        content: Text(
          'Convert ${quote.quotationNumber} into a invoice?\n\n'
          'The invoice will retain the quotation selling prices '
          'and totals. You can record payments against it from the Invoices section.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.receipt_long),
            label: const Text('Convert'),
          ),
        ],
      ),
    );

    if (yes != true || !mounted) return;

    setState(() {
      _convertingQuotationIds.add(quote.id);
    });

    try {
      final invoice = await _invoiceService.convertQuotationToInvoice(
        businessId: businessId,
        quotationId: quote.id,
      );

      if (mounted) {
        _message(
          'Invoice ${invoice.invoiceNumber} created successfully.',
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        _message(
          e.message ?? 'Unable to convert quotation to invoice.',
        );
      }
    } catch (e) {
      if (mounted) {
        _message('Invoice conversion failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _convertingQuotationIds.remove(quote.id);
        });
      }
    }
  }

  Future<void> _delete(
    Quotation quote,
    String businessId,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete quotation?'),
        content: Text(
          'Delete ${quote.quotationNumber}? '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (yes != true) return;

    try {
      await _service.deleteQuotation(
        businessId: businessId,
        quotationId: quote.id,
      );
    } on FirebaseException catch (e) {
      if (mounted) {
        _message(e.message ?? 'Unable to delete quotation.');
      }
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text)),
      );
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

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Quotations',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              FilledButton.icon(
                onPressed: _create,
                icon: const Icon(Icons.add),
                label: const Text('New quotation'),
              ),
            ],
          ),
          const SizedBox(height: 7),
          const Text(
            'Create, manage and generate professional PDF quotations.',
          ),
          const SizedBox(height: 18),
          Expanded(
            child: StreamBuilder<List<Quotation>>(
              stream: _service.watchQuotations(business.id),
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
                      'Unable to load quotations.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final quotes = snapshot.data ?? [];

                if (quotes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.request_quote_outlined,
                          size: 58,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No quotations yet',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Create your first quotation to get started.',
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _create,
                          icon: const Icon(Icons.add),
                          label: const Text('Create quotation'),
                        ),
                      ],
                    ),
                  );
                }

                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListView.separated(
                    itemCount: quotes.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final quote = quotes[index];
                      final isConverted =
                          quote.invoiceId.isNotEmpty;
                      final isConverting =
                          _convertingQuotationIds.contains(quote.id);

                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFEAF0F8),
                          child: Icon(
                            Icons.description_outlined,
                            color: Color(0xFF29486F),
                          ),
                        ),
                        title: Text(
                          '${quote.quotationNumber}  •  '
                          '${quote.customerName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${quote.projectName}  •  ${quote.status}  •  '
                          '${CurrencyFormatter.format(
                            quote.grandTotal,
                            currency: quote.currency,
                          )}'
                          '${isConverted ? '\nInvoice created' : ''}',
                        ),
                        isThreeLine: isConverted,
                        trailing: Wrap(
                          spacing: 2,
                          children: [
                            if (isConverting)
                              const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            else if (isConverted)
                              const IconButton(
                                tooltip: 'Already converted to invoice',
                                onPressed: null,
                                icon: Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                              )
                            else
                              IconButton(
                                tooltip: 'Convert to invoice',
                                onPressed: () => _convertToInvoice(
                                  quote,
                                  business.id,
                                ),
                                icon: const Icon(
                                  Icons.receipt_long_outlined,
                                ),
                              ),
                            IconButton(
                              tooltip: 'Edit quotation',
                              onPressed: () => _edit(quote),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Generate PDF',
                              onPressed: () => _print(business, quote),
                              icon: const Icon(
                                Icons.picture_as_pdf_outlined,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Delete quotation',
                              onPressed: () => _delete(
                                quote,
                                business.id,
                              ),
                              icon: const Icon(
                                Icons.delete_outline,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
