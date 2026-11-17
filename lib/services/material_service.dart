import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/material_item.dart';

class MaterialService {
  MaterialService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  static const Uuid _uuid = Uuid();

  CollectionReference<Map<String, dynamic>> _materials(String businessId) =>
      _db.collection('businesses').doc(businessId).collection('materials');

  Stream<List<MaterialItem>> watchMaterials(String businessId) =>
      _materials(businessId).orderBy('name').snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => MaterialItem.fromMap(doc.data()))
            .toList(),
      );

  Future<MaterialItem> saveMaterial({
    required String businessId,
    required MaterialItem material,
  }) async {
    if (businessId.trim().isEmpty) {
      throw ArgumentError('Select a business before saving a board.');
    }
    final saved = material.copyWith(
      id: material.id.isEmpty ? _uuid.v4() : material.id,
      category: 'Board',
      unit: 'sheet',
    );
    await _materials(businessId).doc(saved.id).set(saved.toMap());
    return saved;
  }

  Future<void> setMaterialActive({
    required String businessId,
    required String materialId,
    required bool isActive,
  }) => _materials(businessId).doc(materialId).update({'isActive': isActive});
}
