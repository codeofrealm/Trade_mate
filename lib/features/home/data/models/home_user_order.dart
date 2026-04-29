import 'package:cloud_firestore/cloud_firestore.dart';

class HomeUserOrder {
  const HomeUserOrder({
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

  String get cleanStatus {
    final value = status.trim().toLowerCase();
    if (value.isEmpty) {
      return 'placed';
    }
    return value;
  }

  int get progressStepIndex {
    switch (cleanStatus) {
      case 'placed':
      case 'pending':
        return 0;
      case 'confirmed':
      case 'processing':
      case 'packed':
        return 1;
      case 'shipped':
      case 'out_for_delivery':
      case 'out for delivery':
        return 2;
      case 'delivered':
        return 3;
      default:
        return cleanStatus == 'cancelled' || cleanStatus == 'canceled' ? -1 : 0;
    }
  }

  bool get isCancelled =>
      cleanStatus == 'cancelled' || cleanStatus == 'canceled';

  bool get isDelivered => cleanStatus == 'delivered';

  String get statusLabel {
    final value = cleanStatus.replaceAll('_', ' ');
    if (value.isEmpty) {
      return 'Placed';
    }
    return value[0].toUpperCase() + value.substring(1);
  }

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

  factory HomeUserOrder.fromFirestore(String id, Map<String, dynamic> data) {
    final created = data['createdAt'];
    final updated = data['updatedAt'];
    final rawAddress = data['address'];
    final address = rawAddress is Map<String, dynamic>
        ? rawAddress
        : <String, dynamic>{};

    return HomeUserOrder(
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
