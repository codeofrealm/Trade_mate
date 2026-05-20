import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../admin/data/models/admin_product.dart';
import '../../../data/models/home_user_address.dart';

class HomeProductImage extends StatelessWidget {
  const HomeProductImage({super.key, required this.product});
  final AdminProduct product;

  @override
  Widget build(BuildContext context) {
    final b64 = product.imageBase64?.trim() ?? '';
    final url = product.imageUrl?.trim() ?? '';
    if (b64.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(b64),
          fit: BoxFit.cover,
          width: double.infinity,
        );
      } catch (_) {}
    }
    if (url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => const _ImgFallback(),
      );
    }
    return const _ImgFallback();
  }
}

class _ImgFallback extends StatelessWidget {
  const _ImgFallback();

  @override
  Widget build(BuildContext context) => const Center(
        child: Icon(Icons.photo_outlined, color: Color(0xFFC7C7CC), size: 48),
      );
}

class HomePill extends StatelessWidget {
  const HomePill({super.key, required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

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
          IconButton(
            onPressed: onMinus,
            icon: const Icon(Icons.remove, size: 17),
          ),
          Expanded(
            child: Center(
              child: Text(
                '$quantity',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          IconButton(onPressed: onPlus, icon: const Icon(Icons.add, size: 17)),
        ],
      ),
    );
  }
}

class HomeAddressStatusCard extends StatelessWidget {
  const HomeAddressStatusCard({
    super.key,
    required this.address,
    this.onOpenProfile,
  });
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
          color: ok ? const Color(0xFF86EFAC) : const Color(0xFFFCD34D),
        ),
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
            Text(
              '${address.fullName}, ${address.line1}, ${address.city}',
              style: const TextStyle(color: Color(0xFF475569), fontSize: 12.5),
            ),
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
