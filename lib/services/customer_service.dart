import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/customer.dart';

class CustomerService {
  CustomerService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const Uuid _uuid = Uuid();

  CollectionReference<Map<String, dynamic>> _customerCollection(
    String businessId,
  ) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('customers');
  }

  DocumentReference<Map<String, dynamic>> _counterDocument(
    String businessId,
  ) {
    return _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('settings')
        .doc('customerCounter');
  }

  String _formatCustomerNumber(int number) {
    return number.toString().padLeft(3, '0');
  }

  /// Assigns numbers to existing customers, oldest-created first.
  /// Each document is read individually inside the transaction.
  Future<void> ensureCustomerNumbers(String businessId) async {
    final customers = _customerCollection(businessId);
    final counter = _counterDocument(businessId);

    // Firestore transactions cannot read a Query directly.
    // Get the list first, then read each document in the transaction.
    final customerQuery = await customers.orderBy('createdAt').get();

    if (customerQuery.docs.length > 450) {
      final missingCount = customerQuery.docs.where((document) {
        final value = document.data()['customerNumber'];
        return value is! String || value.isEmpty;
      }).length;

      if (missingCount > 450) {
        throw StateError(
          'This business has more than 450 existing customers without '
          'customer numbers. Please contact support to migrate these '
          'records safely before continuing.',
        );
      }
    }

    await _firestore.runTransaction((transaction) async {
      final counterSnapshot = await transaction.get(counter);

      var highestExistingNumber = 0;

      final missingDocuments =
          <DocumentReference<Map<String, dynamic>>>[];

      // Read every customer document before performing any writes.
      for (final document in customerQuery.docs) {
        final latestSnapshot = await transaction.get(document.reference);

        if (!latestSnapshot.exists) {
          continue;
        }

        final value = latestSnapshot.data()?['customerNumber'];

        if (value is String && value.isNotEmpty) {
          final parsed = int.tryParse(value);

          if (parsed != null && parsed > highestExistingNumber) {
            highestExistingNumber = parsed;
          }
        } else {
          missingDocuments.add(document.reference);
        }
      }

      final storedNextNumber =
          (counterSnapshot.data()?['nextCustomerNumber'] as num?)?.toInt() ??
              1;

      var nextNumber = storedNextNumber;

      if (nextNumber <= highestExistingNumber) {
        nextNumber = highestExistingNumber + 1;
      }

      if (missingDocuments.length > 450) {
        throw StateError(
          'This business has more than 450 existing customers without '
          'customer numbers. Please contact support to migrate these '
          'records safely before continuing.',
        );
      }

      // All reads are complete. Now perform the writes.
      for (final documentReference in missingDocuments) {
        transaction.set(
          documentReference,
          {
            'customerNumber': _formatCustomerNumber(nextNumber),
          },
          SetOptions(merge: true),
        );

        nextNumber++;
      }

      if (!counterSnapshot.exists || nextNumber != storedNextNumber) {
        transaction.set(counter, {
          'nextCustomerNumber': nextNumber,
        });
      }
    });
  }

  Stream<List<Customer>> watchCustomers(String businessId) async* {
    await ensureCustomerNumbers(businessId);

    yield* _customerCollection(businessId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Customer.fromMap(doc.data());
      }).toList();
    });
  }

  Future<Customer> addCustomer({
    required String businessId,
    required String fullName,
    String companyName = '',
    String phoneNumber = '',
    String email = '',
    String address = '',
    String notes = '',
  }) async {
    await ensureCustomerNumbers(businessId);

    final customerId = _uuid.v4();
    final counter = _counterDocument(businessId);

    final customerReference =
        _customerCollection(businessId).doc(customerId);

    late Customer createdCustomer;

    await _firestore.runTransaction((transaction) async {
      final counterSnapshot = await transaction.get(counter);

      if (!counterSnapshot.exists) {
        throw StateError(
          'Customer numbering could not be initialized. '
          'Please refresh the page and try again.',
        );
      }

      final nextNumber =
          (counterSnapshot.data()?['nextCustomerNumber'] as num?)?.toInt() ??
              1;

      createdCustomer = Customer(
        id: customerId,
        customerNumber: _formatCustomerNumber(nextNumber),
        fullName: fullName.trim(),
        companyName: companyName.trim(),
        phoneNumber: phoneNumber.trim(),
        email: email.trim(),
        address: address.trim(),
        notes: notes.trim(),
        createdAt: DateTime.now(),
      );

      transaction.set(
        customerReference,
        createdCustomer.toMap(),
      );

      transaction.update(counter, {
        'nextCustomerNumber': nextNumber + 1,
      });
    });

    return createdCustomer;
  }

  Future<void> updateCustomer({
    required String businessId,
    required Customer customer,
  }) async {
    await _customerCollection(businessId)
        .doc(customer.id)
        .set(customer.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteCustomer({
    required String businessId,
    required String customerId,
  }) async {
    // Deleted customer numbers are never reused.
    await _customerCollection(businessId)
        .doc(customerId)
        .delete();
  }
}