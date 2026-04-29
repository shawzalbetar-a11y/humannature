
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:human_nature_admin/models/product.dart';

class FirebaseService {
  late final FirebaseFirestore _db;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  FirebaseService() {
    try {
      _db = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'humannature',
      );
    } catch (e) {
      debugPrint('Firestore initialization failed: $e');
      _db = FirebaseFirestore.instance;
    }
  }

  // Products
  Stream<List<Product>> streamProducts() {
    return _db
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  Future<void> addProduct(Product product) async {
    await _db.collection('products').doc(product.id).set(product.toFirestore());
  }

  Future<void> updateProduct(Product product) async {
    await _db.collection('products').doc(product.id).update(product.toFirestore());
  }

  Future<void> deleteProduct(String id) async {
    await _db.collection('products').doc(id).delete();
  }

  Future<void> updateProductStock(String id, int stockCount) async {
    await _db.collection('products').doc(id).update({'stockCount': stockCount});
  }

  /// Update specific fields of a product document (partial update)
  Future<void> updateProductFields(String id, Map<String, dynamic> fields) async {
    // Remove null values so Firestore doesn't set fields to null
    fields.removeWhere((key, value) => value == null);
    await _db.collection('products').doc(id).update(fields);
  }



  // For Web (using bytes)
  Future<String> uploadImageBytes(dynamic bytes, String folder) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference ref = _storage.ref().child(folder).child(fileName);
    UploadTask uploadTask = ref.putData(bytes);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // Store Settings
  Future<Map<String, dynamic>?> getStoreSettings() async {
    final doc = await _db.collection('settings').doc('store').get();
    return doc.data();
  }

  Future<void> updateStoreSettings(Map<String, dynamic> data) async {
    await _db.collection('settings').doc('store').set(data, SetOptions(merge: true));
  }

  // Cloudinary Accounts
  Future<List<Map<String, dynamic>>> getCloudinaryAccounts() async {
    final doc = await _db.collection('settings').doc('cloudinary').get();
    if (doc.exists && doc.data() != null) {
      final accounts = doc.data()!['accounts'] as List<dynamic>?;
      if (accounts != null) {
        return accounts.cast<Map<String, dynamic>>();
      }
    }
    return [];
  }

  // Featured Categories Config
  Future<Map<String, dynamic>?> getFeaturedCategoriesConfig() async {
    final doc = await _db.collection('settings').doc('featuredCategories').get();
    return doc.data();
  }

  Future<void> updateFeaturedCategoriesConfig(Map<String, dynamic> data) async {
    await _db.collection('settings').doc('featuredCategories').set(data, SetOptions(merge: true));
  }

  /// Stream products filtered by category (used by Featured Categories admin)
  Stream<List<Product>> streamProductsByCategory(String category) {
    return _db
        .collection('products')
        .where('category', isEqualTo: category)
        .orderBy('salesCount', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  // ═══════════════════════════════════════════════════════════
  // Dynamic Categories Management
  // ═══════════════════════════════════════════════════════════

  /// Stream the categories config from Firestore
  Stream<List<Map<String, dynamic>>> streamCategories() {
    return _db
        .collection('settings')
        .doc('categories')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        // Return defaults if no config exists
        return [
          {
            'slug': 'giyim',
            'title': 'Giyim',
            'subCategories': [
              {'slug': 'tisort', 'title': 'Tişört'},
              {'slug': 'sortlu-takim', 'title': 'Şortlu Takım'},
              {'slug': 'spor-takim', 'title': 'Spor Takım'},
            ]
          },
          {
            'slug': 'aksesuar',
            'title': 'Aksesuar',
            'subCategories': [],
          },
        ];
      }
      final data = snapshot.data()!;
      final list = data['list'] as List<dynamic>? ?? [];
      return list.cast<Map<String, dynamic>>();
    });
  }

  /// Save the full categories list
  Future<void> saveCategories(List<Map<String, dynamic>> categories) async {
    await _db.collection('settings').doc('categories').set({
      'list': categories,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ═══════════════════════════════════════════════════════════
  // Payment Methods Management
  // ═══════════════════════════════════════════════════════════

  /// Get payment methods settings from Firestore
  Future<Map<String, dynamic>?> getPaymentMethods() async {
    final doc = await _db.collection('settings').doc('paymentMethods').get();
    return doc.data();
  }

  /// Update payment methods settings in Firestore
  Future<void> updatePaymentMethods(Map<String, dynamic> data) async {
    await _db.collection('settings').doc('paymentMethods').set(data, SetOptions(merge: true));
  }
}
