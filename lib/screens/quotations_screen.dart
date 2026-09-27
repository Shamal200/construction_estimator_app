import 'package:construction_estimator_app/core/utils/currency_formatter.dart';
import 'package:flutter/material.dart';

class QuotationsScreen extends StatelessWidget {
  const QuotationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quotations = [
      {'number': 'QT-1001', 'customer': 'Amit Patel', 'status': 'Pending', 'total': CurrencyFormatter.format(14850.0)},
      {'number': 'QT-1002', 'customer': 'N. Singh', 'status': 'Approved', 'total': CurrencyFormatter.format(22600.0)},
      {'number': 'QT-1003', 'customer': 'J. Harris', 'status': 'Draft', 'total': CurrencyFormatter.format(9800.0)},
    ];

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
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('New quotation'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Quotation #')),
                    DataColumn(label: Text('Customer')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Total')),
                  ],
                  rows: quotations
                      .map(
                        (item) => DataRow(
                          cells: [
                            DataCell(Text(item['number'] as String)),
                            DataCell(Text(item['customer'] as String)),
                            DataCell(
                              Text(item['status'] as String),
                            ),
                            DataCell(Text(item['total'] as String)),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
