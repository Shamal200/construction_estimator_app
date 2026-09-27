class Project {
  const Project({
    required this.id,
    required this.name,
    required this.customerId,
    required this.address,
    required this.startDate,
    required this.expectedCompletionDate,
    required this.status,
    this.description = '',
    this.quotationId = '',
    this.invoiceId = '',
    this.notes = '',
  });

  final String id;
  final String name;
  final String customerId;
  final String address;
  final DateTime startDate;
  final DateTime expectedCompletionDate;
  final String status;
  final String description;
  final String quotationId;
  final String invoiceId;
  final String notes;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'customerId': customerId,
      'address': address,
      'startDate': startDate.toIso8601String(),
      'expectedCompletionDate': expectedCompletionDate.toIso8601String(),
      'status': status,
      'description': description,
      'quotationId': quotationId,
      'invoiceId': invoiceId,
      'notes': notes,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      address: map['address'] as String? ?? '',
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate'] as String) : DateTime.now(),
      expectedCompletionDate: map['expectedCompletionDate'] != null
          ? DateTime.parse(map['expectedCompletionDate'] as String)
          : DateTime.now(),
      status: map['status'] as String? ?? 'Planning',
      description: map['description'] as String? ?? '',
      quotationId: map['quotationId'] as String? ?? '',
      invoiceId: map['invoiceId'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
    );
  }
}
