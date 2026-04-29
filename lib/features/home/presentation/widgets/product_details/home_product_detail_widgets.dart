import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../admin/data/models/admin_product.dart';
import '../../../../admin/data/models/admin_product_review.dart';
import '../../../../auth/data/auth_user_store.dart';
import '../../../data/home_product_service.dart';
import '../../../data/models/home_user_address.dart';

// ── Product image ─────────────────────────────────────────────────────────────

class HomeProductImage extends StatelessWidget {
  const HomeProductImage({super.key, required this.product});
  final AdminProduct product;

  @override
  Widget build(BuildContext context) {
    final b64 = product.imageBase64?.trim() ?? '';
    final url = product.imageUrl?.trim() ?? '';
    if (b64.isNotEmpty) {
      try {
        return Image.memory(base64Decode(b64),
            fit: BoxFit.cover, width: double.infinity);
      } catch (_) {}
    }
    if (url.isNotEmpty) {
      return Image.network(url,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) => const _ImgFallback());
    }
    return const _ImgFallback();
  }
}

class _ImgFallback extends StatelessWidget {
  const _ImgFallback();
  @override
  Widget build(BuildContext context) =>
      const Center(child: Icon(Icons.photo_outlined, color: Color(0xFFC7C7CC), size: 48));
}

// ── Pill ──────────────────────────────────────────────────────────────────────

class HomePill extends StatelessWidget {
  const HomePill({super.key, required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.3)),
    );
  }
}

// ── Quantity control ──────────────────────────────────────────────────────────

class HomeQuantityControl extends StatelessWidget {
  const HomeQuantityControl({
    super.key,
    required this.quantity,
    required this.maxStock,
    this.onMinus,
    this.onPlus,
  });
  final int quantity;
  final int maxStock;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Row(
        children: [
          IconButton(onPressed: onMinus, icon: const Icon(Icons.remove, size: 17)),
          Expanded(
            child: Center(
              child: Text('$quantity',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
          IconButton(onPressed: onPlus, icon: const Icon(Icons.add, size: 17)),
        ],
      ),
    );
  }
}

// ── Address status card ───────────────────────────────────────────────────────

class HomeAddressStatusCard extends StatelessWidget {
  const HomeAddressStatusCard(
      {super.key, required this.address, this.onOpenProfile});
  final HomeUserAddress address;
  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final ok = address.isComplete;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ok ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: ok ? const Color(0xFF86EFAC) : const Color(0xFFFCD34D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ok
                ? 'Address complete. You can place order.'
                : 'Address incomplete. Complete Profile to place order.',
            style: TextStyle(
              color: ok ? const Color(0xFF166534) : const Color(0xFF92400E),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          if (ok) ...[
            const SizedBox(height: 2),
            Text('${address.fullName}, ${address.line1}, ${address.city}',
                style: const TextStyle(color: Color(0xFF475569), fontSize: 12.5)),
          ],
          if (!ok && onOpenProfile != null) ...[
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: onOpenProfile,
              icon: const Icon(Icons.person_outline_rounded, size: 15),
              label: const Text('Open Profile'),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Reviews list ──────────────────────────────────────────────────────────────

class HomeReviewsList extends StatelessWidget {
  const HomeReviewsList({super.key, required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdminProductReview>>(
      stream: HomeProductService.instance.streamProductReviews(productId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: CircularProgressIndicator.adaptive(),
            ),
          );
        }
        final reviews = snap.data!;
        if (reviews.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E5EA)),
            ),
            child: const Text('No reviews yet. Be the first to review!',
                style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13.5)),
          );
        }
        return Column(
          children: reviews
              .take(10)
              .map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ReviewCard(review: r),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final AdminProductReview review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.reviewerName.isEmpty ? 'User' : review.reviewerName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF000000),
                      fontSize: 14),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating.round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 14,
                    color: i < review.rating.round()
                        ? const Color(0xFFFF9500)
                        : const Color(0xFFD1D1D6),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(review.rating.toStringAsFixed(1),
                  style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(review.comment,
                style: const TextStyle(
                    color: Color(0xFF3C3C43), fontSize: 13.5, height: 1.4)),
          ],
        ],
      ),
    );
  }
}

// ── Write review box ──────────────────────────────────────────────────────────

class HomeWriteReviewBox extends StatefulWidget {
  const HomeWriteReviewBox({super.key, required this.product});
  final AdminProduct product;

  @override
  State<HomeWriteReviewBox> createState() => _HomeWriteReviewBoxState();
}

class _HomeWriteReviewBoxState extends State<HomeWriteReviewBox> {
  int _stars = 0;
  final _commentCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final reviewerName =
          AuthUserStore.username?.trim().isNotEmpty == true
              ? AuthUserStore.username!.trim()
              : 'User';

      await FirebaseFirestore.instance.collection('product_reviews').add({
        'productId': widget.product.id,
        'productName': widget.product.name,
        'reviewerName': reviewerName,
        'comment': _commentCtrl.text.trim(),
        'rating': _stars.toDouble(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      final ref = FirebaseFirestore.instance
          .collection('products')
          .doc(widget.product.id);
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) return;
        final data = snap.data()!;
        final oldRating = (data['rating'] as num?)?.toDouble() ?? 0.0;
        final oldCount = (data['reviewCount'] as num?)?.toInt() ?? 0;
        final newCount = oldCount + 1;
        final newRating = ((oldRating * oldCount) + _stars) / newCount;
        tx.update(ref, {
          'rating': newRating,
          'reviewCount': newCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;
      setState(() {
        _stars = 0;
        _commentCtrl.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted. Thank you!')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit review. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Write a Review',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF000000),
                  letterSpacing: -0.3)),
          const SizedBox(height: 4),
          const Text('Share your experience with this product',
              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12.5)),
          const SizedBox(height: 14),
          Row(
            children: List.generate(
              5,
              (i) => GestureDetector(
                onTap: () => setState(() => _stars = i + 1),
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    i < _stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 36,
                    color: i < _stars
                        ? const Color(0xFFFF9500)
                        : const Color(0xFFD1D1D6),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Write your comment (optional)...',
              filled: true,
              fillColor: const Color(0xFFF2F2F7),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E5EA))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E5EA))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF007AFF), width: 1.5)),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Review',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
