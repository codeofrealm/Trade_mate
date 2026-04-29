import 'package:cloud_firestore/cloud_firestore.dart';

class HomeCartItem {
  const HomeCartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productCategory,
    required this.productPrice,
    required this.quantity,
    this.productImageUrl,
    this.productImageBase64,
    this.updatedAt,
  });

  final String id;
  final String productId;
  final String productName;
  final String productCategory;
  final double productPrice;
  final int quantity;
  final String? productImageUrl;
  final String? productImageBase64;
  final DateTime? updatedAt;

  double get totalPrice => productPrice * quantity;

  factory HomeCartItem.fromFirestore(String id, Map<String, dynamic> data) {
    final timestamp = data['updatedAt'];

    return HomeCartItem(
      id: id,
      productId: (data['productId'] ?? '').toString(),
      productName: (data['productName'] ?? '').toString(),
      productCategory: (data['productCategory'] ?? '').toString(),
      productPrice: _asDouble(data['productPrice']),
      quantity: _asInt(data['quantity']),
      productImageUrl: (data['productImageUrl'] ?? '').toString().trim().isEmpty
          ? null
          : data['productImageUrl'].toString().trim(),
      productImageBase64:
          (data['productImageBase64'] ?? '').toString().trim().isEmpty
          ? null
          : data['productImageBase64'].toString().trim(),
      updatedAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
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
