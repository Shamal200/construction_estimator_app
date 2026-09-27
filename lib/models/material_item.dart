class MaterialItem {
  const MaterialItem({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.cost,
    this.supplier = '',
    this.notes = '',
    this.isActive = true,
  });

  final String id;
  final String name;
  final String category;
  final String unit;
  final double cost;
  final String supplier;
  final String notes;
  final bool isActive;

  MaterialItem copyWith({
    String? id,
    String? name,
    String? category,
    String? unit,
    double? cost,
    String? supplier,
    String? notes,
    bool? isActive,
  }) {
    return MaterialItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      cost: cost ?? this.cost,
      supplier: supplier ?? this.supplier,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'unit': unit,
      'cost': cost,
      'supplier': supplier,
      'notes': notes,
      'isActive': isActive,
    };
  }

  factory MaterialItem.fromMap(Map<String, dynamic> map) {
    return MaterialItem(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? '',
      unit: map['unit'] as String? ?? '',
      cost: (map['cost'] as num?)?.toDouble() ?? 0,
      supplier: map['supplier'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
    );
  }
}
