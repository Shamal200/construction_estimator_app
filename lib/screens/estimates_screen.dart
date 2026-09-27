import 'package:construction_estimator_app/core/utils/calculations.dart';
import 'package:construction_estimator_app/core/utils/currency_formatter.dart';
import 'package:flutter/material.dart';

class EstimatesScreen extends StatefulWidget {
  const EstimatesScreen({super.key});

  @override
  State<EstimatesScreen> createState() => _EstimatesScreenState();
}

class _EstimatesScreenState extends State<EstimatesScreen> {
  final TextEditingController _itemNameController = TextEditingController(text: 'Kitchen cabinets');
  final TextEditingController _quantityController = TextEditingController(text: '3');
  final TextEditingController _materialCostController = TextEditingController(text: '40');
  final TextEditingController _labourCostController = TextEditingController(text: '20');
  final TextEditingController _markupController = TextEditingController(text: '10');
  final TextEditingController _discountController = TextEditingController(text: '5');
  final TextEditingController _taxController = TextEditingController(text: '15');

  @override
  void dispose() {
    _itemNameController.dispose();
    _quantityController.dispose();
    _materialCostController.dispose();
    _labourCostController.dispose();
    _markupController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  QuotationSummary _summary() {
    final quantity = double.tryParse(_quantityController.text) ?? 1;
    final materialCost = double.tryParse(_materialCostController.text) ?? 0;
    final labourCost = double.tryParse(_labourCostController.text) ?? 0;
    final markupPercent = double.tryParse(_markupController.text) ?? 0;
    final discount = double.tryParse(_discountController.text) ?? 0;
    final taxPercent = double.tryParse(_taxController.text) ?? 0;

    return QuoteCalculations.summarize(
      materialCost: materialCost,
      labourCost: labourCost,
      markupPercent: markupPercent,
      discount: discount,
      taxPercent: taxPercent,
      quantity: quantity,
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estimates',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ChoiceChip(label: const Text('Joinery'), selected: true, onSelected: (_) {}),
              ChoiceChip(label: const Text('Carpentry'), selected: false, onSelected: (_) {}),
              ChoiceChip(label: const Text('Painting'), selected: false, onSelected: (_) {}),
              ChoiceChip(label: const Text('Flooring'), selected: false, onSelected: (_) {}),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quote builder',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _itemNameController,
                            decoration: const InputDecoration(labelText: 'Item name'),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _quantityController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(labelText: 'Quantity'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: TextField(
                                  enabled: false,
                                  decoration: InputDecoration(labelText: 'Unit'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _materialCostController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(labelText: 'Material cost / unit'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _labourCostController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(labelText: 'Labour cost / unit'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _markupController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(labelText: 'Markup %'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _discountController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(labelText: 'Discount'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _taxController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(labelText: 'Tax %'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: () => setState(() {}),
                            icon: const Icon(Icons.calculate),
                            label: const Text('Recalculate'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cost summary',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SummaryRow(label: 'Direct cost', value: CurrencyFormatter.format(summary.directCost)),
                          _SummaryRow(label: 'Markup', value: CurrencyFormatter.format(summary.markup)),
                          _SummaryRow(label: 'Taxable subtotal', value: CurrencyFormatter.format(summary.taxableSubtotal)),
                          _SummaryRow(label: 'Tax', value: CurrencyFormatter.format(summary.tax)),
                          const Divider(),
                          _SummaryRow(
                            label: 'Grand total',
                            value: CurrencyFormatter.format(summary.grandTotal),
                            isTotal: true,
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_itemNameController.text.isEmpty ? 'Item' : _itemNameController.text} • ${_quantityController.text} qty',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
              color: isTotal ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}
