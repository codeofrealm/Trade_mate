import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProduct {
  const AdminProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.costPrice,
    required this.stock,
    required this.soldCount,
    required this.reviewCount,
    required this.rating,
    required this.isActive,
    this.imageUrl,
    this.imageBase64,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final double costPrice;
  final int stock;
  final int soldCount;
  final int reviewCount;
  final double rating;
  final bool isActive;
  final String? imageUrl;
  final String? imageBase64;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AdminProduct.fromFirestore(String id, Map<String, dynamic> data) {
    return AdminProduct(
      id: id,
      name: (data['name'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      price: _asDouble(data['price']),
      costPrice: _firstDouble(data, const [
        'costPrice',
        'buyPrice',
        'purchasePrice',
        'basePrice',
      ]),
      stock: _asInt(data['stock']),
      soldCount: _asInt(data['soldCount']),
      reviewCount: _asInt(data['reviewCount']),
      rating: _asDouble(data['rating']),
      isActive: data['isActive'] == true,
      imageUrl: (data['imageUrl'] ?? '').toString().trim().isEmpty
          ? null
          : data['imageUrl'].toString().trim(),
      imageBase64: (data['imageBase64'] ?? '').toString().trim().isEmpty
          ? null
          : data['imageBase64'].toString().trim(),
      createdAt: _asDate(data['createdAt']),
      updatedAt: _asDate(data['updatedAt']),
    );
  }
}

class AdminProductDraft {
  const AdminProductDraft({
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    this.costPrice = 0,
    required this.stock,
    this.soldCount = 0,
    this.reviewCount = 0,
    this.rating = 0,
    this.isActive = true,
    this.imageUrl,
    this.imageBase64,
  });

  final String name;
  final String description;
  final String category;
  final double price;
  final double costPrice;
  final int stock;
  final int soldCount;
  final int reviewCount;
  final double rating;
  final bool isActive;
  final String? imageUrl;
  final String? imageBase64;

  Map<String, dynamic> toFirestoreForCreate() {
    return {
      'name': name.trim(),
      'description': description.trim(),
      'category': category.trim(),
      'price': price,
      'costPrice': costPrice,
      'stock': stock,
      'soldCount': soldCount,
      'reviewCount': reviewCount,
      'rating': rating,
      'isActive': isActive,
      'imageUrl': imageUrl?.trim() ?? '',
      'imageBase64': imageBase64?.trim() ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toFirestoreForUpdate() {
    return {
      'name': name.trim(),
      'description': description.trim(),
      'category': category.trim(),
      'price': price,
      'costPrice': costPrice,
      'stock': stock,
      'soldCount': soldCount,
      'reviewCount': reviewCount,
      'rating': rating,
      'isActive': isActive,
      'imageUrl': imageUrl?.trim() ?? '',
      'imageBase64': imageBase64?.trim() ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    };
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

DateTime? _asDate(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  return null;
}
