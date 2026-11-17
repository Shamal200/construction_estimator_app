import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/material_item.dart';
import '../providers/auth_provider.dart';
import '../services/material_service.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  final MaterialService _service = MaterialService();
  String _search = '';
  bool _includeInactive = false;

  @override
  Widget build(BuildContext context) {
    final businessId = context.watch<AuthProvider>().activeBusiness?.id;

    if (businessId == null || businessId.isEmpty) {
      return const Center(
        child: Text('Select an active business to manage boards.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 12,
            spacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Board materials',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sheet boards, thicknesses, sizes and prices for joinery.',
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: () => _editBoard(context, businessId),
                icon: const Icon(Icons.add),
                label: const Text('Add board'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    setState(() => _search = value.trim().toLowerCase());
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search board name, type or thickness',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilterChip(
                label: Text(
                  _includeInactive ? 'Including inactive' : 'Active only',
                ),
                selected: _includeInactive,
                onSelected: (value) {
                  setState(() => _includeInactive = value);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<MaterialItem>>(
              stream: _service.watchMaterials(businessId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Could not load boards: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final all = snapshot.data!;
                final rows = all.where((material) {
                  if (!_includeInactive && !material.isActive) {
                    return false;
                  }

                  return material.name.toLowerCase().contains(_search) ||
                      material.boardType.toLowerCase().contains(_search) ||
                      material.thicknessMm.toString().contains(_search);
                }).toList();

                if (rows.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 44),
                        const SizedBox(height: 10),
                        Text(
                          all.isEmpty
                              ? 'No board materials added yet.'
                              : 'No matching boards.',
                        ),
                        const SizedBox(height: 5),
                        Text(
                          all.isEmpty
                              ? 'Add your first plywood, PVC or Melteca sheet.'
                              : 'Try a different search.',
                        ),
                      ],
                    ),
                  );
                }

                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final material = rows[index];
                      final sizeKnown = material.sheetLengthMm > 0 &&
                          material.sheetWidthMm > 0;
                      final thickness = material.thicknessMm > 0
                          ? '${_fmt(material.thicknessMm)} mm'
                          : 'Thickness not set';
                      final size = sizeKnown
                          ? '${_fmt(material.sheetLengthMm)} × '
                              '${_fmt(material.sheetWidthMm)} mm'
                          : 'Sheet size not set';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        leading: CircleAvatar(
                          child: Text(
                            material.thicknessMm > 0
                                ? _fmt(material.thicknessMm)
                                : '—',
                          ),
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                material.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (!material.isActive) ...[
                              const SizedBox(width: 8),
                              const Chip(
                                label: Text('Inactive'),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          '${material.boardType} • $thickness • $size'
                          '${material.supplier.isNotEmpty ? '\nSupplier: ${material.supplier}' : ''}',
                        ),
                        isThreeLine: material.supplier.isNotEmpty,
                        trailing: SizedBox(
                          width: 145,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Text(
                                  'FJD ${material.cost.toStringAsFixed(2)}',
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (action) async {
                                  if (action == 'edit') {
                                    await _editBoard(
                                      context,
                                      businessId,
                                      existing: material,
                                    );
                                  } else if (action == 'toggle') {
                                    await _toggleActive(businessId, material);
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit board'),
                                  ),
                                  PopupMenuItem(
                                    value: 'toggle',
                                    child: Text(
                                      material.isActive
                                          ? 'Deactivate'
                                          : 'Activate',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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

  Future<void> _editBoard(
    BuildContext context,
    String businessId, {
    MaterialItem? existing,
  }) async {
    final result = await showDialog<MaterialItem>(
      context: context,
      builder: (_) => _BoardDialog(existing: existing),
    );

    if (result == null || !context.mounted) return;

    try {
      await _service.saveMaterial(
        businessId: businessId,
        material: result,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing == null ? 'Board added.' : 'Board updated.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $error')),
      );
    }
  }

  Future<void> _toggleActive(
    String businessId,
    MaterialItem item,
  ) async {
    try {
      await _service.setMaterialActive(
        businessId: businessId,
        materialId: item.id,
        isActive: !item.isActive,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $error')),
      );
    }
  }

  static String _fmt(double number) {
    return number.toStringAsFixed(number % 1 == 0 ? 0 : 1);
  }
}

class _BoardDialog extends StatefulWidget {
  const _BoardDialog({this.existing});

  final MaterialItem? existing;

  @override
  State<_BoardDialog> createState() => _BoardDialogState();
}

class _BoardDialogState extends State<_BoardDialog> {
  final _key = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _thickness;
  late final TextEditingController _length;
  late final TextEditingController _width;
  late final TextEditingController _price;
  late final TextEditingController _supplier;
  late final TextEditingController _notes;

  late String _type;

  static const _types = [
    'Plywood',
    'PVC Board',
    'Melteca',
    'MDF',
    'Particle Board',
    'Other Sheet Board',
  ];

  @override
  void initState() {
    super.initState();

    final material = widget.existing;
    _type = material?.boardType ?? 'Plywood';
    _name = TextEditingController(text: material?.name ?? '');
    _thickness = TextEditingController(
      text: material != null && material.thicknessMm > 0
          ? _fmt(material.thicknessMm)
          : '16',
    );
    _length = TextEditingController(
      text: material != null && material.sheetLengthMm > 0
          ? _fmt(material.sheetLengthMm)
          : '2440',
    );
    _width = TextEditingController(
      text: material != null && material.sheetWidthMm > 0
          ? _fmt(material.sheetWidthMm)
          : '1220',
    );
    _price = TextEditingController(
      text: material?.cost.toStringAsFixed(2) ?? '',
    );
    _supplier = TextEditingController(text: material?.supplier ?? '');
    _notes = TextEditingController(text: material?.notes ?? '');
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _thickness,
      _length,
      _width,
      _price,
      _supplier,
      _notes,
    ]) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null
            ? 'Add board material'
            : 'Edit board material',
      ),
      content: SizedBox(
        width: 470,
        child: SingleChildScrollView(
          child: Form(
            key: _key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Board name',
                    hintText: 'e.g. White Matte PVC 16mm',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Board type'),
                  items: _types
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _type = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _thickness,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Thickness (mm)',
                  ),
                  validator: (value) => _positive(value, 'Thickness'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _length,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Sheet length (mm)',
                        ),
                        validator: (value) =>
                            _positive(value, 'Sheet length'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _width,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Sheet width (mm)',
                        ),
                        validator: (value) => _positive(value, 'Sheet width'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _price,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Price per sheet (FJD)',
                    prefixText: 'FJD ',
                  ),
                  validator: (value) => _nonNegative(value, 'Price'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _supplier,
                  decoration: const InputDecoration(
                    labelText: 'Supplier (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notes,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'All dimensions are in millimetres. Default sheet size is '
                  '2440 × 1220 mm and can be changed.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save board'),
        ),
      ],
    );
  }

  void _save() {
    if (!_key.currentState!.validate()) return;

    final oldMaterial = widget.existing;

    Navigator.pop(
      context,
      MaterialItem(
        id: oldMaterial?.id ?? '',
        name: _name.text.trim(),
        category: 'Board',
        unit: 'sheet',
        cost: double.parse(_price.text.trim()),
        boardType: _type,
        thicknessMm: double.parse(_thickness.text.trim()),
        sheetLengthMm: double.parse(_length.text.trim()),
        sheetWidthMm: double.parse(_width.text.trim()),
        supplier: _supplier.text.trim(),
        notes: _notes.text.trim(),
        isActive: oldMaterial?.isActive ?? true,
      ),
    );
  }

  static String? _required(String? value) {
    return value == null || value.trim().isEmpty
        ? 'This field is required.'
        : null;
  }

  static String? _positive(String? value, String label) {
    final number = double.tryParse((value ?? '').trim());

    return number == null || !number.isFinite || number <= 0
        ? '$label must be greater than zero.'
        : null;
  }

  static String? _nonNegative(String? value, String label) {
    final number = double.tryParse((value ?? '').trim());

    return number == null || !number.isFinite || number < 0
        ? '$label must be zero or more.'
        : null;
  }

  static String _fmt(double number) {
    return number.toStringAsFixed(number % 1 == 0 ? 0 : 1);
  }
}
