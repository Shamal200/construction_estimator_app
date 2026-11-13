
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

  Stream<List<Customer>> watchCustomers(String businessId) {
    return _customerCollection(businessId)
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
    final customer = Customer(
      id: _uuid.v4(),
      fullName: fullName.trim(),
      companyName: companyName.trim(),
      phoneNumber: phoneNumber.trim(),
      email: email.trim(),
      address: address.trim(),
      notes: notes.trim(),
      createdAt: DateTime.now(),
    );

    await _customerCollection(businessId)
        .doc(customer.id)
        .set(customer.toMap());

    return customer;
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
    await _customerCollection(businessId)
        .doc(customerId)
        .delete();
  }
}
