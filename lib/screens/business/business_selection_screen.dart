import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/business_membership.dart';
import '../../providers/auth_provider.dart';
import 'business_onboarding_screen.dart';

class BusinessSelectionScreen extends StatelessWidget {
  const BusinessSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Business selection')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: auth.isLoading
            ? const Center(child: CircularProgressIndicator())
            : auth.businesses.isEmpty
            ? _NoBusinessView(
                onCreate: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BusinessOnboardingScreen(),
                  ),
                ),
                onJoin: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BusinessOnboardingScreen(),
                  ),
                ),
              )
            : ListView.builder(
                itemCount: auth.businesses.length,
                itemBuilder: (context, index) {
                  final business = auth.businesses[index];
                  final role =
                      auth.membershipFor(business.id)?.role ??
                      BusinessRole.viewer;

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          business.name.substring(0, 1).toUpperCase(),
                        ),
                      ),
                      title: Text(business.name),
                      subtitle: Text(
                        '${business.address} • Role: ${role.label}',
                      ),
                      trailing: auth.profile?.activeBusinessId == business.id
                          ? const Chip(label: Text('Active'))
                          : FilledButton(
                              onPressed: () => auth.selectBusiness(business.id),
                              child: const Text('Select'),
                            ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _NoBusinessView extends StatelessWidget {
  const _NoBusinessView({required this.onCreate, required this.onJoin});

  final VoidCallback onCreate;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.business_center, size: 52),
                const SizedBox(height: 12),
                Text(
                  'No business workspaces yet',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Create a new workspace or join an invitation to get started.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onCreate,
                  child: const Text('Create business'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: onJoin,
                  child: const Text('Join business'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
