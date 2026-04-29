import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../admin/data/models/admin_product.dart';
import '../../admin/data/models/admin_product_review.dart';
import '../../admin/data/services/admin_catalog_service.dart';
import 'models/home_cart_item.dart';
import 'models/home_user_address.dart';
import 'models/home_user_order.dart';

class HomeProductService {
  HomeProductService._();

  static final HomeProductService instance = HomeProductService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<AdminProduct>> streamVisibleProducts() {
    return AdminCatalogService.instance.streamActiveProducts();
  }

  Stream<List<AdminProductReview>> streamProductReviews(String productId) {
    return _firestore
        .collection('product_reviews')
        .where('productId', isEqualTo: productId)
        .snapshots()
        .map((snapshot) {
          final reviews = snapshot.docs
              .map(
                (doc) => AdminProductReview.fromFirestore(doc.id, doc.data()),
              )
              .toList();
          reviews.sort(
            (a, b) => _sortDate(b.createdAt).compareTo(_sortDate(a.createdAt)),
          );
          return reviews;
        });
  }

  Stream<List<HomeCartItem>> streamCartItems() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(const []);
    }

    return _firestore
        .collection('cart_items')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map((doc) => HomeCartItem.fromFirestore(doc.id, doc.data()))
              .toList();
          items.sort(
            (a, b) => _sortDate(b.updatedAt).compareTo(_sortDate(a.updatedAt)),
          );
          return items;
        });
  }

  Stream<List<HomeUserOrder>> streamMyOrders({int limit = 100}) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(const []);
    }

    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => HomeUserOrder.fromFirestore(doc.id, doc.data()))
              .toList();
          orders.sort(
            (a, b) => _sortDate(
              b.updatedAt ?? b.createdAt,
            ).compareTo(_sortDate(a.updatedAt ?? a.createdAt)),
          );
          return orders.take(limit).toList();
        });
  }

  Future<void> addToCart({
    required AdminProduct product,
    int quantity = 1,
  }) async {
    if (!product.isActive) {
      throw const HomeProductException('This product is not available.');
    }

    if (product.stock <= 0) {
      throw const HomeProductException('Product is out of stock.');
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw const HomeProductException('Please login again.');
    }

    final docId = '${user.uid}_${product.id}';

    await _firestore.collection('cart_items').doc(docId).set({
      'userId': user.uid,
      'productId': product.id,
      'productName': product.name,
      'productCategory': product.category,
      'productPrice': product.price,
      'productImageUrl': product.imageUrl ?? '',
      'productImageBase64': product.imageBase64 ?? '',
      'quantity': FieldValue.increment(quantity),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateCartQuantity({
    required String cartDocId,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      throw const HomeProductException('Quantity should be at least 1.');
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw const HomeProductException('Please login again.');
    }

    final docRef = _firestore.collection('cart_items').doc(cartDocId);
    final doc = await docRef.get();
    if (!doc.exists) {
      throw const HomeProductException('Cart item not found.');
    }

    final data = doc.data() ?? <String, dynamic>{};
    final ownerId = (data['userId'] ?? '').toString();
    if (ownerId != user.uid) {
      throw const HomeProductException('You cannot edit this cart item.');
    }

    await docRef.set({
      'quantity': quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removeCartItem(String cartDocId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const HomeProductException('Please login again.');
    }

    final docRef = _firestore.collection('cart_items').doc(cartDocId);
    final doc = await docRef.get();
    if (!doc.exists) {
      return;
    }

    final data = doc.data() ?? <String, dynamic>{};
    final ownerId = (data['userId'] ?? '').toString();
    if (ownerId != user.uid) {
      throw const HomeProductException('You cannot remove this cart item.');
    }

    await docRef.delete();
  }

  Future<String> placeOrder({
    required AdminProduct product,
    required HomeUserAddress address,
    int quantity = 1,
  }) async {
    if (!address.isComplete) {
      throw const HomeProductException(
        'Please complete your address in profile before ordering.',
      );
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw const HomeProductException('Please login again.');
    }

    final productRef = _firestore.collection('products').doc(product.id);
    final orderRef = _firestore.collection('orders').doc();

    await _firestore.runTransaction((transaction) async {
      final productSnapshot = await transaction.get(productRef);
      if (!productSnapshot.exists) {
        throw const HomeProductException('Product is no longer available.');
      }

      final data = productSnapshot.data() ?? <String, dynamic>{};
      final isActive = data['isActive'] == true;
      final stock = _asInt(data['stock']);
      final soldCount = _asInt(data['soldCount']);
      final price = _asDouble(data['price']);

      if (!isActive) {
        throw const HomeProductException('This product is not active now.');
      }

      if (stock < quantity) {
        throw const HomeProductException('Insufficient stock for this order.');
      }

      transaction.set(orderRef, {
        'userId': user.uid,
        'productId': product.id,
        'productName': data['name'] ?? product.name,
        'productCategory': data['category'] ?? product.category,
        'productPrice': price,
        'quantity': quantity,
        'totalAmount': price * quantity,
        'status': 'placed',
        'address': address.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(productRef, {
        'stock': stock - quantity,
        'soldCount': soldCount + quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    return orderRef.id;
  }

  Future<String> placeCartOrder({
    required List<HomeCartItem> items,
    required HomeUserAddress address,
  }) async {
    if (items.isEmpty) {
      throw const HomeProductException('Your cart is empty.');
    }

    if (!address.isComplete) {
      throw const HomeProductException(
        'Please complete your address in profile before ordering.',
      );
    }

    if (items.length > 25) {
      throw const HomeProductException(
        'Too many items in cart. Please reduce and try again.',
      );
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw const HomeProductException('Please login again.');
    }

    final orderRefs = <DocumentReference<Map<String, dynamic>>>[];
    for (var i = 0; i < items.length; i++) {
      orderRefs.add(_firestore.collection('orders').doc());
    }

    await _firestore.runTransaction((transaction) async {
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        final quantity = item.quantity <= 0 ? 1 : item.quantity;

        final productRef = _firestore.collection('products').doc(item.productId);
        final cartRef = _firestore.collection('cart_items').doc(item.id);
        final orderRef = orderRefs[i];

        final productSnapshot = await transaction.get(productRef);
        if (!productSnapshot.exists) {
          throw HomeProductException(
            '${item.productName} is no longer available.',
          );
        }

        final data = productSnapshot.data() ?? <String, dynamic>{};
        final isActive = data['isActive'] == true;
        final stock = _asInt(data['stock']);
        final soldCount = _asInt(data['soldCount']);
        final price = _asDouble(data['price']);

        if (!isActive) {
          throw HomeProductException('${item.productName} is not active now.');
        }

        if (stock < quantity) {
          throw HomeProductException(
            'Insufficient stock for ${item.productName}.',
          );
        }

        transaction.set(orderRef, {
          'userId': user.uid,
          'productId': item.productId,
          'productName': data['name'] ?? item.productName,
          'productCategory': data['category'] ?? item.productCategory,
          'productPrice': price,
          'quantity': quantity,
          'totalAmount': price * quantity,
          'status': 'placed',
          'address': address.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.update(productRef, {
          'stock': stock - quantity,
          'soldCount': soldCount + quantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.delete(cartRef);
      }
    });

    return orderRefs.first.id;
  }

  int _sortDate(DateTime? value) {
    if (value == null) {
      return 0;
    }
    return value.millisecondsSinceEpoch;
  }
}

class HomeProductException implements Exception {
  const HomeProductException(this.message);

  final String message;
}

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(dynamic value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
