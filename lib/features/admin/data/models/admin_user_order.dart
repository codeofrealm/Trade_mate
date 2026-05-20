import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserOrder {
  const AdminUserOrder({
    required this.id,
    required this.userId,
    required this.productId,
    required this.productName,
    required this.productCategory,
    required this.productPrice,
    required this.productCostPrice,
    required this.quantity,
    required this.totalAmount,
    required this.profitAmount,
    required this.lossAmount,
    required this.status,
    required this.customerName,
    required this.phone,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
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
  final double productCostPrice;
  final int quantity;
  final double totalAmount;
  final double profitAmount;
  final double lossAmount;
  final String status;
  final String customerName;
  final String phone;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String postalCode;
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
      addressLine2.trim(),
      city.trim(),
      [state.trim(), postalCode.trim()].where((part) => part.isNotEmpty).join(' - '),
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
    final explicitProfit = _firstExistingDouble(data, const [
      'profitAmount',
      'profit',
      'totalProfit',
    ]);
    final explicitLoss = _firstExistingDouble(data, const [
      'lossAmount',
      'loss',
      'totalLoss',
    ]);

    return AdminUserOrder(
      id: id,
      userId: (data['userId'] ?? '').toString(),
      productId: (data['productId'] ?? '').toString(),
      productName: (data['productName'] ?? '').toString(),
      productCategory: (data['productCategory'] ?? '').toString(),
      productPrice: _asDouble(data['productPrice']),
      productCostPrice: _firstDouble(data, const [
        'productCostPrice',
        'costPrice',
        'buyPrice',
        'purchasePrice',
        'basePrice',
      ]),
      quantity: _asInt(data['quantity']),
      totalAmount: _asDouble(data['totalAmount']),
      profitAmount:
          explicitProfit != null && explicitProfit > 0 ? explicitProfit : 0,
      lossAmount:
          _normalizeLoss(explicitLoss) + _negativeAsLoss(explicitProfit),
      status: (data['status'] ?? '').toString(),
      customerName: (address['fullName'] ?? '').toString(),
      phone: (address['phone'] ?? '').toString(),
      addressLine1: (address['line1'] ?? '').toString(),
      addressLine2: (address['line2'] ?? '').toString(),
      city: (address['city'] ?? '').toString(),
      state: (address['state'] ?? '').toString(),
      postalCode: (address['postalCode'] ?? '').toString(),
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

double _firstDouble(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    if (data.containsKey(key)) {
      final value = _asDouble(data[key]);
      if (value > 0) {
        return value;
      }
    }
  }
  return 0;
}

double? _firstExistingDouble(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    if (data.containsKey(key)) {
      return _asDouble(data[key]);
    }
  }
  return null;
}

double _normalizeLoss(double? value) {
  if (value == null) {
    return 0;
  }
  return value < 0 ? -value : value;
}

double _negativeAsLoss(double? value) {
  if (value == null || value >= 0) {
    return 0;
  }
  return -value;
}
