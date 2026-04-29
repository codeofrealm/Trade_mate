import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/admin_product.dart';
import '../../data/services/admin_catalog_service.dart';
import '../widgets/product_form/admin_product_form_widgets.dart';

class AdminProductFormArgs {
  const AdminProductFormArgs({this.product});

  final AdminProduct? product;
}

class AdminProductFormPage extends StatefulWidget {
  const AdminProductFormPage({super.key});

  @override
  State<AdminProductFormPage> createState() => _AdminProductFormPageState();
}

class _AdminProductFormPageState extends State<AdminProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _soldCountController = TextEditingController();
  final _reviewCountController = TextEditingController();
  final _ratingController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  AdminProduct? _editingProduct;
  bool _isActive = true;
  bool _isSaving = false;
  bool _isPickingImage = false;
  bool _isInitialized = false;
  String? _imageBase64;

  bool get _isEditMode => _editingProduct != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) {
      return;
    }

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is AdminProductFormArgs && args.product != null) {
      _editingProduct = args.product;
      _nameController.text = args.product!.name;
      _categoryController.text = args.product!.category;
      _descriptionController.text = args.product!.description;
      _priceController.text = args.product!.price.toStringAsFixed(2);
      _stockController.text = args.product!.stock.toString();
      _soldCountController.text = args.product!.soldCount.toString();
      _reviewCountController.text = args.product!.reviewCount.toString();
      _ratingController.text = args.product!.rating.toStringAsFixed(1);
      _imageUrlController.text = args.product!.imageUrl ?? '';
      _imageBase64 = args.product!.imageBase64;
      _isActive = args.product!.isActive;
    } else {
      _soldCountController.text = '0';
      _reviewCountController.text = '0';
      _ratingController.text = '0';
    }

    _isInitialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _soldCountController.dispose();
    _reviewCountController.dispose();
    _ratingController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate() || _isSaving) {
      return;
    }

    final price = double.parse(_priceController.text.trim());
    final stock = int.parse(_stockController.text.trim());
    final sold = int.parse(_soldCountController.text.trim());
    final reviews = int.parse(_reviewCountController.text.trim());
    final rating = double.parse(_ratingController.text.trim());

    setState(() => _isSaving = true);

    final draft = AdminProductDraft(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _categoryController.text.trim(),
      price: price,
      stock: stock,
      soldCount: sold,
      reviewCount: reviews,
      rating: rating,
      isActive: _isActive,
      imageUrl: _imageUrlController.text.trim().isEmpty
          ? null
          : _imageUrlController.text.trim(),
      imageBase64: _imageBase64,
    );

    try {
      if (_isEditMode) {
        await AdminCatalogService.instance.updateProduct(
          productId: _editingProduct!.id,
          draft: draft,
        );
      } else {
        await AdminCatalogService.instance.createProduct(draft);
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Product updated successfully.'
                : 'Product uploaded successfully.',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save product. Try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickImage() async {
    if (_isPickingImage || _isSaving) {
      return;
    }

    setState(() => _isPickingImage = true);

    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 55,
        maxWidth: 1000,
        maxHeight: 1000,
      );

      if (picked == null) {
        return;
      }

      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) {
        return;
      }

      setState(() {
        _imageBase64 = base64Encode(bytes);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to select image. Try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  void _clearImage() {
    if (_isSaving) {
      return;
    }
    setState(() {
      _imageBase64 = null;
      _imageUrlController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
        automaticallyImplyLeading: false,
        title: Text(_isEditMode ? 'Edit Product' : 'Add Product'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              // ── Image picker ──
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E5EA)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _isPickingImage
                      ? const Center(
                          child: CircularProgressIndicator.adaptive(),
                        )
                      : _imageBase64 != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(
                              base64Decode(_imageBase64!),
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: _clearImage,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : _imageUrlController.text.trim().isNotEmpty
                      ? Image.network(
                          _imageUrlController.text.trim(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Tap to select image',
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Basic Details ──
              AdminSectionLabel(text: 'Basic Details'),
              const SizedBox(height: 10),
              AdminFormField(
                controller: _nameController,
                label: 'Product Name',
                icon: Icons.inventory_2_outlined,
                action: TextInputAction.next,
                validator: (v) => (v ?? '').trim().length < 2
                    ? 'Enter at least 2 characters.'
                    : null,
              ),
              const SizedBox(height: 10),
              AdminFormField(
                controller: _categoryController,
                label: 'Category',
                icon: Icons.category_outlined,
                action: TextInputAction.next,
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Category is required.' : null,
              ),
              const SizedBox(height: 10),
              AdminFormField(
                controller: _descriptionController,
                label: 'Description',
                icon: Icons.notes_rounded,
                action: TextInputAction.next,
                minLines: 3,
                maxLines: 4,
                validator: (v) => (v ?? '').trim().length < 8
                    ? 'At least 8 characters required.'
                    : null,
              ),
              const SizedBox(height: 20),

              // ── Price & Stock ──
              AdminSectionLabel(text: 'Price & Stock'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: AdminFormField(
                      controller: _priceController,
                      label: 'Price (Rs)',
                      icon: Icons.currency_rupee_rounded,
                      keyboard: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      action: TextInputAction.next,
                      validator: _validatePositiveDouble,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AdminFormField(
                      controller: _stockController,
                      label: 'Stock',
                      icon: Icons.warehouse_outlined,
                      keyboard: TextInputType.number,
                      action: TextInputAction.next,
                      validator: _validateNonNegativeInt,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AdminFormField(
                controller: _soldCountController,
                label: 'Sold Count',
                icon: Icons.shopping_bag_outlined,
                keyboard: TextInputType.number,
                action: TextInputAction.next,
                validator: _validateNonNegativeInt,
              ),
              const SizedBox(height: 20),

              // ── Reviews & Rating ──
              AdminSectionLabel(text: 'Reviews & Rating'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: AdminFormField(
                      controller: _reviewCountController,
                      label: 'Review Count',
                      icon: Icons.reviews_outlined,
                      keyboard: TextInputType.number,
                      action: TextInputAction.next,
                      validator: _validateNonNegativeInt,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AdminFormField(
                      controller: _ratingController,
                      label: 'Rating (0–5)',
                      icon: Icons.star_outline_rounded,
                      keyboard: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      action: TextInputAction.next,
                      validator: _validateRating,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AdminFormField(
                controller: _imageUrlController,
                label: 'Image URL (optional)',
                icon: Icons.link_rounded,
                action: TextInputAction.done,
                validator: (_) => null,
              ),
              const SizedBox(height: 16),

              // ── Active toggle ──
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E5EA)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.toggle_on_outlined,
                      color: Color(0xFF8E8E93),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Product Active',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                          color: Color(0xFF000000),
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: _isActive,
                      activeColor: const Color(0xFF34C759),
                      onChanged: _isSaving
                          ? null
                          : (v) => setState(() => _isActive = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Save button ──
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveProduct,
                  icon: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _isEditMode
                              ? Icons.save_rounded
                              : Icons.cloud_upload_rounded,
                        ),
                  label: Text(
                    _isEditMode ? 'Save Changes' : 'Upload Product',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF007AFF).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.add_photo_alternate_outlined,
            color: Color(0xFF007AFF),
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tap to add product image',
          style: TextStyle(
            color: Color(0xFF8E8E93),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String? _validatePositiveDouble(String? value) {
    final parsed = double.tryParse((value ?? '').trim());
    if (parsed == null || parsed <= 0) {
      return 'Enter a valid amount greater than 0.';
    }
    return null;
  }

  String? _validateNonNegativeInt(String? value) {
    final parsed = int.tryParse((value ?? '').trim());
    if (parsed == null || parsed < 0) {
      return 'Enter a valid number (0 or greater).';
    }
    return null;
  }

  String? _validateRating(String? value) {
    final parsed = double.tryParse((value ?? '').trim());
    if (parsed == null || parsed < 0 || parsed > 5) {
      return 'Rating must be between 0 and 5.';
    }
    return null;
  }
}


