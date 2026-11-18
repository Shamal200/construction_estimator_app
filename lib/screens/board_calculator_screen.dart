import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/material_item.dart';
import '../providers/auth_provider.dart';
import '../services/material_service.dart';

class BoardCalculatorScreen extends StatefulWidget {
  const BoardCalculatorScreen({super.key});

  @override
  State<BoardCalculatorScreen> createState() => _BoardCalculatorScreenState();
}

class _BoardCalculatorScreenState extends State<BoardCalculatorScreen> {
  final MaterialService _materialService = MaterialService();

  final TextEditingController _lengthController =
      TextEditingController(text: '1200');
  final TextEditingController _heightController =
      TextEditingController(text: '780');
  final TextEditingController _depthController =
      TextEditingController(text: '560');
  final TextEditingController _shelvesController =
      TextEditingController(text: '1');
  final TextEditingController _kerfController =
      TextEditingController(text: '2');
  final TextEditingController _wastageController =
      TextEditingController(text: '10');

  String? _mainBoardId;

  @override
  void dispose() {
    _lengthController.dispose();
    _heightController.dispose();
    _depthController.dispose();
    _shelvesController.dispose();
    _kerfController.dispose();
    _wastageController.dispose();
    super.dispose();
  }

  double _number(TextEditingController controller, double fallback) {
    final value = double.tryParse(controller.text.trim());
    return value != null && value.isFinite ? value : fallback;
  }

