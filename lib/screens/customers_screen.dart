
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/business_membership.dart';
import '../models/customer.dart';
import '../providers/auth_provider.dart';
import '../services/customer_service.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final CustomerService _customerService = CustomerService();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _canDeleteCustomer(AuthProvider auth) {
    final businessId = auth.activeBusiness?.id;

    if (businessId == null) return false;

    final role = auth.membershipFor(businessId)?.role;

    return role == BusinessRole.owner ||
        role == BusinessRole.admin;
  }

  List<Customer> _filterCustomers(List<Customer> customers) {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) return customers;

    return customers.where((customer) {
      return customer.fullName.toLowerCase().contains(query) ||
          customer.companyName.toLowerCase().contains(query) ||
          customer.phoneNumber.toLowerCase().contains(query) ||
          customer.email.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _openCustomerForm({Customer? customer}) async {
    final result = await showDialog<CustomerFormData>(
      context: context,
      builder: (_) => CustomerFormDialog(customer: customer),
    );

    if (!mounted || result == null) return;

    final businessId = context.read<AuthProvider>().activeBusiness?.id;

    if (businessId == null) {
      _showMessage('No active business selected.');
      return;
    }

    try {
      if (customer == null) {
        await _customerService.addCustomer(
          businessId: businessId,
          fullName: result.fullName,
          companyName: result.companyName,
          phoneNumber: result.phoneNumber,
          email: result.email,
          address: result.address,
          notes: result.notes,
        );
      } else {
        final updatedCustomer = customer.copyWith(
          fullName: result.fullName,
          companyName: result.companyName,
          phoneNumber: result.phoneNumber,
          email: result.email,
          address: result.address,
          notes: result.notes,
        );

        await _customerService.updateCustomer(
          businessId: businessId,
          customer: updatedCustomer,
        );
      }

      if (!mounted) return;

      _showMessage(
        customer == null
            ? 'Customer added successfully.'
            : 'Customer updated successfully.',
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      _showMessage(_firebaseErrorMessage(error));
    } catch (error) {
      if (!mounted) return;
      _showMessage('Something went wrong: $error');
    }
  }

  Future<void> _confirmDelete(Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete customer?'),
          content: Text(
            'Are you sure you want to delete ${customer.fullName}? '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    final businessId = context.read<AuthProvider>().activeBusiness?.id;

    if (businessId == null) {
      _showMessage('No active business selected.');
      return;
    }

    try {
      await _customerService.deleteCustomer(
        businessId: businessId,
        customerId: customer.id,
      );

      if (!mounted) return;
      _showMessage('Customer deleted successfully.');
    } on FirebaseException catch (error) {
      if (!mounted) return;
      _showMessage(_firebaseErrorMessage(error));
    } catch (error) {
      if (!mounted) return;
      _showMessage('Something went wrong: $error');
    }
  }

  String _firebaseErrorMessage(FirebaseException error) {
    if (error.code == 'permission-denied') {
      return 'You do not have permission to perform this action.';
    }

    if (error.code == 'unavailable') {
      return 'Unable to connect. Please check your internet connection.';
    }

    return error.message ?? 'A Firebase error occurred.';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final businessId = auth.activeBusiness?.id;

    if (businessId == null) {
      return const Center(
        child: Text('Please select a business to view customers.'),
      );
    }

    final canDelete = _canDeleteCustomer(auth);

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
                onPressed: () => _openCustomerForm(),
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Add customer'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your business customers and their contact details.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
            decoration: InputDecoration(
              hintText: 'Search by name, company, phone or email',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<List<Customer>>(
              stream: _customerService.watchCustomers(businessId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  final error = snapshot.error;

                  return _MessageState(
                    icon: Icons.error_outline,
                    title: 'Unable to load customers',
                    message: error is FirebaseException
                        ? _firebaseErrorMessage(error)
                        : error.toString(),
                    action: TextButton.icon(
                      onPressed: () => setState(() {}),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  );
                }

                final customers = _filterCustomers(snapshot.data ?? []);

                if (customers.isEmpty) {
                  return _MessageState(
                    icon: _searchQuery.isEmpty
                        ? Icons.people_outline
                        : Icons.search_off,
                    title: _searchQuery.isEmpty
                        ? 'No customers yet'
                        : 'No matching customers',
                    message: _searchQuery.isEmpty
                        ? 'Add your first customer to get started.'
                        : 'Try another name, company, phone number or email.',
                    action: _searchQuery.isEmpty
                        ? FilledButton.icon(
                            onPressed: () => _openCustomerForm(),
                            icon: const Icon(Icons.person_add_alt_1),
                            label: const Text('Add first customer'),
                          )
                        : null,
                  );
                }

                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListView.separated(
                    itemCount: customers.length,
                    separatorBuilder: (_, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final customer = customers[index];

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          child: Text(
                            customer.fullName.isEmpty
                                ? '?'
                                : customer.fullName[0].toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(
                          customer.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (customer.companyName.isNotEmpty)
                                Text(customer.companyName),
                              if (customer.phoneNumber.isNotEmpty)
                                Text(customer.phoneNumber),
                              if (customer.email.isNotEmpty)
                                Text(customer.email),
                            ],
                          ),
                        ),
                        isThreeLine: customer.companyName.isNotEmpty ||
                            customer.phoneNumber.isNotEmpty ||
                            customer.email.isNotEmpty,
                        trailing: PopupMenuButton<String>(
                          tooltip: 'Customer options',
                          onSelected: (value) {
                            if (value == 'edit') {
                              _openCustomerForm(customer: customer);
                            } else if (value == 'delete') {
                              _confirmDelete(customer);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined),
                                  SizedBox(width: 10),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            if (canDelete)
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error,
                                    ),
                                    const SizedBox(width: 10),
                                    const Text('Delete'),
                                  ],
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

class CustomerFormData {
  const CustomerFormData({
    required this.fullName,
    required this.companyName,
    required this.phoneNumber,
    required this.email,
    required this.address,
    required this.notes,
  });

  final String fullName;
  final String companyName;
  final String phoneNumber;
  final String email;
  final String address;
  final String notes;
}

class CustomerFormDialog extends StatefulWidget {
  const CustomerFormDialog({
    super.key,
    this.customer,
  });

  final Customer? customer;

  @override
  State<CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _companyController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();

    final customer = widget.customer;

    _fullNameController = TextEditingController(
      text: customer?.fullName ?? '',
    );
    _companyController = TextEditingController(
      text: customer?.companyName ?? '',
    );
    _phoneController = TextEditingController(
      text: customer?.phoneNumber ?? '',
    );
    _emailController = TextEditingController(
      text: customer?.email ?? '',
    );
    _addressController = TextEditingController(
      text: customer?.address ?? '',
    );
    _notesController = TextEditingController(
      text: customer?.notes ?? '',
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      CustomerFormData(
        fullName: _fullNameController.text.trim(),
        companyName: _companyController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        notes: _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.customer != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit customer' : 'Add customer'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _fullNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Customer name *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the customer name.';
                    }

                    if (value.trim().length > 200) {
                      return 'Name cannot exceed 200 characters.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _companyController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Company name',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';

                    if (email.isNotEmpty &&
                        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(email)) {
                      return 'Please enter a valid email address.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _addressController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _notesController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Save changes' : 'Add customer'),
        ),
      ],
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 54,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
