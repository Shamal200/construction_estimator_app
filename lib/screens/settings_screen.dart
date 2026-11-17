
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/business.dart';
import '../providers/auth_provider.dart';
import '../services/business_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessService = BusinessService();

  final _bankNameController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _branchController = TextEditingController();
  final _branchCodeController = TextEditingController();
  final _paymentInstructionsController = TextEditingController();

  String _template = 'minimal';
  String _logoBase64 = '';
  bool _isSaving = false;
  bool _isPickingLogo = false;
  bool _initialized = false;

  static const List<Map<String, String>> _templates = [
    {'id': 'minimal', 'name': 'Minimal (Free)'},
    {'id': 'standard_blue', 'name': 'Standard Blue (Free)'},
    {'id': 'modern_green', 'name': 'Modern Green (Free)'},
    {'id': 'navy_gold', 'name': 'Navy & Gold (Pro)'},
    {'id': 'professional_grey', 'name': 'Professional Grey (Pro)'},
    {'id': 'elegant_teal', 'name': 'Elegant Teal (Pro)'},
    {'id': 'modern_orange', 'name': 'Modern Orange (Pro)'},
    {'id': 'dark_premium', 'name': 'Dark Premium (Pro)'},
    {'id': 'construction', 'name': 'Construction (Pro)'},
    {'id': 'professional_red', 'name': 'Professional Red (Pro)'},
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final business = context.read<AuthProvider>().activeBusiness;

    if (business != null) {
      _loadBusinessSettings(business);
    }

    _initialized = true;
  }

  void _loadBusinessSettings(Business business) {
    _bankNameController.text = business.bankName;
    _accountNameController.text = business.bankAccountName;
    _accountNumberController.text = business.bankAccountNumber;
    _branchController.text = business.bankBranch;
    _branchCodeController.text = business.bankBranchCode;
    _paymentInstructionsController.text = business.paymentInstructions;

    _logoBase64 = business.logoBase64;

    final savedTemplate = business.defaultQuotationTemplate;
    _template = _templates.any((item) => item['id'] == savedTemplate)
        ? savedTemplate
        : 'minimal';
  }

  Future<void> _pickLogo() async {
    try {
      setState(() => _isPickingLogo = true);

      final file = await FilePicker.pickFile(
        type: FileType.image,
      );

      if (file == null) return;

      final extension = file.extension?.toLowerCase();

      if (!['png', 'jpg', 'jpeg'].contains(extension)) {
        throw Exception('Please select a PNG or JPG image.');
      }

      final fileSize = await file.length();

      if (fileSize != null && fileSize > 500 * 1024) {
        throw Exception('Please select a logo smaller than 500 KB.');
      }

      final bytes = await file.readAsBytes();

      if (bytes.length > 500 * 1024) {
        throw Exception('Please select a logo smaller than 500 KB.');
      }

      setState(() {
        _logoBase64 = base64Encode(bytes);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo selected successfully.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingLogo = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final business = authProvider.activeBusiness;

    if (business == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active business found.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _businessService.updateBusinessBranding(
        businessId: business.id,
        logoBase64: _logoBase64,
        defaultQuotationTemplate: _template,
        bankName: _bankNameController.text,
        bankAccountName: _accountNameController.text,
        bankAccountNumber: _accountNumberController.text,
        bankBranch: _branchController.text,
        bankBranchCode: _branchCodeController.text,
        paymentInstructions: _paymentInstructionsController.text,
      );

      if (!mounted) return;

      await authProvider.refreshSession();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quotation settings saved successfully.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save settings: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    String? hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final business = context.watch<AuthProvider>().activeBusiness;

    if (business == null) {
      return const Center(
        child: Text('Please select a business first.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            Text(
              'Business settings',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your quotation branding and payment information.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(
                      'Company information',
                      'These details will appear on your quotations.',
                    ),
                    const SizedBox(height: 16),
                    Text(
                      business.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(business.address),
                    Text(business.phone),
                    Text(business.email),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(
                      'Company logo',
                      'Your logo will automatically fit into the quotation header.',
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 180,
                      height: 120,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _logoBase64.isEmpty
                          ? const Text('No logo selected')
                          : Image.memory(
                              base64Decode(_logoBase64),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Text('Invalid logo image'),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _isPickingLogo ? null : _pickLogo,
                          icon: const Icon(Icons.upload_file),
                          label: Text(
                            _isPickingLogo ? 'Selecting...' : 'Choose logo',
                          ),
                        ),
                        if (_logoBase64.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() => _logoBase64 = '');
                            },
                            child: const Text('Remove logo'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'PNG or JPG only. Maximum file size: 500 KB.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(
                      'Default quotation template',
                      'Choose the design used by default for your quotations.',
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _template,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Quotation design',
                        border: OutlineInputBorder(),
                      ),
                      items: _templates.map((item) {
                        return DropdownMenuItem<String>(
                          value: item['id'],
                          child: Text(item['name']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _template = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(
                      'Bank details',
                      'Customers will see these details when they receive your quotation.',
                    ),
                    const SizedBox(height: 16),
                    _textField(_bankNameController, 'Bank name'),
                    const SizedBox(height: 12),
                    _textField(_accountNameController, 'Account name'),
                    const SizedBox(height: 12),
                    _textField(_accountNumberController, 'Account number'),
                    const SizedBox(height: 12),
                    _textField(_branchController, 'Branch (optional)'),
                    const SizedBox(height: 12),
                    _textField(
                      _branchCodeController,
                      'Branch code (optional)',
                    ),
                    const SizedBox(height: 12),
                    _textField(
                      _paymentInstructionsController,
                      'Payment instructions (optional)',
                      hint: 'Example: Please use quotation number as reference.',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _saveSettings,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _isSaving ? 'Saving...' : 'Save quotation settings',
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _branchController.dispose();
    _branchCodeController.dispose();
    _paymentInstructionsController.dispose();
    super.dispose();
  }
}
