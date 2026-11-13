
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/customer.dart';
import '../models/quotation.dart';
import '../models/quotation_item.dart';
import '../providers/auth_provider.dart';
import '../services/customer_service.dart';
import '../services/quotation_service.dart';

class QuotationFormScreen extends StatefulWidget {
  const QuotationFormScreen({super.key});

  @override
  State<QuotationFormScreen> createState() => _QuotationFormScreenState();
}

class _QuotationFormScreenState extends State<QuotationFormScreen> {
  final _form = GlobalKey<FormState>();
  final _customerSearch = TextEditingController();
  final _project = TextEditingController();
  final _site = TextEditingController();
  final _scope = TextEditingController();
  final _markup = TextEditingController(text: '0');
  final _discount = TextEditingController(text: '0');
  final _tax = TextEditingController();
  final _validity = TextEditingController(text: '30');
  final _notes = TextEditingController();

  final _terms = TextEditingController(
    text: 'Quotation validity: 30 days.\n'
        'Payment terms: 50% deposit, balance upon completion.\n'
        'Any variation or additional work outside the stated scope '
        'will be quoted separately.',
  );

  final _customers = CustomerService();
  final _quotes = QuotationService();
  final List<_LineDraft> _lines = [_LineDraft()];

  Customer? _customer;
  DateTime _date = DateTime.now();
  bool _saving = false;

  double _n(String s) =>
      double.tryParse(s.trim().replaceAll(',', '')) ?? 0;

  double get _direct => _lines.fold(
        0,
        (v, l) => v + _n(l.qty.text) * _n(l.rate.text),
      );

  double get _markupAmount => _direct * _n(_markup.text) / 100;
  double get _subtotal => _direct + _markupAmount - _n(_discount.text);
  double get _taxAmount => _subtotal * _n(_tax.text) / 100;
  double get _total => _subtotal + _taxAmount;

  @override
  void initState() {
    super.initState();
    _tax.text = (context
                .read<AuthProvider>()
                .activeBusiness
                ?.defaultTaxRate ??
            0)
        .toStringAsFixed(2);
  }

  @override
  void dispose() {
    for (final c in [
      _customerSearch,
      _project,
      _site,
      _scope,
      _markup,
      _discount,
      _tax,
      _validity,
      _notes,
      _terms,
    ]) {
      c.dispose();
    }

    for (final l in _lines) {
      l.dispose();
    }

    super.dispose();
  }

