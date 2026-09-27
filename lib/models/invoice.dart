enum InvoiceStatus { draft, sent, partiallyPaid, paid, overdue }

class Invoice {
  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.customerId,
    required this.projectId,
    required this.issueDate,
    required this.dueDate,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.amountPaid,
    required this.balance,
    required this.status,
  });

  final String id;
  final String invoiceNumber;
  final String customerId;
  final String projectId;
  final DateTime issueDate;
  final DateTime dueDate;
  final List<String> items;
  final double subtotal;
  final double tax;
  final double total;
  final double amountPaid;
  final double balance;
  final InvoiceStatus status;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'customerId': customerId,
      'projectId': projectId,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'items': items,
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'amountPaid': amountPaid,
      'balance': balance,
      'status': status.name,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] as String? ?? '',
      invoiceNumber: map['invoiceNumber'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      projectId: map['projectId'] as String? ?? '',
      issueDate: map['issueDate'] != null ? DateTime.parse(map['issueDate'] as String) : DateTime.now(),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate'] as String) : DateTime.now(),
      items: List<String>.from(map['items'] as List? ?? const []),
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0,
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0,
      balance: (map['balance'] as num?)?.toDouble() ?? 0,
      status: InvoiceStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => InvoiceStatus.draft,
      ),
    );
  }
}
