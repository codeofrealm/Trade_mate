import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../admin/data/models/admin_product.dart';
import 'models/home_user_address.dart';

class HomeUserProfileService {
  HomeUserProfileService._();

  static final HomeUserProfileService instance = HomeUserProfileService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Address ────────────────────────────────────────────────────────────────

  Stream<HomeUserAddress> streamAddress() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(HomeUserAddress.empty);

    return _firestore.collection('users').doc(user.uid).snapshots().map((doc) {
      final data = doc.data() ?? <String, dynamic>{};
      final addressData = data['address'];
      if (addressData is Map<String, dynamic>) {
        return HomeUserAddress.fromMap(addressData);
      }
      return HomeUserAddress.empty;
    });
  }

  Future<HomeUserAddress> loadAddress() async {
    final user = _auth.currentUser;
    if (user == null) return HomeUserAddress.empty;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    final data = doc.data() ?? <String, dynamic>{};
    final addressData = data['address'];
    if (addressData is Map<String, dynamic>) {
      return HomeUserAddress.fromMap(addressData);
    }
    return HomeUserAddress.empty;
  }

  Future<void> saveAddress(HomeUserAddress address) async {
    final user = _auth.currentUser;
    if (user == null) throw const HomeProfileException('Please login again.');

    await _firestore.collection('users').doc(user.uid).set({
      'address': address.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── Wishlist ───────────────────────────────────────────────────────────────

  Stream<List<AdminProduct>> streamWishlist() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('wishlist')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .asyncMap((snap) async {
          final productIds = snap.docs
              .map((d) => (d.data()['productId'] ?? '').toString())
              .where((id) => id.isNotEmpty)
              .toList();

          if (productIds.isEmpty) return <AdminProduct>[];

          final results = await Future.wait(
            productIds.map(
              (id) => _firestore.collection('products').doc(id).get(),
            ),
          );

          return results
              .where((d) => d.exists && d.data() != null)
              .map((d) => AdminProduct.fromFirestore(d.id, d.data()!))
              .toList();
        });
  }

  Stream<bool> streamIsWishlisted(String productId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);

    final docId = '${user.uid}_$productId';
    return _firestore
        .collection('wishlist')
        .doc(docId)
        .snapshots()
        .map((d) => d.exists);
  }

  Future<void> toggleWishlist(AdminProduct product) async {
    final user = _auth.currentUser;
    if (user == null) throw const HomeProfileException('Please login again.');

    final docId = '${user.uid}_${product.id}';
    final ref = _firestore.collection('wishlist').doc(docId);
    final doc = await ref.get();

    if (doc.exists) {
      await ref.delete();
    } else {
      await ref.set({
        'userId': user.uid,
        'productId': product.id,
        'productName': product.name,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }
}

class HomeProfileException implements Exception {
  const HomeProfileException(this.message);
  final String message;
}
