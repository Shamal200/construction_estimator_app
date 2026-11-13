import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/business_service.dart';

class CreateBusinessScreen extends StatefulWidget {
  const CreateBusinessScreen({super.key});

  @override
  State<CreateBusinessScreen> createState() => _CreateBusinessScreenState();
}

class _CreateBusinessScreenState extends State<CreateBusinessScreen> {
  final _formKey = GlobalKey<FormState>();

  final _companyNameController = TextEditingController();
  final _registrationController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _taxController = TextEditingController();
  final _currencyController = TextEditingController(text: 'FJD');
  final _defaultTaxController = TextEditingController(text: '12.5');

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _companyNameController.dispose();
    _registrationController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _taxController.dispose();
    _currencyController.dispose();
    _defaultTaxController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Business email is required';
    }

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailPattern.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }

    return null;
  }

  String? _taxValidator(String? value) {
    final tax = double.tryParse(value ?? '');

    if (tax == null || !tax.isFinite || tax < 0 || tax > 100) {
      return 'Enter a percentage between 0 and 100';
    }

    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    // Get providers before any asynchronous operation.
    final businessService = context.read<BusinessService>();
    final authProvider = context.read<AuthProvider>();

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await businessService.createBusiness(
        name: _companyNameController.text,
        address: _addressController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        currency: _currencyController.text,
        defaultTaxRate: double.parse(_defaultTaxController.text.trim()),
        website: _websiteController.text,
        businessRegistrationNumber: _registrationController.text,
        taxRegistrationNumber: _taxController.text,
      );

      await authProvider.refreshSession();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business created successfully.')),
      );

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create business')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Create a new business',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _companyNameController,
                        decoration: const InputDecoration(
                          labelText: 'Company name',
                        ),
                        validator: (value) =>
                            _requiredValidator(value, 'Company name'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _registrationController,
                        decoration: const InputDecoration(
                          labelText: 'Business registration number (optional)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Business address',
                        ),
                        validator: (value) =>
                            _requiredValidator(value, 'Address'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Phone number',
                              ),
                              validator: (value) =>
                                  _requiredValidator(value, 'Phone number'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Business email',
                              ),
                              validator: _emailValidator,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _websiteController,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          labelText: 'Website (optional)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _taxController,
                        decoration: const InputDecoration(
                          labelText: 'Tax registration number (optional)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _currencyController,
                              textCapitalization: TextCapitalization.characters,
                              maxLength: 3,
                              decoration: const InputDecoration(
                                labelText: 'Currency code',
                                hintText: 'FJD',
                                counterText: '',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().length != 3) {
                                  return 'Enter a 3-letter code';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _defaultTaxController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Default tax (%)',
                              ),
                              validator: _taxValidator,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      FilledButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add_business),
                        label: Text(
                          _isSubmitting
                              ? 'Creating business...'
                              : 'Create business',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
