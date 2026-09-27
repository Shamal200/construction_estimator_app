import 'package:flutter/material.dart';

class MaterialsScreen extends StatelessWidget {
  const MaterialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final materials = [
      {'name': 'PVC Board', 'category': 'Joinery', 'unit': 'sheet', 'cost': 'FJD 120.00'},
      {'name': 'Plywood', 'category': 'Carpentry', 'unit': 'sheet', 'cost': 'FJD 95.00'},
      {'name': 'Paint', 'category': 'Painting', 'unit': 'litre', 'cost': 'FJD 44.00'},
      {'name': 'Vinyl Flooring', 'category': 'Flooring', 'unit': 'm²', 'cost': 'FJD 22.00'},
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
                  'Materials database',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Add material'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search materials',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Card(
              child: ListView.separated(
                itemCount: materials.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final material = materials[index];
                  return ListTile(
                    title: Text(material['name'] as String),
                    subtitle: Text(material['category'] as String),
                    trailing: Text(material['cost'] as String),
                    leading: Text(material['unit'] as String),
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
