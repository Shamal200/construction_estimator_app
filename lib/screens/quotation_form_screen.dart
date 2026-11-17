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
  const QuotationFormScreen({
    super.key,
    this.existingQuotation,
  });

  final Quotation? existingQuotation;

  @override
  State<QuotationFormScreen> createState() =>
      _QuotationFormScreenState();
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

  final List<_LineDraft> _lines = [];

  Customer? _customer;
  DateTime _date = DateTime.now();
  bool _saving = false;

  bool get _isEditing => widget.existingQuotation != null;

  Quotation? get _existing => widget.existingQuotation;

  double _n(String s) =>
      double.tryParse(s.trim().replaceAll(',', '')) ?? 0;

  bool get _usesItemMarkup =>
      !_isEditing || (_existing?.itemMarkupEnabled ?? false);

  double _sellingUnitRate(_LineDraft line) =>
      _n(line.rate.text) * (1 + _n(line.markup.text) / 100);

  double _sellingTotal(_LineDraft line) =>
      _sellingUnitRate(line) * _n(line.qty.text);

  double get _direct => _lines.fold(
        0.0,
        (sum, line) =>
            sum + _n(line.qty.text) * _n(line.rate.text),
      );

  double get _markupAmount => _usesItemMarkup
      ? _lines.fold(
          0.0,
          (sum, line) =>
              sum +
              (_n(line.qty.text) *
                  _n(line.rate.text) *
                  _n(line.markup.text) /
                  100),
        )
      : _direct * _n(_markup.text) / 100;

  double get _subtotal => _usesItemMarkup
      ? _lines.fold(
              0.0,
              (sum, line) => sum + _sellingTotal(line),
            ) -
            _n(_discount.text)
      : _direct + _markupAmount - _n(_discount.text);

  double get _taxAmount => _subtotal * _n(_tax.text) / 100;

  double get _total => _subtotal + _taxAmount;

  @override
  void initState() {
    super.initState();

    final existing = _existing;

    if (existing != null) {
      _loadExistingQuotation(existing);
    } else {
      _tax.text = (context
                  .read<AuthProvider>()
                  .activeBusiness
                  ?.defaultTaxRate ??
              0)
          .toStringAsFixed(2);

      _lines.add(_LineDraft());
    }
  }

  void _loadExistingQuotation(Quotation quote) {
    _customerSearch.text =
        '${quote.customerNumber} - ${quote.customerName}';

    _project.text = quote.projectName;
    _site.text = quote.projectAddress;
    _scope.text = quote.description;
    _markup.text = quote.markupPercent.toString();
    _discount.text = quote.discount.toString();
    _tax.text = quote.taxPercent.toString();
    _date = quote.issueDate;

    _validity.text =
        quote.validUntil.difference(quote.issueDate).inDays.toString();

    _notes.text = quote.notes;
    _terms.text = quote.termsAndConditions;

    for (final item in quote.items) {
      _lines.add(_LineDraft.fromItem(item));
    }

    if (_lines.isEmpty) {
      _lines.add(_LineDraft());
    }
  }

  @override
  void dispose() {
    for (final controller in [
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
      controller.dispose();
    }

    for (final line in _lines) {
      line.dispose();
    }

    super.dispose();
  }

  void _msg(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _cash(double value, String currency) =>
      '$currency ${value.toStringAsFixed(2)}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;

    if (!_isEditing && _customer == null) {
      _msg('Select a customer from the search results.');
      return;
    }

    final business = context.read<AuthProvider>().activeBusiness;

    if (business == null) {
      _msg('No active business selected.');
      return;
    }

    final existing = _existing;
    final selectedCustomer = _customer;

    final customerId =
        selectedCustomer?.id ?? existing?.customerId ?? '';

    final customerName =
        selectedCustomer?.fullName ?? existing?.customerName ?? '';

    final customerNumber =
        selectedCustomer?.customerNumber ??
            existing?.customerNumber ??
            '';

    final customerCompany =
        selectedCustomer?.companyName ??
            existing?.customerCompany ??
            '';

    final customerPhone =
        selectedCustomer?.phoneNumber ??
            existing?.customerPhone ??
            '';

    final customerEmail =
        selectedCustomer?.email ?? existing?.customerEmail ?? '';

    final customerAddress =
        selectedCustomer?.address ??
            existing?.customerAddress ??
            '';

    final validity = int.tryParse(_validity.text) ?? 30;

    final items = _lines.map((line) {
      return QuotationItem(
        id: line.id.isEmpty ? const Uuid().v4() : line.id,
        name: line.name.text.trim(),
        description: line.details.text.trim(),
        unit: line.unit.text.trim().isEmpty
            ? 'item'
            : line.unit.text.trim(),
        quantity: _n(line.qty.text),
        materialCost: _n(line.rate.text),
        labourCost: 0,
        markupPercent: _usesItemMarkup ? _n(line.markup.text) : 0,
      );
    }).toList();

    final draft = Quotation(
      id: existing?.id ?? '',
      quotationNumber: existing?.quotationNumber ?? '',
      customerId: customerId,
      customerName: customerName,
      customerNumber: customerNumber,
      customerCompany: customerCompany,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      customerAddress: customerAddress,
      projectName: _project.text.trim(),
      projectAddress: _site.text.trim(),
      description: _scope.text.trim(),
      issueDate: _date,
      validUntil: _date.add(Duration(days: validity)),
      notes: _notes.text.trim(),
      termsAndConditions: _terms.text.trim(),
      items: items,
      markupPercent: _usesItemMarkup ? 0 : _n(_markup.text),
      discount: _n(_discount.text),
      taxPercent: _n(_tax.text),
      status: existing?.status ?? 'Draft',
      currency: existing?.currency ??
          (business.currency.isEmpty ? 'FJD' : business.currency),
      itemMarkupEnabled: _usesItemMarkup,
    );

    setState(() => _saving = true);

    try {
      if (_isEditing) {
        await _quotes.updateQuotation(
          businessId: business.id,
          quotation: draft,
        );

        if (!mounted) return;

        _msg('${draft.quotationNumber} updated successfully.');
      } else {
        final saved = await _quotes.createQuotation(
          businessId: business.id,
          quotation: draft,
        );

        if (!mounted) return;

        _msg('${saved.quotationNumber} saved successfully.');
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        _msg(
          e.code == 'permission-denied'
              ? 'Permission denied. Please check your quotation Firestore rules.'
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
    TextEditingController controller,
    String label, {
    bool required = false,
    bool whole = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (required &&
            (value == null || value.trim().isEmpty)) {
          return 'Required';
        }

        if (value != null &&
            value.trim().isNotEmpty &&
            double.tryParse(value.trim()) == null) {
          return 'Enter a number';
        }

        if (whole &&
            value != null &&
            value.trim().isNotEmpty &&
            int.tryParse(value.trim()) == null) {
          return 'Enter whole days';
        }

        if (value != null &&
            value.trim().isNotEmpty &&
            _n(value) < 0) {
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
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(row.$1),
                  Text(_cash(row.$2, currency)),
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

  Widget _customerDetails(String businessId) {
    if (_isEditing) {
      final quote = _existing!;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF0F8),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${quote.customerNumber}  ${quote.customerName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (quote.customerCompany.isNotEmpty)
              Text(quote.customerCompany),
            if (quote.customerPhone.isNotEmpty)
              Text(quote.customerPhone),
            if (quote.customerEmail.isNotEmpty)
              Text(quote.customerEmail),
            if (quote.customerAddress.isNotEmpty)
              Text(quote.customerAddress),
            const SizedBox(height: 8),
            const Text(
              'The customer details on this existing quotation are retained.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<List<Customer>>(
      stream: _customers.watchCustomers(businessId),
      builder: (context, snapshot) {
        final list = snapshot.data ?? [];
        final query = _customerSearch.text.trim().toLowerCase();

        final matches = query.isEmpty
            ? <Customer>[]
            : list
                .where(
                  (customer) =>
                      customer.customerNumber
                          .toLowerCase()
                          .contains(query) ||
                      customer.fullName.toLowerCase().contains(query) ||
                      customer.companyName.toLowerCase().contains(query),
                )
                .take(8)
                .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _customerSearch,
              decoration: InputDecoration(
                labelText: 'Search customer by number or name',
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
                constraints: const BoxConstraints(maxHeight: 190),
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: matches.map((customer) {
                    return ListTile(
                      dense: true,
                      title: Text(
                        '${customer.customerNumber}  ${customer.fullName}',
                      ),
                      subtitle: Text(
                        [
                          customer.companyName,
                          customer.phoneNumber,
                        ].where((value) => value.isNotEmpty).join(' • '),
                      ),
                      onTap: () {
                        setState(() {
                          _customer = customer;
                          _customerSearch.text =
                              '${customer.customerNumber} - '
                              '${customer.fullName}';

                          if (_site.text.isEmpty) {
                            _site.text = customer.address;
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            if (snapshot.connectionState == ConnectionState.waiting)
              const LinearProgressIndicator(),
            if (snapshot.hasError)
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }

  Widget _lineItem(_LineDraft line, int index, String currency) {
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
                  'Item ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: _lines.length == 1
                    ? null
                    : () {
                        setState(() {
                          final removed = _lines.removeAt(index);
                          removed.dispose();
                        });
                      },
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          TextFormField(
            controller: line.name,
            decoration: const InputDecoration(
              labelText: 'Description / item name *',
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty
                    ? 'Enter item description'
                    : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: line.details,
            decoration: const InputDecoration(
              labelText: 'Additional details',
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final fields = <Widget>[
                _number(
                  line.qty,
                  'Quantity *',
                  required: true,
                ),
                TextFormField(
                  controller: line.unit,
                  decoration: const InputDecoration(labelText: 'Unit'),
                ),
                _number(
                  line.rate,
                  _usesItemMarkup ? 'Unit cost *' : 'Unit rate *',
                  required: true,
                ),
                if (_usesItemMarkup)
                  _number(line.markup, 'Markup %'),
              ];

              if (constraints.maxWidth < 550) {
                return Column(
                  children: fields
                      .map(
                        (field) => Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: field,
                        ),
                      )
                      .toList(),
                );
              }

              return Row(
                children: fields
                    .map(
                      (field) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: field,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          if (_usesItemMarkup)
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Selling unit rate: ${_cash(_sellingUnitRate(line), currency)}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Line total: ${_cash(_usesItemMarkup ? _sellingTotal(line) : _n(line.qty.text) * _n(line.rate.text), currency)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
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

    final currency = _isEditing
        ? (_existing!.currency.isEmpty ? 'FJD' : _existing!.currency)
        : (business.currency.isEmpty ? 'FJD' : business.currency);

    final actionLabel = _isEditing ? 'Update quotation' : 'Save quotation';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? 'Edit quotation ${_existing!.quotationNumber}'
              : 'Create quotation',
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Saving...' : actionLabel),
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
              _customerDetails(business.id),
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
                    validator: (value) =>
                        value == null || value.trim().isEmpty
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
                  ...List.generate(
                    _lines.length,
                    (index) => _lineItem(
                      _lines[index],
                      index,
                      currency,
                    ),
                  ),
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
                    builder: (context, constraints) {
                      final fields = <Widget>[
                        if (!_usesItemMarkup)
                          _number(_markup, 'Overall markup %'),
                        _number(_discount, 'Discount amount'),
                        _number(_tax, 'Tax %'),
                        _number(
                          _validity,
                          'Validity (days)',
                          required: true,
                          whole: true,
                        ),
                      ];

                      if (constraints.maxWidth < 600) {
                        return Column(
                          children: fields
                              .map(
                                (field) => Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 8),
                                  child: field,
                                ),
                              )
                              .toList(),
                        );
                      }

                      return Row(
                        children: fields
                            .map(
                              (field) => Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.only(right: 7),
                                  child: field,
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
                label: Text(_saving ? 'Saving...' : actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineDraft {
  _LineDraft();

  _LineDraft.fromItem(QuotationItem item) {
    id = item.id;
    name.text = item.name;
    details.text = item.description;
    qty.text = item.quantity.toString();
    unit.text = item.unit;
    rate.text = item.unitRate.toString();
    markup.text = item.markupPercent.toString();
  }

  String id = '';

  final name = TextEditingController();
  final details = TextEditingController();
  final qty = TextEditingController(text: '1');
  final unit = TextEditingController(text: 'item');
  final rate = TextEditingController(text: '0');
  final markup = TextEditingController(text: '0');

  void dispose() {
    name.dispose();
    details.dispose();
    qty.dispose();
    unit.dispose();
    rate.dispose();
    markup.dispose();
  }
}