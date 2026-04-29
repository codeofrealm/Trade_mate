import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../app/ui/glass.dart';
import '../../../admin/data/models/admin_product.dart';
import '../../data/models/home_user_order.dart';

class OrderDetailsPage extends StatelessWidget {
  const OrderDetailsPage({super.key});

  HomeUserOrder _args(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is HomeUserOrder) {
      return args;
    }
    return const HomeUserOrder(
      id: '',
      userId: '',
      productId: '',
      productName: 'Order',
      productCategory: '',
      productPrice: 0,
      quantity: 1,
      totalAmount: 0,
      status: 'placed',
      addressLine1: '',
      city: '',
      state: '',
      country: '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = _args(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: GlassBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProductCard(order: order),
                const SizedBox(height: 12),
                _OrderSummaryCard(order: order),
                const SizedBox(height: 12),
                _AddressCard(order: order),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.order});

  final HomeUserOrder order;

  @override
  Widget build(BuildContext context) {
    if (order.productId.trim().isEmpty) {
      return GlassContainer(
        child: Row(
          children: [
            const _FallbackImage(),
            const SizedBox(width: 12),
            Expanded(
              child: _ProductInfo(
                name: order.productName,
                category: order.productCategory,
                price: order.productPrice,
              ),
            ),
          ],
        ),
      );
    }

    final docRef = FirebaseFirestore.instance
        .collection('products')
        .doc(order.productId.trim());

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: docRef.snapshots(),
      builder: (context, snapshot) {
        AdminProduct? product;
        if (snapshot.hasData && snapshot.data!.data() != null) {
          product = AdminProduct.fromFirestore(
            snapshot.data!.id,
            snapshot.data!.data()!,
          );
        }

        final imageUrl = product?.imageUrl?.trim() ?? '';
        final imageBase64 = product?.imageBase64?.trim() ?? '';
        final name = (product?.name.trim().isNotEmpty == true)
            ? product!.name
            : order.productName;
        final category = (product?.category.trim().isNotEmpty == true)
            ? product!.category
            : order.productCategory;
        final price = product?.price ?? order.productPrice;

        return GlassContainer(
          child: Row(
            children: [
              _ProductImage(url: imageUrl, base64Data: imageBase64),
              const SizedBox(width: 12),
              Expanded(
                child: _ProductInfo(
                  name: name,
                  category: category,
                  price: price,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProductInfo extends StatelessWidget {
  const _ProductInfo({
    required this.name,
    required this.category,
    required this.price,
  });

  final String name;
  final String category;
  final double price;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name.trim().isEmpty ? 'Product' : name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        if (category.trim().isNotEmpty)
          Text(
            category,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'Rs ${price.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Color(0xFF1D4ED8),
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.order});

  final HomeUserOrder order;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          _RowItem(label: 'Order ID', value: order.id.isEmpty ? '-' : order.id),
          const SizedBox(height: 8),
          _RowItem(label: 'Status', value: order.statusLabel),
          const SizedBox(height: 8),
          _RowItem(label: 'Quantity', value: order.quantity.toString()),
          const SizedBox(height: 8),
          _RowItem(
            label: 'Total Amount',
            value: 'Rs ${order.totalAmount.toStringAsFixed(2)}',
            emphasize: true,
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.order});

  final HomeUserOrder order;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_outlined, color: Color(0xFF0F172A)),
              SizedBox(width: 8),
              Text(
                'Delivery Address',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            order.addressSummary,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  const _RowItem({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: emphasize ? const Color(0xFF0F172A) : const Color(0xFF334155),
            fontWeight: emphasize ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.url, required this.base64Data});

  final String url;
  final String base64Data;

  @override
  Widget build(BuildContext context) {
    Widget child = const _FallbackImage();

    if (base64Data.trim().isNotEmpty) {
      try {
        child = Image.memory(
          base64Decode(base64Data),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const _FallbackImage(),
        );
      } catch (_) {
        child = const _FallbackImage();
      }
    } else if (url.trim().isNotEmpty) {
      child = Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const _FallbackImage(),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 82,
        height: 82,
        color: const Color(0xFFE2E8F0),
        child: child,
      ),
    );
  }
}

class _FallbackImage extends StatelessWidget {
  const _FallbackImage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.shopping_bag_outlined, color: Color(0xFF64748B)),
    );
  }
}
