import 'package:construction_estimator_app/core/utils/currency_formatter.dart';
import 'package:construction_estimator_app/widgets/stat_card.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardCards = [
      StatCard(
        title: 'Total quotations',
        value: '128',
        trend: '+12%',
        color: Colors.teal,
        icon: Icons.receipt_long,
      ),
      StatCard(
        title: 'Pending quotations',
        value: '24',
        trend: '5 today',
        color: Colors.orange,
        icon: Icons.pending_actions,
      ),
      StatCard(
        title: 'Accepted quotations',
        value: '92',
        trend: '+8%',
        color: Colors.green,
        icon: Icons.check_circle,
      ),
      StatCard(
        title: 'Revenue',
        value: CurrencyFormatter.format(126500.0),
        trend: '+18%',
        color: Colors.indigo,
        icon: Icons.attach_money,
      ),
    ];

    final recentQuotations = [
      {'name': 'Kitchen Renovation', 'customer': 'A. Patel', 'total': CurrencyFormatter.format(14850.0)},
      {'name': 'Office Fit Out', 'customer': 'N. Singh', 'total': CurrencyFormatter.format(22600.0)},
      {'name': 'Garage Conversion', 'customer': 'J. Harris', 'total': CurrencyFormatter.format(9840.0)},
    ];

    final recentProjects = [
      {'name': 'Basil House', 'status': 'In Progress', 'date': '14 Sep 2026'},
      {'name': 'Blue Lagoon Villa', 'status': 'Approved', 'date': '30 Sep 2026'},
      {'name': 'Coastal Office', 'status': 'Planning', 'date': '06 Oct 2026'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business overview',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 1100
                  ? 4
                  : constraints.maxWidth > 760
                      ? 2
                      : 1;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dashboardCards.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 1.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (context, index) => dashboardCards[index],
              );
            },
          ),
          const SizedBox(height: 26),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: isWide ? 2 : 1,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recent quotations',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...recentQuotations.map(
                              (quotation) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            quotation['name'] as String,
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                          Text(
                                            quotation['customer'] as String,
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(quotation['total'] as String),
                                  ],
                                ),
                              ),
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
                              'Recent projects',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...recentProjects.map(
                              (project) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            project['name'] as String,
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                          Text(project['date'] as String),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        project['status'] as String,
                                        style: Theme.of(context).textTheme.labelMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
