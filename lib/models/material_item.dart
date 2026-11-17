class MaterialItem {
  const MaterialItem({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.cost,
    this.boardType = 'Plywood',
    this.thicknessMm = 0,
    this.sheetLengthMm = 0,
    this.sheetWidthMm = 0,
    this.supplier = '',
    this.notes = '',
    this.isActive = true,
  });

  final String id;
  final String name;
  final String category;
  final String unit;
  final double cost;
  final String boardType;
  final double thicknessMm;
  final double sheetLengthMm;
  final double sheetWidthMm;
  final String supplier;
  final String notes;
  final bool isActive;

  MaterialItem copyWith({
    String? id, String? name, String? category, String? unit, double? cost,
    String? boardType, double? thicknessMm, double? sheetLengthMm,
    double? sheetWidthMm, String? supplier, String? notes, bool? isActive,
  }) => MaterialItem(
    id: id ?? this.id,
    name: name ?? this.name,
    category: category ?? this.category,
    unit: unit ?? this.unit,
    cost: cost ?? this.cost,
    boardType: boardType ?? this.boardType,
    thicknessMm: thicknessMm ?? this.thicknessMm,
    sheetLengthMm: sheetLengthMm ?? this.sheetLengthMm,
    sheetWidthMm: sheetWidthMm ?? this.sheetWidthMm,
    supplier: supplier ?? this.supplier,
    notes: notes ?? this.notes,
    isActive: isActive ?? this.isActive,
  );

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'category': category, 'unit': unit, 'cost': cost,
    'boardType': boardType, 'thicknessMm': thicknessMm,
    'sheetLengthMm': sheetLengthMm, 'sheetWidthMm': sheetWidthMm,
    'supplier': supplier, 'notes': notes, 'isActive': isActive,
  };

  factory MaterialItem.fromMap(Map<String, dynamic> map) => MaterialItem(
    id: map['id'] as String? ?? '',
    name: map['name'] as String? ?? '',
    category: map['category'] as String? ?? 'Board',
    unit: map['unit'] as String? ?? 'sheet',
    cost: (map['cost'] as num?)?.toDouble() ?? 0,
    boardType: map['boardType'] as String? ?? map['category'] as String? ?? 'Plywood',
    thicknessMm: (map['thicknessMm'] as num?)?.toDouble() ?? 0,
    sheetLengthMm: (map['sheetLengthMm'] as num?)?.toDouble() ?? 0,
    sheetWidthMm: (map['sheetWidthMm'] as num?)?.toDouble() ?? 0,
    supplier: map['supplier'] as String? ?? '',
    notes: map['notes'] as String? ?? '',
    isActive: map['isActive'] as bool? ?? true,
  );
}
