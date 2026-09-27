import 'package:flutter/material.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final customers = [
      {'name': 'Amit Patel', 'company': 'Patel Joinery', 'phone': '+679 998 1234', 'email': 'amit@pateljoinery.com'},
      {'name': 'Nancy Singh', 'company': 'N. Singh Builders', 'phone': '+679 923 4421', 'email': 'nancy@nsbuilders.fj'},
      {'name': 'Joel Harris', 'company': 'Harris Projects', 'phone': '+679 887 5500', 'email': 'joel@harrisprojects.com'},
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
                  'Customers',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Add customer'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search customers',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Card(
              child: ListView.separated(
                itemCount: customers.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  return ListTile(
                    title: Text(customer['name'] as String),
                    subtitle: Text(customer['company'] as String),
                    trailing: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(customer['phone'] as String),
                        Text(customer['email'] as String),
                      ],
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        (customer['name'] as String).substring(0, 1),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