  @override
  Widget build(BuildContext context) {
    final businessId = context.watch<AuthProvider>().activeBusiness?.id;

    if (businessId == null || businessId.isEmpty) {
      return const Center(
        child: Text('Select an active business to use the board calculator.'),
      );
    }

    return StreamBuilder<List<MaterialItem>>(
      stream: _materialService.watchMaterials(businessId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Could not load board inventory: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final boards = snapshot.data!
            .where((board) =>
                board.isActive &&
                board.sheetLengthMm > 0 &&
                board.sheetWidthMm > 0 &&
                board.thicknessMm > 0)
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
        final selectedBoard =
            boards.firstWhere((board) => board.id == _mainBoardId);

        final length = _number(_lengthController, 1200);
        final height = _number(_heightController, 780);
        final depth = _number(_depthController, 560);
        final shelfCount = _number(_shelvesController, 1).round();
        final kerf = _number(_kerfController, 2);
        final wastage = _number(_wastageController, 10).clamp(0, 20).toDouble();

        final result = _calculate(
          length: length,
          height: height,
          depth: depth,
          thickness: selectedBoard.thicknessMm,
          shelves: shelfCount,
          sheetLength: selectedBoard.sheetLengthMm,
          sheetWidth: selectedBoard.sheetWidthMm,
          kerf: kerf,
          wastagePercent: wastage,
          sheetPrice: selectedBoard.cost,
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
                    'Ground / Base Carcass',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Board cutting calculator • All measurements in millimetres',
                  ),
                  const SizedBox(height: 18),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _inputCard(boards, selectedBoard)),
                        const SizedBox(width: 16),
                        Expanded(child: _summaryCard(result, selectedBoard)),
                      ],
                    )
                  else ...[
                    _inputCard(boards, selectedBoard),
                    const SizedBox(height: 16),
                    _summaryCard(result, selectedBoard),
                  ],
                  const SizedBox(height: 18),
                  _cuttingListCard(result),
                  const SizedBox(height: 18),
                  _sheetEstimateCard(result, selectedBoard),
                  const SizedBox(height: 16),
                  const Text(
                    'Calculation rules: bottom panel is full outside length × '
                    'depth; sides sit on the bottom and finish below the two '
                    'top rails; front and rear rails are each 100 mm wide and '
                    'full outside length; shelves fit between the sides.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _inputCard(List<MaterialItem> boards, MaterialItem selectedBoard) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Carcass details',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _mainBoardId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Main carcass board',
                border: OutlineInputBorder(),
              ),
              items: boards
                  .map((board) => DropdownMenuItem(
                        value: board.id,
                        child: Text(
                          '${board.name} • ${_fmt(board.thicknessMm)} mm • '
                          '${_fmt(board.sheetLengthMm)} × '
                          '${_fmt(board.sheetWidthMm)} mm',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: (value) => setState(() {
                _mainBoardId = value;
              }),
            ),
            const SizedBox(height: 14),
            _dimensionField(_lengthController, 'Length (L)', '1200'),
            const SizedBox(height: 10),
            _dimensionField(_heightController, 'Height (H)', '780'),
            const SizedBox(height: 10),
            _dimensionField(_depthController, 'Depth (D)', '560'),
            const SizedBox(height: 10),
            _dimensionField(_shelvesController, 'Number of shelves', '1', unit: ''),
            const Divider(height: 26),
            Text('Cutting settings',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _dimensionField(_kerfController, 'Saw kerf (mm)', '2'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _dimensionField(
                    _wastageController,
                    'Wastage (%)',
                    '10',
                    unit: '%',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => setState(() {}),
                icon: const Icon(Icons.calculate_outlined),
                label: const Text('Calculate cutting list'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selected board price: FJD ${selectedBoard.cost.toStringAsFixed(2)} '
              'per sheet',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dimensionField(
    TextEditingController controller,
    String label,
    String hint, {
    String unit = 'mm',
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: unit.isEmpty ? null : unit,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _summaryCard(_CarcassResult result, MaterialItem board) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Calculation summary',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            _summaryRow('Board thickness', '${_fmt(board.thicknessMm)} mm'),
            _summaryRow(
              'Side panel height',
              result.valid ? '${_fmt(result.sideHeight)} mm' : '—',
            ),
            _summaryRow(
              'Shelf length',
              result.valid ? '${_fmt(result.shelfLength)} mm' : '—',
            ),
            _summaryRow(
              'Sheets required',
              result.valid ? '${result.baseSheets}' : '—',
            ),
            _summaryRow(
              'Wastage allowance',
              '${_fmt(result.wastagePercent)}%',
            ),
            const Divider(height: 24),
            _summaryRow(
              'Estimated sheets',
              result.valid ? '${result.totalSheets}' : '—',
              bold: true,
            ),
            _summaryRow(
              'Estimated board cost',
              result.valid
                  ? 'FJD ${result.estimatedCost.toStringAsFixed(2)}'
                  : '—',
              bold: true,
            ),
            if (!result.valid) ...[
              const SizedBox(height: 10),
              Text(
                result.error,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _cuttingListCard(_CarcassResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cutting list',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (!result.valid)
              const Text('Enter valid dimensions to generate the cutting list.')
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Component')),
                    DataColumn(label: Text('Length (mm)')),
                    DataColumn(label: Text('Width (mm)')),
                    DataColumn(label: Text('Qty')),
                  ],
                  rows: result.parts
                      .map((part) => DataRow(cells: [
                            DataCell(Text(part.name)),
                            DataCell(Text(_fmt(part.length))),
                            DataCell(Text(_fmt(part.width))),
                            DataCell(Text('${part.quantity}')),
                          ]))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sheetEstimateCard(_CarcassResult result, MaterialItem board) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sheet estimate',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '${board.name} — ${_fmt(board.sheetLengthMm)} × '
              '${_fmt(board.sheetWidthMm)} mm',
            ),
            const SizedBox(height: 10),
            if (!result.valid)
              const Text('A sheet estimate will appear after valid dimensions.')
            else ...[
              _summaryRow('Panels to cut', '${result.panelCount}'),
              _summaryRow('Sheets required by workshop sequence', '${result.baseSheets} sheets'),
              _summaryRow('Wastage setting (shown separately)', '${_fmt(result.wastagePercent)}%'),
              const SizedBox(height: 12),
              Text('Workshop cutting sequence',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              ...result.cuttingSteps.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${entry.key + 1}. ',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text(entry.value)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Usable offcuts to retain',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              ...result.offcuts.map((offcut) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text('• $offcut'),
                  )),
              const SizedBox(height: 8),
              const Text(
                'This follows the agreed crosscut-first sequence. Check the '
                'marked dimensions against the actual saw fence, blade kerf, '
                'sheet orientation and usable board edges before cutting.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
          ),
          Text(value,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }

  static _CarcassResult _calculate({
    required double length,
    required double height,
    required double depth,
    required double thickness,
    required int shelves,
    required double sheetLength,
    required double sheetWidth,
    required double kerf,
    required double wastagePercent,
    required double sheetPrice,
  }) {
    if ([length, height, depth, thickness, sheetLength, sheetWidth, kerf]
            .any((v) => !v.isFinite || v <= 0) ||
        shelves < 0 ||
        shelves > 50 ||
        kerf < 0 ||
        !wastagePercent.isFinite ||
        wastagePercent < 0 ||
        !sheetPrice.isFinite ||
        sheetPrice < 0) {
      return _CarcassResult.invalid('Check dimensions, thickness and settings.');
    }

    final sideHeight = height - (2 * thickness);
    final shelfLength = length - (2 * thickness);
    if (sideHeight <= 0 || shelfLength <= 0) {
      return _CarcassResult.invalid(
        'Carcass dimensions are too small for the selected board thickness.',
      );
    }

    final parts = <_CutPart>[
      _CutPart('Bottom panel', length, depth, 1),
      _CutPart('Side panels', sideHeight, depth, 2),
     _CutPart('Rails (100 mm)', length, 100, 2),
      if (shelves > 0) _CutPart('Shelves', shelfLength, depth, shelves),
    ];

    final steps = <String>[];
    final offcuts = <String>[];

    // The agreed method treats the sheet as length x width. First crosscut
    // a depth-wide section from the sheet length. The bottom is nested in
    // that section with its 1200 mm side running across the 1220 mm width.
    if (depth + kerf >= sheetLength ||
        length + kerf > sheetWidth ||
        depth > sheetLength) {
      return _CarcassResult.invalid(
        'The bottom panel cannot be produced using the agreed first crosscut. '
        'Check sheet orientation and dimensions.',
      );
    }

    final bottomSectionWidthRemainder = sheetWidth - length - kerf;
    final bottomSectionLengthRemainder = depth;
    steps.add(
      'Sheet 1 — Cut 1: Crosscut a ${_fmt(depth)} mm section from the '
      '${_fmt(sheetLength)} mm sheet length. This creates a '
      '${_fmt(depth)} × ${_fmt(sheetWidth)} mm section for the bottom.',
    );
    steps.add(
      'Sheet 1 — Cut 2: From that section, cut the bottom panel at '
      '${_fmt(length)} × ${_fmt(depth)} mm. Keep the remaining '
      '${_fmt(bottomSectionWidthRemainder)} × ${_fmt(depth)} mm offcut.',
    );
    if (bottomSectionWidthRemainder > 0) {
      offcuts.add(
        'Sheet 1: ${_fmt(bottomSectionWidthRemainder)} × '
        '${_fmt(bottomSectionLengthRemainder)} mm (from the bottom section)',
      );
    }

    // Remaining main stock after the first crosscut.
    var remainingMainLength = sheetLength - depth - kerf;
    if (remainingMainLength <= 0) {
      return _CarcassResult.invalid('No usable sheet remains after the bottom section.');
    }

    // Crosscut the side-height section. Two side panels are ripped from it.
    final sideSectionWidthUsed = (2 * depth) + kerf;
    if (sideHeight + kerf > remainingMainLength ||
        sideSectionWidthUsed > sheetWidth) {
      return _CarcassResult.invalid(
        'The two side panels do not fit in the next crosscut section using '
        'your preferred crosscut-and-rip method.',
      );
    }

    remainingMainLength -= sideHeight + kerf;
    final sideWidthOffcut = sheetWidth - sideSectionWidthUsed;
    steps.add(
      'Sheet 1 — Cut 3: Crosscut ${_fmt(sideHeight)} mm from the remaining '
      'main sheet. Rip this ${_fmt(sideHeight)} × ${_fmt(sheetWidth)} mm '
      'section into two ${_fmt(sideHeight)} × ${_fmt(depth)} mm side panels.',
    );
    if (sideWidthOffcut > 0) {
      offcuts.add(
        'Sheet 1: ${_fmt(sideHeight)} × ${_fmt(sideWidthOffcut)} mm '
        '(beside the two side panels)',
      );
    }

    // Rotate the remaining main section to cut one shelf. In the rotated
    // orientation, the shelf's long side runs across the sheet width.
    var shelfFitsOnSheetOne = shelves == 0;
    if (shelves == 1) {
      shelfFitsOnSheetOne = depth + kerf <= remainingMainLength &&
          shelfLength + kerf <= sheetWidth;
      if (shelfFitsOnSheetOne) {
        final shelfCrosscutRemainder = remainingMainLength - depth - kerf;
        final shelfWidthRemainder = sheetWidth - shelfLength - kerf;
        steps.add(
          'Sheet 1 — Cut 4: Rotate the remaining stock. Cut the shelf at '
          '${_fmt(shelfLength)} × ${_fmt(depth)} mm, with the '
          '${_fmt(shelfLength)} mm side running across the sheet width.',
        );
        if (shelfCrosscutRemainder > 0) {
          offcuts.add(
            'Sheet 1: ${_fmt(shelfCrosscutRemainder)} × '
            '${_fmt(sheetWidth)} mm (remaining after shelf section)',
          );
        }
        if (shelfWidthRemainder > 0) {
          offcuts.add(
            'Sheet 1: ${_fmt(depth)} × '
            '${_fmt(shelfWidthRemainder)} mm (beside the shelf)',
          );
        }
      }
    } else if (shelves > 1) {
      shelfFitsOnSheetOne = false;
    }

    if (shelves == 1 && !shelfFitsOnSheetOne) {
      steps.add(
        'The shelf does not fit in the remaining Sheet 1 stock after the '
        'bottom and side cuts. Allocate it to additional sheet stock.',
      );
    }

    // Under this fixed sequence, the two 1200 x 100 mm rails are assigned
    // to Sheet 2. A 100 mm strip along the 2440 mm sheet length can supply
    // both rails if 2*length plus the separating kerf fits.
    if (2 * length + kerf > sheetLength || 100 + kerf > sheetWidth) {
      return _CarcassResult.invalid(
        'The two rails cannot be cut from one 100 mm strip of the selected '
        'sheet. A different rail layout or more stock is required.',
      );
    }

    steps.add(
      'Sheet 2 — Cut 5: Rip a 100 mm-wide strip along the sheet length. '
      'Crosscut two ${_fmt(length)} × 100 mm rails from this strip, '
      'allowing ${_fmt(kerf)} mm saw kerf between cuts.',
    );
    final railStripLengthRemainder = sheetLength - (2 * length) - kerf;
    if (railStripLengthRemainder > 0) {
      offcuts.add(
        'Sheet 2: ${_fmt(railStripLengthRemainder)} × 100 mm '
        '(end offcut from the rail strip)',
      );
    }
    offcuts.add(
      'Sheet 2: ${_fmt(sheetLength)} × '
      '${_fmt(sheetWidth - 100 - kerf)} mm (remaining beside the rail strip)',
    );

    // The fixed method is fully laid out for the standard single-shelf case.
    // Extra shelves are conservatively allocated one per additional sheet;
    // they are not claimed to be globally optimized.
    var sheets = 2;
    if (shelves > 1) {
      final extraShelves = shelves - 1;
      sheets += extraShelves;
      steps.add(
        'Additional shelves: $extraShelves extra shelf panel(s) are '
'conservatively allocated to $extraShelves additional sheet(s). '
        'Their individual offcut layouts have not yet been optimized.',
      );
    } else if (shelves == 1 && !shelfFitsOnSheetOne) {
      sheets += 1;
    }

    return _CarcassResult(
      valid: true,
      error: '',
      parts: parts,
      sideHeight: sideHeight,
      shelfLength: shelfLength,
      baseSheets: sheets,
      totalSheets: sheets,
      wastagePercent: wastagePercent,
      panelCount: parts.fold<int>(0, (sum, part) => sum + part.quantity),
      estimatedCost: sheets * sheetPrice,
      cuttingSteps: steps,
      offcuts: offcuts,
    );
  }

  static String _fmt(double value) =>
      value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
}

class _CutPart {
  const _CutPart(this.name, this.length, this.width, this.quantity);
  final String name;
  final double length;
  final double width;
  final int quantity;
}

class _CarcassResult {
  const _CarcassResult({
    required this.valid,
    required this.error,
    this.parts = const [],
    this.sideHeight = 0,
    this.shelfLength = 0,
    this.baseSheets = 0,
    this.totalSheets = 0,
    this.wastagePercent = 0,
    this.panelCount = 0,
    this.estimatedCost = 0,
    this.cuttingSteps = const [],
    this.offcuts = const [],
  });

  factory _CarcassResult.invalid(String error) =>
      _CarcassResult(valid: false, error: error);

  final bool valid;
  final String error;
  final List<_CutPart> parts;
  final double sideHeight;
  final double shelfLength;
  final int baseSheets;
  final int totalSheets;
  final double wastagePercent;
  final int panelCount;
  final double estimatedCost;
  final List<String> cuttingSteps;
  final List<String> offcuts;
}
