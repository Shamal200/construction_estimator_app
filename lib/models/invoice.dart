
enum InvoiceStatus {
  draft,
  sent,
  partiallyPaid,
  paid,
  overdue,
}

class InvoiceItem {
  const InvoiceItem({
    required this.id,
    required this.name,
    this.description = '',
    required this.quantity,
    required this.unit,
    required this.unitRate,
    required this.total,
  });

  final String id;
  final String name;
  final String description;
  final double quantity;
  final String unit;
  final double unitRate;
  final double total;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'quantity': quantity,
      'unit': unit,
      'unitRate': unitRate,
      'total': total,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      unit: map['unit'] as String? ?? '',
      unitRate: (map['unitRate'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Invoice {
  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.projectId,
    this.projectName = '',
    this.quotationId = '',
    this.quotationNumber = '',
    required this.issueDate,
    required this.dueDate,
    required this.items,
    required this.subtotal,
    this.discount = 0,
    required this.tax,
    required this.total,
    required this.amountPaid,
    required this.balance,
    required this.status,
    this.currency = 'FJD',
  });

  final String id;
  final String invoiceNumber;
  final String customerId;
  final String projectId;
  final String projectName;

  final String quotationId;
  final String quotationNumber;

  final DateTime issueDate;
  final DateTime dueDate;
  final List<InvoiceItem> items;

  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final double amountPaid;
  final double balance;
  final InvoiceStatus status;
  final String currency;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'customerId': customerId,
      'projectId': projectId,
      'projectName': projectName,
      'quotationId': quotationId,
      'quotationNumber': quotationNumber,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'total': total,
      'amountPaid': amountPaid,
      'balance': balance,
      'status': status.name,
      'currency': currency,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'] as List? ?? [];

    return Invoice(
      id: map['id'] as String? ?? '',
      invoiceNumber: map['invoiceNumber'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      projectId: map['projectId'] as String? ?? '',
      projectName: map['projectName'] as String? ?? '',
      quotationId: map['quotationId'] as String? ?? '',
      quotationNumber: map['quotationNumber'] as String? ?? '',
      issueDate: DateTime.tryParse(
            map['issueDate'] as String? ?? '',
          ) ??
          DateTime.now(),
      dueDate: DateTime.tryParse(
            map['dueDate'] as String? ?? '',
          ) ??
          DateTime.now(),
      items: rawItems
          .whereType<Map>()
          .map(
            (item) => InvoiceItem.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0,
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0,
      balance: (map['balance'] as num?)?.toDouble() ?? 0,
      status: InvoiceStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => InvoiceStatus.draft,
      ),
      currency: map['currency'] as String? ?? 'FJD',
    );
  }
}
