import 'quotation_item.dart';

class Quotation {
  const Quotation({
    required this.id,
    required this.quotationNumber,
    required this.customerId,
    required this.customerName,
    required this.projectName,
    required this.projectAddress,
    required this.description,
    required this.issueDate,
    required this.validUntil,
    required this.notes,
    required this.termsAndConditions,
    required this.items,
    required this.markupPercent,
    required this.discount,
    required this.taxPercent,
    required this.status,
  });

  final String id;
  final String quotationNumber;
  final String customerId;
  final String customerName;
  final String projectName;
  final String projectAddress;
  final String description;
  final DateTime issueDate;
  final DateTime validUntil;
  final String notes;
  final String termsAndConditions;
  final List<QuotationItem> items;
  final double markupPercent;
  final double discount;
  final double taxPercent;
  final String status;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quotationNumber': quotationNumber,
      'customerId': customerId,
      'customerName': customerName,
      'projectName': projectName,
      'projectAddress': projectAddress,
      'description': description,
      'issueDate': issueDate.toIso8601String(),
      'validUntil': validUntil.toIso8601String(),
      'notes': notes,
      'termsAndConditions': termsAndConditions,
      'items': items.map((item) => item.toMap()).toList(),
      'markupPercent': markupPercent,
      'discount': discount,
      'taxPercent': taxPercent,
      'status': status,
    };
  }

  factory Quotation.fromMap(Map<String, dynamic> map) {
    final items = (map['items'] as List? ?? const [])
        .map((item) => QuotationItem.fromMap(item as Map<String, dynamic>))
        .toList();

    return Quotation(
      id: map['id'] as String? ?? '',
      quotationNumber: map['quotationNumber'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      projectName: map['projectName'] as String? ?? '',
      projectAddress: map['projectAddress'] as String? ?? '',
      description: map['description'] as String? ?? '',
      issueDate: map['issueDate'] != null ? DateTime.parse(map['issueDate'] as String) : DateTime.now(),
      validUntil: map['validUntil'] != null ? DateTime.parse(map['validUntil'] as String) : DateTime.now(),
      notes: map['notes'] as String? ?? '',
      termsAndConditions: map['termsAndConditions'] as String? ?? '',
      items: items,
      markupPercent: (map['markupPercent'] as num?)?.toDouble() ?? 0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0,
      taxPercent: (map['taxPercent'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'Draft',
    );
  }
}
