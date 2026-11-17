
class QuotationItem {
  const QuotationItem({
    required this.id,
    required this.name,
    this.description = '',
    required this.unit,
    required this.quantity,
    required this.materialCost,
    required this.labourCost,
    this.markupPercent = 0,
    this.discount = 0,
    this.taxPercent = 0,
  });

  final String id;
  final String name;
  final String description;
  final String unit;

  // Internal business costs
  final double quantity;
  final double materialCost;
  final double labourCost;

  // Private markup for this individual item
  final double markupPercent;

  final double discount;
  final double taxPercent;

  // Actual cost before markup
  double get unitRate => materialCost + labourCost;

  double get directCost => unitRate * quantity;

  // Private markup amount
  double get markupAmount =>
      directCost * markupPercent / 100;

  // Customer-facing selling price per unit
  double get sellingUnitRate =>
      unitRate * (1 + markupPercent / 100);

  // Customer-facing total for this item
  double get sellingTotal =>
      sellingUnitRate * quantity;

  double get subtotal =>
      directCost + markupAmount - discount;

  double get taxAmount =>
      subtotal * taxPercent / 100;

  double get total => subtotal + taxAmount;

  QuotationItem copyWith({
    String? id,
    String? name,
    String? description,
    String? unit,
    double? quantity,
    double? materialCost,
    double? labourCost,
    double? markupPercent,
    double? discount,
    double? taxPercent,
  }) {
    return QuotationItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      materialCost: materialCost ?? this.materialCost,
      labourCost: labourCost ?? this.labourCost,
      markupPercent: markupPercent ?? this.markupPercent,
      discount: discount ?? this.discount,
      taxPercent: taxPercent ?? this.taxPercent,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'unit': unit,
      'quantity': quantity,
      'materialCost': materialCost,
      'labourCost': labourCost,
      'markupPercent': markupPercent,
      'discount': discount,
      'taxPercent': taxPercent,
    };
  }

  factory QuotationItem.fromMap(Map<String, dynamic> map) {
    return QuotationItem(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      unit: map['unit'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      materialCost:
          (map['materialCost'] as num?)?.toDouble() ?? 0,
      labourCost:
          (map['labourCost'] as num?)?.toDouble() ?? 0,
      markupPercent:
          (map['markupPercent'] as num?)?.toDouble() ?? 0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0,
      taxPercent:
          (map['taxPercent'] as num?)?.toDouble() ?? 0,
    );
  }
}