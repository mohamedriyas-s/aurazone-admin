import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/product_provider.dart';
import '../../providers/store_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

class AdminProducts extends StatelessWidget {
  const AdminProducts({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Products'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => _showSearchSheet(context),
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            onPressed: () => _showFilterSheet(context),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: products.products.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 64, color: AppColors.textTertiary),
                  const SizedBox(height: 16),
                  const Text(
                    'No products found',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => context.read<ProductProvider>().fetchProducts(),
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: products.products.length,
                itemBuilder: (context, index) {
                  final product = products.products[index];
                  final category = context.read<CategoryProvider>().categories.firstWhere(
                    (c) => c.id == product.category,
                    orElse: () => Category(id: '', storeId: '', name: 'Unknown', slug: ''),
                  );
                  return _ProductCard(
                    product: product,
                    categoryName: category.name,
                    onEdit: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AddEditProductScreen(product: product),
                      ),
                    ),
                    onDelete: () => _confirmDelete(context, product),
                    onToggle: () =>
                        products.toggleProductActive(product.id),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AddEditProductScreen(),
          ),
        ),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Product',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  void _showSearchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                autofocus: true,
                onChanged: (v) => context.read<ProductProvider>().setSearchQuery(v),
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      context.read<ProductProvider>().setSearchQuery('');
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: context.watch<ProductProvider>().categories.map((cat) {
                  final isSelected =
                      context.watch<ProductProvider>().selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppColors.accent.withValues(alpha: 0.15),
                    onSelected: (_) {
                      context.read<ProductProvider>().setCategory(cat);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Text(
                'Gender',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ProductProvider.genders.map((g) {
                  final isSelected =
                      context.watch<ProductProvider>().selectedGender == g;
                  return ChoiceChip(
                    label: Text(g),
                    selected: isSelected,
                    selectedColor: AppColors.accent.withValues(alpha: 0.15),
                    onSelected: (_) {
                      context.read<ProductProvider>().setGender(g);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ProductProvider>().deleteProduct(product.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.name} deleted'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final String categoryName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _ProductCard({
    required this.product,
    required this.categoryName,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Product Image
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      product.imageUrls.isNotEmpty
                          ? product.imageUrls.first
                          : '',
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.image,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                  if (!product.isActive)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'INACTIVE',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            categoryName,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (product.gender.isNotEmpty && product.gender != 'Not Specified')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.gender,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Text(
                          currencyFormat.format(product.price),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (product.originalPrice != null) ...[
                          Text(
                            currencyFormat.format(product.originalPrice),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 12,
                          color: product.isOutOfStock
                              ? AppColors.error
                              : product.isLowStock
                                  ? AppColors.warning
                                  : AppColors.success,
                        ),
                        Text(
                          product.isOutOfStock
                              ? 'Out of stock'
                              : product.isLowStock
                                  ? '${product.stockQuantity} left (Low)'
                                  : '${product.stockQuantity} in stock',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: product.isOutOfStock
                                ? AppColors.error
                                : product.isLowStock
                                    ? AppColors.warning
                                    : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'toggle':
                      onToggle();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          product.isActive
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(product.isActive ? 'Deactivate' : 'Activate'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                        SizedBox(width: 10),
                        Text('Delete', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.more_vert_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ===================== ADD / EDIT PRODUCT SCREEN =====================

class AddEditProductScreen extends StatefulWidget {
  final Product? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _originalPriceController;
  late TextEditingController _stockController;
  bool _isGenderEnabled = false;
  String _selectedGender = 'Men';
  String? _selectedStoreId;
  String? _selectedCategoryId;
  List<String> _selectedSizes = [];
  List<String> _selectedColors = [];
  List<String> _imageUrls = [];
  List<XFile> _pickedImages = [];

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreProvider>().fetchStores();
      context.read<CategoryProvider>().fetchCategories();
    });
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descController = TextEditingController(text: p?.description ?? '');
    _priceController = TextEditingController(
      text: p?.price.toStringAsFixed(0) ?? '',
    );
    _originalPriceController = TextEditingController(
      text: p?.originalPrice?.toStringAsFixed(0) ?? '',
    );
    _stockController = TextEditingController(
      text: p?.stockQuantity.toString() ?? '',
    );
    _selectedStoreId = p?.storeId;
    _selectedCategoryId = p?.categoryId;
    _selectedSizes = List.from(p?.sizes ?? []);
    _selectedColors = List.from(p?.colors ?? []);
    _isGenderEnabled = p != null && p.gender.isNotEmpty && p.gender != 'Not Specified';
    _selectedGender = _isGenderEnabled ? p!.gender : 'Men';
    _imageUrls = List.from(p?.imageUrls ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _stockController.dispose();
    // category, sizes, colors controllers removed
    super.dispose();
  }

  Future<void> _pickImages() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Upload Image',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.accent),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(ctx);
                _processImagePick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.accent),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _processImagePick(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processImagePick(ImageSource source) async {
    final picker = ImagePicker();
    List<XFile> images = [];

    if (source == ImageSource.camera) {
      final img = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (img != null) images.add(img);
    } else {
      final imgs = await picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      images.addAll(imgs);
    }

    if (images.isNotEmpty) {
      setState(() {
        // Limit to 4 images total
        final remaining = 4 - _imageUrls.length - _pickedImages.length;
        if (remaining > 0) {
          _pickedImages.addAll(images.take(remaining));
        }
      });
    }
  }

  bool _isSaving = false;

  void _removeImage(int index) {
    setState(() {
      if (index < _imageUrls.length) {
        _imageUrls.removeAt(index);
      } else {
        _pickedImages.removeAt(index - _imageUrls.length);
      }
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageUrls.isEmpty && _pickedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add at least one image'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() { _isSaving = true; });

    // sizes and colors lists are maintained directly

    List<String> uploadedUrls = [];
    try {
      for (var file in _pickedImages) {
        final ext = file.path.split('.').last.toLowerCase();
        String contentType = 'image/jpeg';
        if (ext == 'png') contentType = 'image/png';
        if (ext == 'webp') contentType = 'image/webp';
        if (ext == 'gif') contentType = 'image/gif';

        final presignRes = await ApiService.post('/upload/presigned-url', {
          'fileName': file.name,
          'contentType': contentType,
        });

        if (presignRes.statusCode != 200) {
          throw Exception('Failed to get upload URL: ${presignRes.body}');
        }

        final presignData = jsonDecode(presignRes.body)['data'];
        final uploadUrl = presignData['uploadUrl'];
        final publicUrl = presignData['publicUrl'];

        final imageBytes = await file.readAsBytes();
        final uploadRes = await http.put(
          Uri.parse(uploadUrl),
          headers: {'Content-Type': contentType},
          body: imageBytes,
        );

        if (uploadRes.statusCode == 200) {
          uploadedUrls.add(publicUrl);
        } else {
          throw Exception('Failed to upload to S3. Status: ${uploadRes.statusCode}');
        }
      }
    } catch (e) {
      setState(() { _isSaving = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading images: $e')));
      return;
    }

    final allImages = [
      ..._imageUrls,
      ...uploadedUrls,
    ];

    final sizes = _selectedSizes.isEmpty ? ['One Size'] : _selectedSizes;
    final colors = _selectedColors.isEmpty ? ['Default'] : _selectedColors;
    
    final price = double.parse(_priceController.text.trim());
    final originalPriceText = _originalPriceController.text.trim();
    final originalPrice = originalPriceText.isNotEmpty ? double.parse(originalPriceText) : null;
    final totalStock = int.parse(_stockController.text.trim());
    
    // Simple variant generator
    int stockPerVariant = totalStock ~/ (sizes.length * colors.length);
    if (stockPerVariant == 0 && totalStock > 0) stockPerVariant = 1;
    
    List<ProductVariant> generatedVariants = [];
    for (var size in sizes) {
      for (var color in colors) {
        String? existingId;
        if (widget.product != null && widget.product!.variants.isNotEmpty) {
          final match = widget.product!.variants.where((v) {
            final hasSize = v.attributes.any((a) => a.key == 'Size' && a.value == size);
            final hasColor = v.attributes.any((a) => a.key == 'Color' && a.value == color);
            return hasSize && hasColor;
          }).toList();
          if (match.isNotEmpty) {
            existingId = match.first.id;
          } else if (widget.product!.variants.length == 1 && sizes.length == 1 && colors.length == 1) {
            existingId = widget.product!.variants.first.id;
          }
        }

        generatedVariants.add(ProductVariant(
          id: existingId,
          sku: '${_nameController.text.trim().replaceAll(' ', '-').toUpperCase()}-$size-$color',
          price: price,
          compareAtPrice: originalPrice,
          quantity: stockPerVariant,
          imageUrls: allImages,
          attributes: [
            ProductVariantAttribute(key: 'Size', value: size),
            ProductVariantAttribute(key: 'Color', value: color),
          ]
        ));
      }
    }

    final storeProvider = context.read<StoreProvider>();
    final catProvider = context.read<CategoryProvider>();
    
    final storeId = _selectedStoreId ?? (storeProvider.stores.isNotEmpty ? storeProvider.stores.first.id : '');
    final storeCategories = catProvider.categories.where((c) => c.storeId == storeId).toList();
    final catId = _selectedCategoryId ?? (storeCategories.isNotEmpty ? storeCategories.first.id : '');

    if (storeId.isEmpty || catId.isEmpty) {
      setState(() { _isSaving = false; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot save: You must create at least 1 Store and 1 Category in the database first.')));
      return;
    }

    final product = Product(
      id: widget.product?.id,
      storeId: storeId,
      categoryId: catId,
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      gender: _isGenderEnabled ? _selectedGender : 'Not Specified',
      variants: generatedVariants,
      isActive: widget.product?.isActive ?? true,
      createdAt: widget.product?.createdAt,
    );

    final provider = context.read<ProductProvider>();
    try {
      if (isEditing) {
        await provider.updateProduct(product);
      } else {
        await provider.addProduct(product);
      }
      
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() { _isSaving = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving product: $e')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(isEditing ? 'Product updated!' : 'Product added!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalImages = _imageUrls.length + _pickedImages.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
        actions: [
          _isSaving 
            ? const Center(child: Padding(padding: EdgeInsets.only(right: 20), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
            : TextButton(
                onPressed: _saveProduct,
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Images section
            const Text(
              'Product Images',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Upload up to 4 images ($totalImages/4)',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Existing URL images
                  ..._imageUrls.asMap().entries.map((e) =>
                      _ImageTile(
                        imageUrl: e.value,
                        onRemove: () => _removeImage(e.key),
                      )),
                  // Picked local images
                  ..._pickedImages.asMap().entries.map((e) =>
                      _ImageTile(
                        file: File(e.value.path),
                        onRemove: () =>
                            _removeImage(_imageUrls.length + e.key),
                      )),
                  // Add button
                  if (totalImages < 4)
                    GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.border,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 28, color: AppColors.textTertiary),
                            SizedBox(height: 4),
                            Text(
                              'Add',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textTertiary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Store Selection
            _buildLabel('Store'),
            const SizedBox(height: 8),
            Consumer<StoreProvider>(
              builder: (context, storeProvider, child) {
                if (storeProvider.isLoading) return const CircularProgressIndicator();
                if (storeProvider.stores.isEmpty) return const Text('No stores available. Please create a store first.');
                
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(hintText: 'Select Store'),
                  value: _selectedStoreId ?? storeProvider.stores.first.id,
                  items: storeProvider.stores.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() { 
                        _selectedStoreId = val;
                        _selectedCategoryId = null; // Reset category when store changes
                      });
                    }
                  },
                );
              }
            ),
            const SizedBox(height: 20),

            // Category Selection
            _buildLabel('Category'),
            const SizedBox(height: 8),
            Consumer<CategoryProvider>(
              builder: (context, catProvider, child) {
                if (catProvider.isLoading) return const CircularProgressIndicator();
                
                final storeProvider = context.read<StoreProvider>();
                final currentStoreId = _selectedStoreId ?? (storeProvider.stores.isNotEmpty ? storeProvider.stores.first.id : null);
                final storeCategories = catProvider.categories.where((c) => c.storeId == currentStoreId).toList();

                if (storeCategories.isEmpty) return const Text('No categories available for this store.');

                // Ensure selected category is valid for current store
                if (_selectedCategoryId != null && !storeCategories.any((c) => c.id == _selectedCategoryId)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() { _selectedCategoryId = null; });
                  });
                }

                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(hintText: 'Select Category'),
                  value: _selectedCategoryId ?? storeCategories.first.id,
                  items: storeCategories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() { _selectedCategoryId = val; });
                    }
                  },
                );
              }
            ),
            const SizedBox(height: 24),

            // Name
            _buildLabel('Product Name'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'e.g. AuraRunner Pro X'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 20),

            // Description
            _buildLabel('Description'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Describe the product...',
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Description is required'
                  : null,
            ),
            const SizedBox(height: 20),

            // Price row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Price (₹)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                        decoration:
                            const InputDecoration(hintText: 'e.g. 4999'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(v.trim()) == null) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Original Price (₹)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _originalPriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                        decoration: const InputDecoration(
                          hintText: 'Optional',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Stock
            _buildLabel('Stock Quantity'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(hintText: 'e.g. 100'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (int.tryParse(v.trim()) == null) return 'Invalid';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Gender toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLabel('Enable Gender Selection'),
                Switch(
                  value: _isGenderEnabled,
                  activeColor: AppColors.accent,
                  onChanged: (val) {
                    setState(() {
                      _isGenderEnabled = val;
                      if (val && _selectedGender == 'Not Specified') {
                        _selectedGender = 'Men';
                      }
                    });
                  },
                ),
              ],
            ),
            if (_isGenderEnabled) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ProductProvider.genders
                    .where((g) => g != 'All')
                    .map((g) {
                  final isSelected = _selectedGender == g;
                  return ChoiceChip(
                    label: Text(g),
                    selected: isSelected,
                    selectedColor: AppColors.accent.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.accent : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedGender = g);
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 20),

            // Sizes
            _MultiTagInputWidget(
              label: 'Sizes',
              hint: 'e.g. M, L, XL',
              initialTags: _selectedSizes,
              suggestedTags: ProductProvider.availableSizes,
              onTagsChanged: (tags) => setState(() => _selectedSizes = tags),
            ),
            const SizedBox(height: 20),

            // Colors
            _MultiTagInputWidget(
              label: 'Colors',
              hint: 'e.g. Red, Blue',
              initialTags: _selectedColors,
              suggestedTags: ProductProvider.availableColors,
              onTagsChanged: (tags) => setState(() => _selectedColors = tags),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  isEditing ? 'Update Product' : 'Add Product',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  final String? imageUrl;
  final File? file;
  final VoidCallback onRemove;

  const _ImageTile({this.imageUrl, this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: imageUrl != null
                ? Image.network(
                    imageUrl!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 100,
                      height: 100,
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.broken_image,
                          color: AppColors.textTertiary),
                    ),
                  )
                : Image.file(
                    file!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _SingleTagInputWidget extends StatefulWidget {
  final String label;
  final String hint;
  final String initialValue;
  final List<String> suggestedTags;
  final Function(String) onChanged;

  const _SingleTagInputWidget({
    required this.label,
    required this.hint,
    required this.initialValue,
    required this.suggestedTags,
    required this.onChanged,
  });

  @override
  State<_SingleTagInputWidget> createState() => _SingleTagInputWidgetState();
}

class _SingleTagInputWidgetState extends State<_SingleTagInputWidget> {
  late String _selectedValue;
  bool _showInput = false;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectValue(String val) {
    final trimmed = val.trim();
    if (trimmed.isNotEmpty) {
      setState(() {
        _selectedValue = trimmed;
        _showInput = false;
      });
      widget.onChanged(_selectedValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...widget.suggestedTags.map((tag) {
              final isSelected = _selectedValue == tag;
              return ChoiceChip(
                label: Text(tag),
                selected: isSelected,
                selectedColor: AppColors.accent.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.accent : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
                onSelected: (_) => _selectValue(tag),
              );
            }),
            if (_selectedValue.isNotEmpty && !widget.suggestedTags.contains(_selectedValue))
              ChoiceChip(
                label: Text(_selectedValue),
                selected: true,
                selectedColor: AppColors.accent.withValues(alpha: 0.15),
                labelStyle: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                onSelected: (_) {},
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (!_showInput)
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showInput = true;
              });
            },
            icon: const Icon(Icons.add, size: 18),
            label: Text('Add Custom '),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              alignment: Alignment.centerLeft,
            ),
          )
        else
          TextFormField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: widget.hint,
              suffixIcon: IconButton(
                icon: const Icon(Icons.check_circle),
                onPressed: () {
                  _selectValue(_controller.text);
                  _controller.clear();
                },
              ),
            ),
            onChanged: (val) {
              if (val.endsWith(' ')) {
                _selectValue(val);
                _controller.clear();
              }
            },
            onFieldSubmitted: (val) {
              _selectValue(val);
              _controller.clear();
            },
          ),
      ],
    );
  }
}

class _MultiTagInputWidget extends StatefulWidget {
  final String label;
  final String hint;
  final List<String> initialTags;
  final List<String> suggestedTags;
  final Function(List<String>) onTagsChanged;

  const _MultiTagInputWidget({
    required this.label,
    required this.hint,
    required this.initialTags,
    required this.suggestedTags,
    required this.onTagsChanged,
  });

  @override
  State<_MultiTagInputWidget> createState() => _MultiTagInputWidgetState();
}

class _MultiTagInputWidgetState extends State<_MultiTagInputWidget> {
  late List<String> _tags;
  bool _showInput = false;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.initialTags);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isNotEmpty && !_tags.contains(trimmed)) {
      setState(() {
        _tags.add(trimmed);
        // Do not auto-hide input so they can add multiple easily,
        // but we clear the controller.
      });
      widget.onTagsChanged(_tags);
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
    widget.onTagsChanged(_tags);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...widget.suggestedTags.map((tag) {
              final isSelected = _tags.contains(tag);
              return ChoiceChip(
                label: Text(tag),
                selected: isSelected,
                selectedColor: AppColors.accent.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.accent : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
                onSelected: (_) {
                  if (isSelected) {
                    _removeTag(tag);
                  } else {
                    _addTag(tag);
                  }
                },
              );
            }),
            ..._tags.where((t) => !widget.suggestedTags.contains(t)).map((tag) {
              return Chip(
                label: Text(tag),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => _removeTag(tag),
                backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                labelStyle: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.transparent),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 10),
        if (!_showInput)
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showInput = true;
              });
            },
            icon: const Icon(Icons.add, size: 18),
            label: Text('Add Custom '),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              alignment: Alignment.centerLeft,
            ),
          )
        else
          TextFormField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: widget.hint,
              suffixIcon: IconButton(
                icon: const Icon(Icons.add_circle),
                onPressed: () {
                  _addTag(_controller.text);
                  _controller.clear();
                },
              ),
            ),
            onChanged: (val) {
              if (val.endsWith(' ')) {
                _addTag(val.trim());
                _controller.clear();
              }
            },
            onFieldSubmitted: (val) {
              _addTag(val);
              _controller.clear();
            },
          ),
      ],
    );
  }
}
