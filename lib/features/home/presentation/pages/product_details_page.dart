import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../../admin/data/models/admin_product.dart';
import '../../data/home_product_service.dart';
import '../../data/home_user_profile_service.dart';
import '../../data/models/home_user_address.dart';
import '../widgets/product_details/home_product_detail_widgets.dart';
import 'order_success_page.dart';

class ProductDetailsPageArgs {
  const ProductDetailsPageArgs({this.product, this.productId, this.productName});

  final AdminProduct? product;
  final String? productId;
  final String? productName;
}

class ProductDetailsPage extends StatefulWidget {
  const ProductDetailsPage({super.key});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  bool _isAddingToCart = false;
  bool _isOrdering = false;
  int _quantity = 1;

  ProductDetailsPageArgs get _args {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ProductDetailsPageArgs) return args;
    return const ProductDetailsPageArgs();
  }

  Future<void> _addToCart(AdminProduct product) async {
    if (_isAddingToCart) return;
    setState(() => _isAddingToCart = true);
    try {
      await HomeProductService.instance.addToCart(product: product, quantity: _quantity);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added to cart.')),
      );
    } on HomeProductException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  Future<void> _placeOrder({required AdminProduct product, required HomeUserAddress address}) async {
    if (_isOrdering) return;
    setState(() => _isOrdering = true);
    try {
      final orderId = await HomeProductService.instance.placeOrder(
        product: product, address: address, quantity: _quantity,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacementNamed(
        AppRoutes.orderSuccess,
        arguments: OrderSuccessPageArgs(
          productName: product.name,
          quantity: _quantity,
          totalAmount: product.price * _quantity,
          orderId: orderId,
        ),
      );
    } on HomeProductException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isOrdering = false);
    }
  }

  Future<void> _openProfilePage({bool showAddressHint = false}) async {
    if (!mounted) return;
    if (showAddressHint) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete your address in Profile to order.')),
      );
    }
    await Navigator.of(context).pushNamed(AppRoutes.homeProfile);
  }

  @override
  Widget build(BuildContext context) {
    final args = _args;

    // If navigated from order card with only productId
    if (args.product == null && (args.productId?.isNotEmpty ?? false)) {
      return _ProductLoader(
        productId: args.productId!,
        fallbackName: args.productName ?? '',
      );
    }

    final product = args.product;
    if (product == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        appBar: AppBar(title: const Text('Product Details')),
        body: const Center(child: Text('Product not found.')),
      );
    }

    return _ProductDetailsBody(
      product: product,
      quantity: _quantity,
      isAddingToCart: _isAddingToCart,
      isOrdering: _isOrdering,
      onAddToCart: (p) => _addToCart(p),
      onPlaceOrder: (p, a) => _placeOrder(product: p, address: a),
      onOpenProfile: ({bool showAddressHint = false}) => _openProfilePage(showAddressHint: showAddressHint),
      onQuantityChanged: (q) => setState(() => _quantity = q),
    );
  }
}

// Loads product from Firestore when navigated from order card
class _ProductLoader extends StatelessWidget {
  const _ProductLoader({required this.productId, required this.fallbackName});

  final String productId;
  final String fallbackName;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('products').doc(productId).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Scaffold(
            backgroundColor: const Color(0xFFF2F2F7),
            appBar: AppBar(title: Text(fallbackName.isEmpty ? 'Product' : fallbackName)),
            body: const Center(child: CircularProgressIndicator.adaptive()),
          );
        }
        if (!snap.data!.exists || snap.data!.data() == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFF2F2F7),
            appBar: AppBar(title: const Text('Product Details')),
            body: const Center(child: Text('Product not found.')),
          );
        }
        final product = AdminProduct.fromFirestore(snap.data!.id, snap.data!.data()!);
        return _FullProductDetailsPage(product: product);
      },
    );
  }
}

// Full stateful page when product is loaded
class _FullProductDetailsPage extends StatefulWidget {
  const _FullProductDetailsPage({required this.product});
  final AdminProduct product;

  @override
  State<_FullProductDetailsPage> createState() => _FullProductDetailsPageState();
}

class _FullProductDetailsPageState extends State<_FullProductDetailsPage> {
  bool _isAddingToCart = false;
  bool _isOrdering = false;
  int _quantity = 1;

