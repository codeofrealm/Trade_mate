import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/admin_product.dart';
import '../models/admin_product_review.dart';
import '../models/admin_support_chat.dart';
import '../models/admin_user_order.dart';

class AdminCatalogService {
  AdminCatalogService._();

  static final AdminCatalogService instance = AdminCatalogService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('products');

  CollectionReference<Map<String, dynamic>> get _reviewsRef =>
      _firestore.collection('product_reviews');

  CollectionReference<Map<String, dynamic>> get _chatsRef =>
      _firestore.collection('support_chats');

  CollectionReference<Map<String, dynamic>> get _ordersRef =>
      _firestore.collection('orders');

  Stream<List<AdminProduct>> streamProducts({bool includeInactive = true}) {
    Query<Map<String, dynamic>> query = _productsRef;
    if (!includeInactive) {
      query = query.where('isActive', isEqualTo: true);
    }

    return query.snapshots().map((snapshot) {
      final products = snapshot.docs
          .map((doc) => AdminProduct.fromFirestore(doc.id, doc.data()))
          .toList();
      products.sort(
        (a, b) => _sortDate(b.updatedAt).compareTo(_sortDate(a.updatedAt)),
      );
      return products;
    });
  }

  Stream<List<AdminProduct>> streamActiveProducts() {
    return streamProducts(includeInactive: false);
  }

  Future<void> createProduct(AdminProductDraft draft) {
    return _productsRef.add(draft.toFirestoreForCreate());
  }

  Future<void> updateProduct({
    required String productId,
    required AdminProductDraft draft,
  }) {
    return _productsRef
        .doc(productId)
        .set(draft.toFirestoreForUpdate(), SetOptions(merge: true));
  }

  Future<void> setProductActiveStatus({
    required String productId,
    required bool isActive,
  }) {
    return _productsRef.doc(productId).set({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<int> streamTotalProductsCount() {
    return streamProducts().map((items) => items.length);
  }

  Stream<int> streamActiveProductsCount() {
    return streamActiveProducts().map((items) => items.length);
  }

  Stream<double> streamTotalSalesAmount() {
    return _ordersRef.snapshots().map((snapshot) {
      var total = 0.0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString().trim().toLowerCase();
        if (status == 'cancelled' || status == 'canceled') continue;
        final amount = data['totalAmount'];
        if (amount is num) total += amount.toDouble();
      }
      return total;
    });
  }

  Stream<int> streamTotalReviewCount() {
    return _reviewsRef.snapshots().map((snap) => snap.docs.length);
  }

  Stream<List<AdminProductReview>> streamReviews({int limit = 20}) {
    return _reviewsRef.snapshots().map((snapshot) {
      final reviews = snapshot.docs
          .map((doc) => AdminProductReview.fromFirestore(doc.id, doc.data()))
          .toList();
      reviews.sort(
        (a, b) => _sortDate(b.createdAt).compareTo(_sortDate(a.createdAt)),
      );
      return reviews.take(limit).toList();
    });
  }

  Stream<List<AdminSupportChat>> streamChats({int limit = 20}) {
    return _chatsRef.snapshots().map((snapshot) {
      final chats = snapshot.docs
          .map((doc) => AdminSupportChat.fromFirestore(doc.id, doc.data()))
          .toList();
      chats.sort(
        (a, b) => _sortDate(b.updatedAt).compareTo(_sortDate(a.updatedAt)),
      );
      return chats.take(limit).toList();
    });
  }

  Stream<int> streamOpenChatsCount() {
    return streamChats(
      limit: 100,
    ).map((chats) => chats.where((chat) => chat.isOpen).length);
  }

  Stream<List<AdminUserOrder>> streamOrdersByUser(String userId) {
    return _ordersRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => AdminUserOrder.fromFirestore(doc.id, doc.data()))
          .toList();
      orders.sort((a, b) => _sortDate(b.updatedAt ?? b.createdAt)
          .compareTo(_sortDate(a.updatedAt ?? a.createdAt)));
      return orders;
    });
  }

  Stream<List<AdminUserOrder>> streamOrders({int limit = 100}) {
    return _ordersRef.snapshots().map((snapshot) {
      final orders = snapshot.docs
          .map((doc) => AdminUserOrder.fromFirestore(doc.id, doc.data()))
          .toList();
      orders.sort(
        (a, b) => _sortDate(
          b.updatedAt ?? b.createdAt,
        ).compareTo(_sortDate(a.updatedAt ?? a.createdAt)),
      );
      return orders.take(limit).toList();
    });
  }

  Stream<int> streamTotalUsersCount() {
    return _firestore.collection('users').snapshots()
        .map((s) => s.docs.length);
  }

  Stream<double> streamDeliveredOrdersAmount() {
    return _ordersRef.snapshots().map((snapshot) {
      var total = 0.0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if ((data['status'] ?? '').toString().trim().toLowerCase() != 'delivered') continue;
        final amount = data['totalAmount'];
        if (amount is num) total += amount.toDouble();
      }
      return total;
    });
  }

  // Returns map of month(1-12) -> total amount for current year (non-cancelled)
  Stream<Map<int, double>> streamMonthlyRevenue() {
    return _ordersRef.snapshots().map((snapshot) {
      final now = DateTime.now();
      final Map<int, double> monthly = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString().trim().toLowerCase();
        if (status == 'cancelled' || status == 'canceled') continue;
        final ts = data['createdAt'];
        if (ts is! Timestamp) continue;
        final dt = ts.toDate();
        if (dt.year != now.year) continue;
        final amount = data['totalAmount'];
        if (amount is num) {
          monthly[dt.month] = (monthly[dt.month] ?? 0) + amount.toDouble();
        }
      }
      return monthly;
    });
  }

  Stream<int> streamTotalOrdersCount() {
    return streamOrders(limit: 1000).map((orders) => orders.length);
  }

  int _sortDate(DateTime? value) {
    if (value == null) {
      return 0;
    }
    return value.millisecondsSinceEpoch;
  }
}
