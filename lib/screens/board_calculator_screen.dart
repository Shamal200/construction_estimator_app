import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/material_item.dart';
import '../providers/auth_provider.dart';
import '../services/material_service.dart';

enum _CarcassType { groundBase, overheadWall, tallPantry }

class BoardCalculatorScreen extends StatefulWidget {
  const BoardCalculatorScreen({super.key});

  @override
  State<BoardCalculatorScreen> createState() =>
      _BoardCalculatorScreenState();
}

class _BoardCalculatorScreenState extends State<BoardCalculatorScreen> {
  final MaterialService _materialService = MaterialService();

  final _length = TextEditingController(text: '1200');
  final _height = TextEditingController(text: '780');
  final _depth = TextEditingController(text: '560');
  final _shelves = TextEditingController(text: '1');
  final _quantity = TextEditingController(text: '1');

  _CarcassType _type = _CarcassType.groundBase;
  String? _mainBoardId;
  String? _backBoardId;
  bool _pantryNailers = false;

  final List<_CarcassEntry> _carcasses = [];

  @override
  void dispose() {
    _length.dispose();
    _height.dispose();
    _depth.dispose();
    _shelves.dispose();
    _quantity.dispose();
    super.dispose();
  }

  double _number(TextEditingController controller, double fallback) {
    final value = double.tryParse(controller.text.trim());
    return value != null && value.isFinite ? value : fallback;
  }

  String _fmt(double value) =>
      value.toStringAsFixed(value % 1 == 0 ? 0 : 1);

  String _typeName(_CarcassType type) {
    switch (type) {
      case _CarcassType.groundBase:
        return 'Ground / Base';
      case _CarcassType.overheadWall:
        return 'Overhead / Wall';
      case _CarcassType.tallPantry:
        return 'Tall Pantry';
    }
  }

  void _selectType(_CarcassType? type) {
    if (type == null) return;

    setState(() {
      _type = type;

      switch (type) {
        case _CarcassType.groundBase:
          _length.text = '1200';
          _height.text = '780';
          _depth.text = '560';
          _shelves.text = '1';
          break;

        case _CarcassType.overheadWall:
          _length.text = '800';
          _height.text = '720';
          _depth.text = '350';
          _shelves.text = '1';
          break;

        case _CarcassType.tallPantry:
          _length.text = '600';
          _height.text = '2000';
          _depth.text = '600';
          _shelves.text = '4';
          break;
      }
    });
  }

