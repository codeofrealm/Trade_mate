import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProductReview {
  const AdminProductReview({
    required this.id,
    required this.productId,
    required this.productName,
    required this.reviewerName,
    required this.comment,
    required this.rating,
    this.createdAt,
  });

  final String id;
  final String productId;
  final String productName;
  final String reviewerName;
  final String comment;
  final double rating;
  final DateTime? createdAt;

  factory AdminProductReview.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final timestamp = data['createdAt'];

    return AdminProductReview(
      id: id,
      productId: (data['productId'] ?? '').toString(),
      productName: (data['productName'] ?? '').toString(),
      reviewerName: (data['reviewerName'] ?? '').toString(),
      comment: (data['comment'] ?? '').toString(),
      rating: (data['rating'] is num)
          ? (data['rating'] as num).toDouble()
          : double.tryParse(data['rating']?.toString() ?? '') ?? 0,
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}
