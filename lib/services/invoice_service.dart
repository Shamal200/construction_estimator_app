
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/invoice.dart';
import '../models/quotation.dart';

class InvoiceService {
  InvoiceService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const Uuid _uuid = Uuid();

  CollectionReference<Map<String, dynamic>> _invoices(
    String businessId,
  ) {
    return _db
        .collection('businesses')
        .doc(businessId)
        .collection('invoices');
  }

  DocumentReference<Map<String, dynamic>> _invoiceCounter(
    String businessId,
  ) {
    return _db
        .collection('businesses')
        .doc(businessId)
        .collection('settings')
        .doc('invoiceCounter');
  }

  // Watch all invoices for a business.
  Stream<List<Invoice>> watchInvoices(String businessId) {
    return _invoices(businessId)
        .orderBy('issueDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Invoice.fromMap(doc.data()))
              .toList(),
        );
  }

  // Convert a quotation into an invoice.
  Future<Invoice> convertQuotationToInvoice({
    required String businessId,
    required String quotationId,
  }) async {
    if (businessId.isEmpty || quotationId.isEmpty) {
      throw ArgumentError(
        'Business ID and quotation ID are required.',
      );
    }

    final quotationReference = _db
        .collection('businesses')
        .doc(businessId)
        .collection('quotations')
        .doc(quotationId);

    final counterReference = _invoiceCounter(businessId);

    final invoiceId = _uuid.v4();
    final invoiceReference = _invoices(businessId).doc(invoiceId);

    late Invoice createdInvoice;

    await _db.runTransaction((transaction) async {
      final quotationSnapshot =
          await transaction.get(quotationReference);

      final counterSnapshot =
          await transaction.get(counterReference);

      if (!quotationSnapshot.exists) {
        throw Exception('Quotation not found.');
      }

      final quotationData = quotationSnapshot.data()!;

      final existingInvoiceId =
          quotationData['invoiceId'] as String? ?? '';

      if (existingInvoiceId.isNotEmpty) {
        throw Exception(
          'This quotation has already been converted into an invoice.',
        );
      }

      final quotation = Quotation.fromMap(quotationData);

      if (quotation.items.isEmpty) {
        throw Exception(
          'Cannot create an invoice without quotation items.',
        );
      }

      final nextNumber = counterSnapshot.exists
          ? ((counterSnapshot.data()?['nextInvoiceNumber'] as num?)
                  ?.toInt() ??
              1)
          : 1;

      final invoiceNumber =
          'INV-${nextNumber.toString().padLeft(4, '0')}';

      // Preserve the quotation's final selling prices.
      final invoiceItems = quotation.items.map((item) {
        final sellingUnitRate = quotation.itemMarkupEnabled
            ? item.sellingUnitRate
            : item.unitRate *
                (1 + quotation.markupPercent / 100);

        return InvoiceItem(
          id: item.id,
          name: item.name,
          description: item.description,
          quantity: item.quantity,
          unit: item.unit,
          unitRate: sellingUnitRate,
          total: sellingUnitRate * item.quantity,
        );
      }).toList();

      final now = DateTime.now();

      createdInvoice = Invoice(
        id: invoiceId,
        invoiceNumber: invoiceNumber,
        customerId: quotation.customerId,
        projectId: '',
        projectName: quotation.projectName,
        quotationId: quotation.id,
        quotationNumber: quotation.quotationNumber,
        issueDate: now,
        dueDate: now.add(const Duration(days: 30)),
        items: invoiceItems,
        subtotal: quotation.subtotal,
        discount: quotation.discount,
        tax: quotation.taxAmount,
        total: quotation.grandTotal,
        amountPaid: 0,
        balance: quotation.grandTotal,
        status: InvoiceStatus.unpaid,
        currency: quotation.currency,
      );

      transaction.set(
        invoiceReference,
        createdInvoice.toMap(),
      );

      transaction.set(
        counterReference,
        {
          'nextInvoiceNumber': nextNumber + 1,
        },
      );

      transaction.update(
        quotationReference,
        {
          'invoiceId': invoiceId,
        },
      );
    });

    return createdInvoice;
  }

  // Update the total amount received against an invoice.
  Future<void> updatePayment({
    required String businessId,
    required String invoiceId,
    required double amountPaid,
  }) async {
    if (businessId.isEmpty || invoiceId.isEmpty) {
      throw ArgumentError(
        'Business ID and invoice ID are required.',
      );
    }

    if (amountPaid < 0) {
      throw ArgumentError(
        'Payment cannot be negative.',
      );
    }

    final reference = _invoices(businessId).doc(invoiceId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);

      if (!snapshot.exists) {
        throw Exception('Invoice not found.');
      }

      final invoice = Invoice.fromMap(snapshot.data()!);

      if (amountPaid > invoice.total) {
        throw ArgumentError(
          'Payment cannot exceed the invoice total.',
        );
      }

      final balance = (invoice.total - amountPaid)
          .clamp(0.0, invoice.total)
          .toDouble();

      final InvoiceStatus status;

      if (balance <= 0) {
        status = InvoiceStatus.paid;
      } else if (amountPaid > 0) {
        status = InvoiceStatus.partiallyPaid;
      } else {
        status = InvoiceStatus.unpaid;
      }

      transaction.update(reference, {
        'amountPaid': amountPaid,
        'balance': balance,
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
