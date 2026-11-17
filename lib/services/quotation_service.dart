
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/quotation.dart';

class QuotationService {
  QuotationService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const Uuid _uuid = Uuid();

  CollectionReference<Map<String, dynamic>> _quotes(
    String businessId,
  ) {
    return _db
        .collection('businesses')
        .doc(businessId)
        .collection('quotations');
  }

  DocumentReference<Map<String, dynamic>> _counter(
    String businessId,
  ) {
    return _db
        .collection('businesses')
        .doc(businessId)
        .collection('settings')
        .doc('quotationCounter');
  }

  Stream<List<Quotation>> watchQuotations(String businessId) {
    return _quotes(businessId)
        .orderBy('issueDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Quotation.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<Quotation> createQuotation({
    required String businessId,
    required Quotation quotation,
  }) async {
    final id = _uuid.v4();

    final quoteReference = _quotes(businessId).doc(id);
    final counterReference = _counter(businessId);

    late Quotation savedQuotation;

    await _db.runTransaction((transaction) async {
      final counterSnapshot = await transaction.get(counterReference);

      final nextNumber = counterSnapshot.exists
          ? ((counterSnapshot.data()?['nextQuotationNumber'] as num?)
                  ?.toInt() ??
              1)
          : 1;

      final quotationNumber =
          'QT-${nextNumber.toString().padLeft(4, '0')}';

      savedQuotation = Quotation(
        id: id,
        quotationNumber: quotationNumber,
        customerId: quotation.customerId,
        customerName: quotation.customerName,
        customerNumber: quotation.customerNumber,
        customerCompany: quotation.customerCompany,
        customerPhone: quotation.customerPhone,
        customerEmail: quotation.customerEmail,
        customerAddress: quotation.customerAddress,
        projectName: quotation.projectName,
        projectAddress: quotation.projectAddress,
        description: quotation.description,
        issueDate: quotation.issueDate,
        validUntil: quotation.validUntil,
        notes: quotation.notes,
        termsAndConditions: quotation.termsAndConditions,
        items: quotation.items,
        markupPercent: quotation.markupPercent,
        discount: quotation.discount,
        taxPercent: quotation.taxPercent,
        status: quotation.status,
        currency: quotation.currency,

        // Preserve individual item markup settings.
        itemMarkupEnabled: quotation.itemMarkupEnabled,
      );

      transaction.set(
        quoteReference,
        savedQuotation.toMap(),
      );

      transaction.set(
        counterReference,
        {
          'nextQuotationNumber': nextNumber + 1,
        },
      );
    });

    return savedQuotation;
  }

  Future<void> updateQuotation({
    required String businessId,
    required Quotation quotation,
  }) async {
    if (quotation.id.isEmpty) {
      throw ArgumentError('Quotation ID cannot be empty.');
    }

    await _quotes(businessId)
        .doc(quotation.id)
        .update(quotation.toMap());
  }

  Future<void> deleteQuotation({
    required String businessId,
    required String quotationId,
  }) {
    return _quotes(businessId).doc(quotationId).delete();
  }
}