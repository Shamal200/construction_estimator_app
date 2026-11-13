import 'quotation_item.dart';

class Quotation {
  const Quotation({
    required this.id,
    required this.quotationNumber,
    required this.customerId,
    required this.customerName,
    this.customerNumber = '',
    this.customerCompany = '',
    this.customerPhone = '',
    this.customerEmail = '',
    this.customerAddress = '',
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
    this.currency = 'FJD',
  });

  final String id;
  final String quotationNumber;
  final String customerId;
  final String customerName;
  final String customerNumber;
  final String customerCompany;
  final String customerPhone;
  final String customerEmail;
  final String customerAddress;
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
  final String currency;

  double get directCost {
    return items.fold(0, (sum, item) => sum + item.directCost);
  }

  double get markupAmount {
    return directCost * markupPercent / 100;
  }

  double get subtotal {
    return directCost + markupAmount - discount;
  }

  double get taxAmount {
    return subtotal * taxPercent / 100;
  }

  double get grandTotal {
    return subtotal + taxAmount;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quotationNumber': quotationNumber,
      'customerId': customerId,
      'customerName': customerName,
      'customerNumber': customerNumber,
      'customerCompany': customerCompany,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'customerAddress': customerAddress,
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
      'currency': currency,
      'directCost': directCost,
      'markupAmount': markupAmount,
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'grandTotal': grandTotal,
    };
  }

  factory Quotation.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'] as List? ?? [];

    return Quotation(
      id: map['id'] as String? ?? '',
      quotationNumber: map['quotationNumber'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      customerNumber: map['customerNumber'] as String? ?? '',
      customerCompany: map['customerCompany'] as String? ?? '',
      customerPhone: map['customerPhone'] as String? ?? '',
      customerEmail: map['customerEmail'] as String? ?? '',
      customerAddress: map['customerAddress'] as String? ?? '',
      projectName: map['projectName'] as String? ?? '',
      projectAddress: map['projectAddress'] as String? ?? '',
      description: map['description'] as String? ?? '',
      issueDate: DateTime.tryParse(
            map['issueDate'] as String? ?? '',
          ) ??
          DateTime.now(),
      validUntil: DateTime.tryParse(
            map['validUntil'] as String? ?? '',
          ) ??
          DateTime.now(),
      notes: map['notes'] as String? ?? '',
      termsAndConditions: map['termsAndConditions'] as String? ?? '',
      items: rawItems
          .whereType<Map>()
          .map(
            (item) => QuotationItem.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      markupPercent:
          (map['markupPercent'] as num? ?? 0).toDouble(),
      discount: (map['discount'] as num? ?? 0).toDouble(),
      taxPercent: (map['taxPercent'] as num? ?? 0).toDouble(),
      status: map['status'] as String? ?? 'Draft',
      currency: map['currency'] as String? ?? 'FJD',
    );
  }
}