class LabourRate {
  const LabourRate({
    required this.id,
    required this.description,
    required this.category,
    required this.unit,
    required this.rate,
    this.notes = '',
  });

  final String id;
  final String description;
  final String category;
  final String unit;
  final double rate;
  final String notes;

  LabourRate copyWith({
    String? id,
    String? description,
    String? category,
    String? unit,
    double? rate,
    String? notes,
  }) {
    return LabourRate(
      id: id ?? this.id,
      description: description ?? this.description,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      rate: rate ?? this.rate,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'category': category,
      'unit': unit,
      'rate': rate,
      'notes': notes,
    };
  }

  factory LabourRate.fromMap(Map<String, dynamic> map) {
    return LabourRate(
      id: map['id'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? '',
      unit: map['unit'] as String? ?? '',
      rate: (map['rate'] as num?)?.toDouble() ?? 0,
      notes: map['notes'] as String? ?? '',
    );
  }
}