  Future<void> _addToCart() async {
    if (_isAddingToCart) return;
    setState(() => _isAddingToCart = true);
    try {
      await HomeProductService.instance.addToCart(product: widget.product, quantity: _quantity);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added to cart.')),
      );
    } on HomeProductException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  Future<void> _placeOrder(HomeUserAddress address) async {
    if (_isOrdering) return;
    setState(() => _isOrdering = true);
    try {
      final orderId = await HomeProductService.instance.placeOrder(
        product: widget.product, address: address, quantity: _quantity,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacementNamed(
        AppRoutes.orderSuccess,
        arguments: OrderSuccessPageArgs(
          productName: widget.product.name,
          quantity: _quantity,
          totalAmount: widget.product.price * _quantity,
          orderId: orderId,
        ),
      );
    } on HomeProductException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isOrdering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ProductDetailsBody(
      product: widget.product,
      quantity: _quantity,
      isAddingToCart: _isAddingToCart,
      isOrdering: _isOrdering,
      onAddToCart: (_) => _addToCart(),
      onPlaceOrder: (p, a) => _placeOrder(a),
      onOpenProfile: ({bool showAddressHint = false}) async {
        if (showAddressHint) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please complete your address in Profile to order.')),
          );
        }
        await Navigator.of(context).pushNamed(AppRoutes.homeProfile);
      },
      onQuantityChanged: (q) => setState(() => _quantity = q),
    );
  }
}

// ── Shared body ───────────────────────────────────────────────────────────────

class _ProductDetailsBody extends StatelessWidget {
  const _ProductDetailsBody({
    required this.product,
    required this.quantity,
    required this.isAddingToCart,
    required this.isOrdering,
    required this.onAddToCart,
    required this.onPlaceOrder,
    required this.onOpenProfile,
    required this.onQuantityChanged,
  });

  final AdminProduct product;
  final int quantity;
  final bool isAddingToCart;
  final bool isOrdering;
  final Future<void> Function(AdminProduct) onAddToCart;
  final Future<void> Function(AdminProduct, HomeUserAddress) onPlaceOrder;
  final Future<void> Function({bool showAddressHint}) onOpenProfile;
  final void Function(int) onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<HomeUserAddress>(
      stream: HomeUserProfileService.instance.streamAddress(),
      builder: (context, addressSnap) {
        final address = addressSnap.data ?? HomeUserAddress.empty;
        final purchasable = product.isActive && product.stock > 0;

        return Scaffold(
          backgroundColor: const Color(0xFFF2F2F7),
          appBar: AppBar(
            title: const Text('Product Details'),
            backgroundColor: const Color(0xFFF2F2F7),
            actions: [
              IconButton(
                onPressed: () => onOpenProfile(),
                icon: const Icon(Icons.person_outline_rounded),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  height: 240,
                  color: const Color(0xFFE5E5EA),
                  child: HomeProductImage(product: product),
                ),
              ),
              const SizedBox(height: 12),

              // Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardDeco(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                            color: Color(0xFF000000), letterSpacing: -0.4)),
                    const SizedBox(height: 4),
                    Text(product.category,
                        style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text('Rs ${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                                color: Color(0xFF007AFF), letterSpacing: -0.4)),
                        const Spacer(),
                        HomePill(
                          text: product.isActive ? 'In Stock' : 'Inactive',
                          color: product.isActive ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                        ),
                      ],
                    ),
                    if (product.description.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(product.description,
                          style: const TextStyle(color: Color(0xFF3C3C43), height: 1.5, fontSize: 14)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Quantity + address
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardDeco(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Quantity',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
                            color: Color(0xFF000000))),
                    const SizedBox(height: 8),
                    HomeQuantityControl(
                      quantity: quantity,
                      maxStock: product.stock,
                      onMinus: quantity > 1 ? () => onQuantityChanged(quantity - 1) : null,
                      onPlus: quantity < product.stock ? () => onQuantityChanged(quantity + 1) : null,
                    ),
                    const SizedBox(height: 12),
                    HomeAddressStatusCard(address: address, onOpenProfile: () => onOpenProfile()),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text('Reviews',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                      color: Color(0xFF000000), letterSpacing: -0.3)),
              const SizedBox(height: 10),
              HomeReviewsList(productId: product.id),
              const SizedBox(height: 16),
              HomeWriteReviewBox(product: product),
              const SizedBox(height: 80),
            ],
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E5EA)),
                boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, -2))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (product.stock <= 0 || !product.isActive || isAddingToCart)
                          ? null
                          : () => onAddToCart(product),
                      icon: isAddingToCart
                          ? const SizedBox(width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.add_shopping_cart_outlined),
                      label: const Text('Add Cart'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: (purchasable && !isOrdering)
                          ? () {
                              if (!address.isComplete) {
                                onOpenProfile(showAddressHint: true);
                                return;
                              }
                              onPlaceOrder(product, address);
                            }
                          : null,
                      icon: isOrdering
                          ? const SizedBox(width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.shopping_bag_outlined),
                      label: const Text('Buy Now'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _cardDeco() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xFFE5E5EA)),
  );
}