  void _msg(String s) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s)),
    );
  }

  String _cash(double v, String currency) =>
      '$currency ${v.toStringAsFixed(2)}';

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (d != null) {
      setState(() => _date = d);
    }
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;

    if (_customer == null) {
      _msg('Select a customer from the search results.');
      return;
    }

    final business = context.read<AuthProvider>().activeBusiness;

    if (business == null) {
      _msg('No active business selected.');
      return;
    }

    final customer = _customer!;
    final validity = int.tryParse(_validity.text) ?? 30;

    final items = _lines
        .map(
          (l) => QuotationItem(
            id: const Uuid().v4(),
            name: l.name.text.trim(),
            description: l.details.text.trim(),
            unit: l.unit.text.trim().isEmpty
                ? 'item'
                : l.unit.text.trim(),
            quantity: _n(l.qty.text),
            materialCost: _n(l.rate.text),
            labourCost: 0,
          ),
        )
        .toList();

    final draft = Quotation(
      id: '',
      quotationNumber: '',
      customerId: customer.id,
      customerName: customer.fullName,
      customerNumber: customer.customerNumber,
      customerCompany: customer.companyName,
      customerPhone: customer.phoneNumber,
      customerEmail: customer.email,
      customerAddress: customer.address,
      projectName: _project.text.trim(),
      projectAddress: _site.text.trim(),
      description: _scope.text.trim(),
      issueDate: _date,
      validUntil: _date.add(Duration(days: validity)),
      notes: _notes.text.trim(),
      termsAndConditions: _terms.text.trim(),
      items: items,
      markupPercent: _n(_markup.text),
      discount: _n(_discount.text),
      taxPercent: _n(_tax.text),
      status: 'Draft',
      currency: business.currency.isEmpty
          ? 'FJD'
          : business.currency,
    );

    setState(() => _saving = true);

    try {
      final saved = await _quotes.createQuotation(
        businessId: business.id,
        quotation: draft,
      );

      if (!mounted) return;

      _msg('${saved.quotationNumber} saved successfully.');
      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (mounted) {
        _msg(
          e.code == 'permission-denied'
              ? 'Permission denied. The quotation counter rules '
                  'must be added before saving quotations.'
              : e.message ?? 'Unable to save quotation.',
        );
      }
    } catch (e) {
      if (mounted) {
        _msg('Unable to save quotation: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _card(
    String title,
    Widget child, {
    Widget? action,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (action != null) action,
              ],
            ),
            const SizedBox(height: 13),
            child,
          ],
        ),
      ),
    );
  }

  Widget _number(
    TextEditingController c,
    String label, {
    bool required = false,
    bool whole = false,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(labelText: label),
      validator: (v) {
        if (required && (v == null || v.trim().isEmpty)) {
          return 'Required';
        }

        if (v != null &&
            v.trim().isNotEmpty &&
            double.tryParse(v.trim()) == null) {
          return 'Enter a number';
        }

        if (whole &&
            v != null &&
            v.trim().isNotEmpty &&
            int.tryParse(v.trim()) == null) {
          return 'Enter whole days';
        }

        if (v != null &&
            v.trim().isNotEmpty &&
            _n(v) < 0) {
          return 'Cannot be negative';
        }

        return null;
      },
    );
  }

  Widget _totals(String currency) {
    final rows = [
      ('Direct cost', _direct),
      ('Markup', _markupAmount),
      ('Discount', -_n(_discount.text)),
      ('Subtotal', _subtotal),
      ('Tax', _taxAmount),
    ];

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          ...rows.map(
            (r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(r.$1),
                  Text(_cash(r.$2, currency)),
                ],
              ),
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL DUE',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                _cash(_total, currency),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Color(0xFF29486F),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final business = context.watch<AuthProvider>().activeBusiness;

    if (business == null) {
      return const Scaffold(
        body: Center(
          child: Text('No active business selected.'),
        ),
      );
    }

    final currency =
        business.currency.isEmpty ? 'FJD' : business.currency;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create quotation'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(
                _saving ? 'Saving...' : 'Save quotation',
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _card(
              'Customer details',
              StreamBuilder<List<Customer>>(
                stream: _customers.watchCustomers(business.id),
                builder: (context, snap) {
                  final list = snap.data ?? [];
                  final q = _customerSearch.text.trim().toLowerCase();

                  final matches = q.isEmpty
                      ? <Customer>[]
                      : list
                          .where(
                            (c) =>
                                c.customerNumber
                                    .toLowerCase()
                                    .contains(q) ||
                                c.fullName.toLowerCase().contains(q) ||
                                c.companyName.toLowerCase().contains(q),
                          )
                          .take(8)
                          .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _customerSearch,
                        decoration: InputDecoration(
                          labelText:
                              'Search customer by number or name',
                          hintText: 'Example: 001',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _customer = null;
                                _customerSearch.clear();
                              });
                            },
                            icon: const Icon(Icons.close),
                          ),
                        ),
                        onChanged: (_) {
                          setState(() => _customer = null);
                        },
                      ),
                      if (matches.isNotEmpty && _customer == null)
                        Container(
                          constraints:
                              const BoxConstraints(maxHeight: 190),
                          margin: const EdgeInsets.only(top: 5),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: ListView(
                            shrinkWrap: true,
                            children: matches
                                .map(
                                  (c) => ListTile(
                                    dense: true,
                                    title: Text(
                                      '${c.customerNumber}  ${c.fullName}',
                                    ),
                                    subtitle: Text(
                                      [
                                        c.companyName,
                                        c.phoneNumber,
                                      ]
                                          .where((e) => e.isNotEmpty)
                                          .join(' • '),
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _customer = c;
                                        _customerSearch.text =
                                            '${c.customerNumber} - '
                                            '${c.fullName}';

                                        if (_site.text.isEmpty) {
                                          _site.text = c.address;
                                        }
                                      });
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      if (snap.connectionState ==
                          ConnectionState.waiting)
                        const LinearProgressIndicator(),
                      if (snap.hasError)
                        const Text('Unable to load customers.'),
                      if (_customer != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF0F8),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_customer!.customerNumber}  '
                                '${_customer!.fullName}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_customer!.companyName.isNotEmpty)
                                Text(_customer!.companyName),
                              if (_customer!.phoneNumber.isNotEmpty)
                                Text(_customer!.phoneNumber),
                              if (_customer!.email.isNotEmpty)
                                Text(_customer!.email),
                              if (_customer!.address.isNotEmpty)
                                Text(_customer!.address),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            _card(
              'Project information',
              Column(
                children: [
                  TextFormField(
                    controller: _project,
                    decoration: const InputDecoration(
                      labelText: 'Project name *',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty
                            ? 'Enter project name'
                            : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _site,
                    decoration: const InputDecoration(
                      labelText: 'Project / site address',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _scope,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description of works',
                    ),
                  ),
                ],
              ),
            ),
            _card(
              'Line items',
              Column(
                children: [
                  ...List.generate(_lines.length, (i) {
                    final l = _lines[i];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Item ${i + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _lines.length == 1
                                    ? null
                                    : () {
                                        setState(() {
                                          final old =
                                              _lines.removeAt(i);
                                          old.dispose();
                                        });
                                      },
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                          TextFormField(
                            controller: l.name,
                            decoration: const InputDecoration(
                              labelText: 'Description / item name *',
                            ),
                            validator: (v) =>
                                v == null || v.trim().isEmpty
                                    ? 'Enter item description'
                                    : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: l.details,
                            decoration: const InputDecoration(
                              labelText: 'Additional details',
                            ),
                          ),
                          const SizedBox(height: 8),
                          LayoutBuilder(
                            builder: (context, c) {
                              final children = [
                                _number(
                                  l.qty,
                                  'Quantity *',
                                  required: true,
                                ),
                                TextFormField(
                                  controller: l.unit,
                                  decoration: const InputDecoration(
                                    labelText: 'Unit',
                                  ),
                                ),
                                _number(
                                  l.rate,
                                  'Unit rate *',
                                  required: true,
                                ),
                              ];

                              if (c.maxWidth < 550) {
                                return Column(
                                  children: children
                                      .map(
                                        (w) => Padding(
                                          padding:
                                              const EdgeInsets.only(
                                            bottom: 7,
                                          ),
                                          child: w,
                                        ),
                                      )
                                      .toList(),
                                );
                              }

                              return Row(
                                children: children
                                    .map(
                                      (w) => Expanded(
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(
                                            right: 7,
                                          ),
                                          child: w,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              );
                            },
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Line total: ${_cash(_n(l.qty.text) * _n(l.rate.text), currency)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _lines.add(_LineDraft()));
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add line item'),
                    ),
                  ),
                ],
              ),
            ),
            _card(
              'Pricing and tax',
              Column(
                children: [
                  LayoutBuilder(
                    builder: (context, c) {
                      final fields = [
                        _number(_markup, 'Markup %'),
                        _number(_discount, 'Discount amount'),
                        _number(_tax, 'Tax %'),
                        _number(
                          _validity,
                          'Validity (days)',
                          required: true,
                          whole: true,
                        ),
                      ];

                      if (c.maxWidth < 600) {
                        return Column(
                          children: fields
                              .map(
                                (w) => Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 8),
                                  child: w,
                                ),
                              )
                              .toList(),
                        );
                      }

                      return Row(
                        children: fields
                            .map(
                              (w) => Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.only(right: 7),
                                  child: w,
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Issue date'),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(
                          '${_date.day.toString().padLeft(2, '0')}/'
                          '${_date.month.toString().padLeft(2, '0')}/'
                          '${_date.year}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _totals(currency),
                ],
              ),
            ),
            _card(
              'Additional information',
              Column(
                children: [
                  TextFormField(
                    controller: _notes,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Additional notes',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _terms,
                    minLines: 3,
                    maxLines: 7,
                    decoration: const InputDecoration(
                      labelText: 'Terms and conditions',
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  _saving ? 'Saving...' : 'Save quotation',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineDraft {
  final name = TextEditingController();
  final details = TextEditingController();
  final qty = TextEditingController(text: '1');
  final unit = TextEditingController(text: 'item');
  final rate = TextEditingController(text: '0');

  void dispose() {
    name.dispose();
    details.dispose();
    qty.dispose();
    unit.dispose();
    rate.dispose();
  }
}
