import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserOrder {
  const AdminUserOrder({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.productCategory,
    required this.productPrice,
    required this.quantity,
    required this.totalAmount,
    required this.status,
    required this.addressLine1,
    required this.city,
    required this.state,
    required this.country,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String productId;
  final String productName;
  final String productCategory;
  final double productPrice;
  final int quantity;
  final double totalAmount;
  final String status;
  final String addressLine1;
  final String city;
  final String state;
  final String country;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get shortUserId {
    if (userId.length <= 10) {
      return userId;
    }
    return '${userId.substring(0, 6)}...${userId.substring(userId.length - 4)}';
  }

  bool get isCancelled {
    final s = status.trim().toLowerCase();
    return s == 'cancelled' || s == 'canceled';
  }

  bool get isDelivered => status.trim().toLowerCase() == 'delivered';

  String get addressSummary {
    final parts = [
      addressLine1.trim(),
      city.trim(),
      state.trim(),
      country.trim(),
    ].where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return 'Address not available';
    }
    return parts.join(', ');
  }

  factory AdminUserOrder.fromFirestore(String id, Map<String, dynamic> data) {
    final created = data['createdAt'];
    final updated = data['updatedAt'];
    final rawAddress = data['address'];
    final address = rawAddress is Map<String, dynamic>
        ? rawAddress
        : <String, dynamic>{};

    return AdminUserOrder(
      id: id,
      userId: (data['userId'] ?? '').toString(),
      productId: (data['productId'] ?? '').toString(),
      productName: (data['productName'] ?? '').toString(),
      productCategory: (data['productCategory'] ?? '').toString(),
      productPrice: _asDouble(data['productPrice']),
      quantity: _asInt(data['quantity']),
      totalAmount: _asDouble(data['totalAmount']),
      status: (data['status'] ?? '').toString(),
      addressLine1: (address['line1'] ?? '').toString(),
      city: (address['city'] ?? '').toString(),
      state: (address['state'] ?? '').toString(),
      country: (address['country'] ?? '').toString(),
      createdAt: created is Timestamp ? created.toDate() : null,
      updatedAt: updated is Timestamp ? updated.toDate() : null,
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