  void _addCarcass() {
    final length = _number(_length, 0);
    final height = _number(_height, 0);
    final depth = _number(_depth, 0);
    final shelves = _number(_shelves, -1).round();
    final quantity = _number(_quantity, 0).round();

    if ([length, height, depth].any((v) => !v.isFinite || v <= 0) ||
        shelves < 0 ||
        shelves > 50 ||
        quantity < 1 ||
        quantity > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter valid dimensions, 0–50 shelves and quantity 1–500.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _carcasses.add(
        _CarcassEntry(
          type: _type,
          length: length,
          height: height,
          depth: depth,
          shelves: shelves,
          quantity: quantity,
          pantryNailers:
              _type == _CarcassType.tallPantry && _pantryNailers,
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Carcass added to this project.')),
    );
  }

  void _removeCarcass(int index) {
    setState(() => _carcasses.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final businessId =
        context.watch<AuthProvider>().activeBusiness?.id;

    if (businessId == null || businessId.isEmpty) {
      return const Center(
        child: Text(
          'Select an active business to use the board calculator.',
        ),
      );
    }

    return StreamBuilder<List<MaterialItem>>(
      stream: _materialService.watchMaterials(businessId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Could not load board inventory: ${snapshot.error}',
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final boards = snapshot.data!
            .where(
              (board) =>
                  board.isActive &&
                  board.sheetLengthMm > 0 &&
                  board.sheetWidthMm > 0 &&
                  board.thicknessMm > 0,
            )
            .toList();

        if (boards.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Add an active board in Board Materials first. '
                'The calculator needs its thickness and sheet dimensions.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (_mainBoardId == null ||
            !boards.any((board) => board.id == _mainBoardId)) {
          _mainBoardId = boards.first.id;
        }

        final mainBoard =
            boards.firstWhere((board) => board.id == _mainBoardId);

        final backBoards = boards
            .where(
              (board) => (board.thicknessMm - 4).abs() < 0.01,
            )
            .toList();

        if (_backBoardId == null ||
            !backBoards.any((board) => board.id == _backBoardId)) {
          _backBoardId =
              backBoards.isEmpty ? null : backBoards.first.id;
        }

        final backBoard = backBoards
            .where((board) => board.id == _backBoardId)
            .firstOrNull;

        final projectResult = _buildProjectCutList(
          _carcasses,
          mainBoard.thicknessMm,
          backBoard?.thicknessMm,
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Joinery Project Calculator',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Add multiple carcasses, then generate one combined '
                    'cutting list. All measurements are in millimetres.',
                  ),
                  const SizedBox(height: 18),

                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _addCarcassCard(
                            boards,
                            backBoards,
                            mainBoard,
                            backBoard,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _projectSummary(
                            projectResult,
                            mainBoard,
                            backBoard,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _addCarcassCard(
                      boards,
                      backBoards,
                      mainBoard,
                      backBoard,
                    ),
                    const SizedBox(height: 16),
                    _projectSummary(
                      projectResult,
                      mainBoard,
                      backBoard,
                    ),
                  ],

                  const SizedBox(height: 18),
                  _carcassItemsCard(),
                  const SizedBox(height: 18),
                  _combinedCuttingList(
                    projectResult,
                    backBoard == null,
                  ),
                  const SizedBox(height: 16),
                  _projectNotes(mainBoard, backBoard),
                ],
              ),
            );
          },
        );
      },
    );
  }
    Widget _addCarcassCard(
    List<MaterialItem> boards,
    List<MaterialItem> backBoards,
    MaterialItem mainBoard,
    MaterialItem? backBoard,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add a carcass',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),

            DropdownButtonFormField<_CarcassType>(
              initialValue: _type,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Carcass type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: _CarcassType.groundBase,
                  child: Text('Ground / Base'),
                ),
                DropdownMenuItem(
                  value: _CarcassType.overheadWall,
                  child: Text('Overhead / Wall'),
                ),
                DropdownMenuItem(
                  value: _CarcassType.tallPantry,
                  child: Text('Tall Pantry'),
                ),
              ],
              onChanged: _selectType,
            ),

            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              initialValue: _mainBoardId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Main carcass board',
                border: OutlineInputBorder(),
              ),
              items: boards.map((board) {
                return DropdownMenuItem(
                  value: board.id,
                  child: Text(
                    '${board.name} • ${_fmt(board.thicknessMm)} mm',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _mainBoardId = value);
              },
            ),

            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              initialValue: _backBoardId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: '4 mm backboard material',
                border: OutlineInputBorder(),
              ),
              hint: const Text('Select a 4 mm board'),
              items: backBoards.map((board) {
                return DropdownMenuItem(
                  value: board.id,
                  child: Text(
                    board.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: backBoards.isEmpty
                  ? null
                  : (value) {
                      setState(() => _backBoardId = value);
                    },
            ),

            if (backBoards.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Add an active 4 mm board in Materials to include backboards.',
                  style: TextStyle(color: Colors.red),
                ),
              ),

            const SizedBox(height: 14),

            _field(_length, 'Length (L)', '1200'),
            const SizedBox(height: 10),
            _field(_height, 'Height (H)', '780'),
            const SizedBox(height: 10),
            _field(_depth, 'Depth (D)', '560'),
            const SizedBox(height: 10),
            _field(_shelves, 'Number of shelves', '1', unit: ''),
            const SizedBox(height: 10),
            _field(
              _quantity,
              'Number of identical carcasses',
              '1',
              unit: '',
            ),

            if (_type == _CarcassType.tallPantry)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _pantryNailers,
                onChanged: (value) {
                  setState(() => _pantryNailers = value ?? false);
                },
                title: const Text('Include two 100 mm nailers'),
                controlAffinity: ListTileControlAffinity.leading,
              ),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _addCarcass,
                icon: const Icon(Icons.add),
                label: const Text('Add carcass to project'),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Main board: ${mainBoard.name} '
              '(${_fmt(mainBoard.thicknessMm)} mm). '
              'Backboard: ${backBoard?.name ?? '4 mm board not selected'}.',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String hint, {
    String unit = 'mm',
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: unit.isEmpty ? null : unit,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  Widget _projectSummary(
    _ProjectCutList result,
    MaterialItem mainBoard,
    MaterialItem? backBoard,
  ) {
    final carcassCount = _carcasses.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Project summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),

            _summaryRow(
              'Different carcass entries',
              '${_carcasses.length}',
            ),
            _summaryRow(
              'Total carcass units',
              '$carcassCount',
            ),
            _summaryRow('Main board', mainBoard.name),
            _summaryRow(
              'Main board thickness',
              '${_fmt(mainBoard.thicknessMm)} mm',
            ),
            _summaryRow(
              '4 mm backboard',
              backBoard?.name ?? 'Not selected',
            ),
            _summaryRow(
              'Total main-board panels',
              result.valid ? '${result.mainPanelCount}' : '—',
            ),
            _summaryRow(
              'Total back panels',
              result.valid ? '${result.backPanelCount}' : '—',
            ),
            _summaryRow(
              'Combined panel area',
              result.valid ? '${_fmt(result.totalAreaM2)} m²' : '—',
            ),

            const Divider(height: 24),

            if (!result.valid)
              Text(
                result.error,
                style: const TextStyle(color: Colors.red),
              ),

            const Text(
              'This stage combines all carcass components. Exact sheet '
              'quantity and offcut nesting will be added after the '
              'combined cutting list is tested.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _carcassItemsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Carcasses in this project',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton.icon(
                  onPressed: _carcasses.isEmpty
                      ? null
                      : () => setState(_carcasses.clear),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear all'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (_carcasses.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No carcasses added yet. Use the form above '
                  'to add your first carcass.',
                ),
              )
            else
              ..._carcasses.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text(
                    '${_typeName(item.type)} × ${item.quantity}',
                  ),
                  subtitle: Text(
                    'L ${_fmt(item.length)} × '
                    'H ${_fmt(item.height)} × '
                    'D ${_fmt(item.depth)} mm'
                    ' • ${item.shelves} shelves each',
                  ),
                  trailing: IconButton(
                    tooltip: 'Remove carcass',
                    onPressed: () => _removeCarcass(index),
                    icon: const Icon(Icons.delete_outline),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _combinedCuttingList(
    _ProjectCutList result,
    bool noBackMaterial,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Combined project cutting list',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            const Text(
              'Identical dimensions and thicknesses are grouped '
              'together across all carcasses.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),

            if (_carcasses.isEmpty)
              const Text(
                'Add carcasses to generate the combined cutting list.',
              )
            else if (!result.valid)
              Text(
                result.error,
                style: const TextStyle(color: Colors.red),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Component')),
                    DataColumn(label: Text('Length (mm)')),
                    DataColumn(label: Text('Width (mm)')),
                    DataColumn(label: Text('Thickness')),
                    DataColumn(label: Text('Total Qty')),
                  ],
                  rows: result.parts.map((part) {
                    return DataRow(
                      cells: [
                        DataCell(Text(part.name)),
                        DataCell(Text(_fmt(part.length))),
                        DataCell(Text(_fmt(part.width))),
                        DataCell(
                          Text('${_fmt(part.thickness)} mm'),
                        ),
                        DataCell(Text('${part.quantity}')),
                      ],
                    );
                  }).toList(),
                ),
              ),

            if (noBackMaterial && _carcasses.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'Back panels are not included because a 4 mm board '
                  'is not selected in inventory.',
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _projectNotes(
    MaterialItem mainBoard,
    MaterialItem? backBoard,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calculation rules',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),

            const Text(
              'Ground/base: bottom is full outside length × depth; '
              'sides are height minus bottom and rail thickness; '
              'shelves fit between sides; two 100 mm rails run full outside length.\n\n'
              'Overhead/wall: full-height sides; top, bottom, shelves '
              'and two 100 mm nailers fit between sides.\n\n'
              'Tall pantry: full-height sides; top, bottom and shelves '
              'fit between sides; two 100 mm nailers are optional.\n\n'
              'All carcasses receive one separate full outside-size 4 mm back panel.',
            ),

            const SizedBox(height: 8),

            Text(
              'Main board: ${mainBoard.name}. '
              'Backboard: ${backBoard?.name ?? 'not selected'}. '
              'All quantities in the combined cutting list include '
              'each carcass entry quantity.',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
    Widget _summaryRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label)),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

  static _ProjectCutList _buildProjectCutList(
    List<_CarcassEntry> entries,
    double thickness,
    double? backThickness,
  ) {
    if (entries.isEmpty) {
      return const _ProjectCutList.empty();
    }

    if (!thickness.isFinite || thickness <= 0) {
      return _ProjectCutList.invalid(
        'The selected main board has an invalid thickness.',
      );
    }

    final allParts = <_CutPart>[];

    var mainPanelCount = 0;
    var backPanelCount = 0;
    var totalArea = 0.0;

    for (final entry in entries) {
      final l = entry.length;
      final h = entry.height;
      final d = entry.depth;

      final betweenSides = l - (2 * thickness);

      if ([l, h, d].any((v) => !v.isFinite || v <= 0) ||
          betweenSides <= 0) {
        return _ProjectCutList.invalid(
          'One of the carcasses has invalid dimensions '
          'for the selected board thickness.',
        );
      }

      final parts = <_CutPart>[];

      switch (entry.type) {
        case _CarcassType.groundBase:
          final sideHeight = h - (2 * thickness);

          if (sideHeight <= 0) {
            return _ProjectCutList.invalid(
              'A ground/base carcass is too short for '
              'the selected board thickness.',
            );
          }

          parts.add(
            _CutPart('Ground bottom', l, d, thickness, 1),
          );

          parts.add(
            _CutPart('Ground sides', sideHeight, d, thickness, 2),
          );

          parts.add(
            _CutPart(
              'Ground front/rear rails',
              l,
              100,
              thickness,
              2,
            ),
          );

          if (entry.shelves > 0) {
            parts.add(
              _CutPart(
                'Ground shelves',
                betweenSides,
                d,
                thickness,
                entry.shelves,
              ),
            );
          }
          break;

        case _CarcassType.overheadWall:
          parts.add(
            _CutPart('Overhead sides', h, d, thickness, 2),
          );

          parts.add(
            _CutPart(
              'Overhead top/bottom',
              betweenSides,
              d,
              thickness,
              2,
            ),
          );

          if (entry.shelves > 0) {
            parts.add(
              _CutPart(
                'Overhead shelves',
                betweenSides,
                d,
                thickness,
                entry.shelves,
              ),
            );
          }

          parts.add(
            _CutPart(
              'Overhead nailers',
              betweenSides,
              100,
              thickness,
              2,
            ),
          );
          break;

        case _CarcassType.tallPantry:
          parts.add(
            _CutPart('Pantry sides', h, d, thickness, 2),
          );

          parts.add(
            _CutPart(
              'Pantry top/bottom',
              betweenSides,
              d,
              thickness,
              2,
            ),
          );

          if (entry.shelves > 0) {
            parts.add(
              _CutPart(
                'Pantry shelves',
                betweenSides,
                d,
                thickness,
                entry.shelves,
              ),
            );
          }

          if (entry.pantryNailers) {
            parts.add(
              _CutPart(
                'Pantry nailers',
                betweenSides,
                100,
                thickness,
                2,
              ),
            );
          }
          break;
      }

      // Multiply every component by the number of identical carcasses.
      for (final part in parts) {
        final totalQty = part.quantity * entry.quantity;

        allParts.add(
          part.copyWith(quantity: totalQty),
        );

        mainPanelCount += totalQty;

        totalArea +=
            part.length * part.width * totalQty;
      }

      // Each carcass receives one separate full-size 4 mm back.
      if (backThickness != null && backThickness > 0) {
        allParts.add(
          _CutPart(
            '4 mm full back panel',
            l,
            h,
            backThickness,
            entry.quantity,
          ),
        );

        backPanelCount += entry.quantity;

        totalArea += l * h * entry.quantity;
      }
    }

    return _ProjectCutList(
      valid: true,
      error: '',
      parts: _groupParts(allParts),
      mainPanelCount: mainPanelCount,
      backPanelCount: backPanelCount,
      totalAreaM2: totalArea / 1000000,
    );
  }

  static List<_CutPart> _groupParts(List<_CutPart> parts) {
    final grouped = <String, _CutPart>{};

    for (final part in parts) {
      final key =
          '${part.length.toStringAsFixed(2)}|'
          '${part.width.toStringAsFixed(2)}|'
          '${part.thickness.toStringAsFixed(2)}';

      final existing = grouped[key];

      if (existing == null) {
        grouped[key] = part;
      } else {
        grouped[key] = _CutPart(
          '${existing.name} / ${part.name}',
          existing.length,
          existing.width,
          existing.thickness,
          existing.quantity + part.quantity,
        );
      }
    }

    return grouped.values.toList();
  }
}

class _CarcassEntry {
  const _CarcassEntry({
    required this.type,
    required this.length,
    required this.height,
    required this.depth,
    required this.shelves,
    required this.quantity,
    required this.pantryNailers,
  });

  final _CarcassType type;
  final double length;
  final double height;
  final double depth;
  final int shelves;
  final int quantity;
  final bool pantryNailers;
}

class _CutPart {
  const _CutPart(
    this.name,
    this.length,
    this.width,
    this.thickness,
    this.quantity,
  );

  final String name;
  final double length;
  final double width;
  final double thickness;
  final int quantity;

  _CutPart copyWith({int? quantity}) {
    return _CutPart(
      name,
      length,
      width,
      thickness,
      quantity ?? this.quantity,
    );
  }
}

class _ProjectCutList {
  const _ProjectCutList({
    required this.valid,
    required this.error,
    this.parts = const [],
    this.mainPanelCount = 0,
    this.backPanelCount = 0,
    this.totalAreaM2 = 0,
  });

  const _ProjectCutList.empty()
      : valid = true,
        error = '',
        parts = const [],
        mainPanelCount = 0,
        backPanelCount = 0,
        totalAreaM2 = 0;

  factory _ProjectCutList.invalid(String error) {
    return _ProjectCutList(
      valid: false,
      error: error,
    );
  }

  final bool valid;
  final String error;
  final List<_CutPart> parts;
  final int mainPanelCount;
  final int backPanelCount;
  final double totalAreaM2;
}