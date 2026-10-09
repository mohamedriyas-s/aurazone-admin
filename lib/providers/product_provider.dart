import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedGender = 'All';

  List<Product> get products {
    var filtered = List<Product>.from(_products);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((p) =>
              p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.description.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_selectedCategory != 'All') {
      filtered =
          filtered.where((p) => p.category == _selectedCategory).toList();
    }

    if (_selectedGender != 'All') {
      filtered = filtered.where((p) => p.gender == _selectedGender.toLowerCase()).toList();
    }

    return filtered;
  }

  List<Product> get allProducts => List.unmodifiable(_products);
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedGender => _selectedGender;

  int get totalProducts => _products.length;
  int get activeProducts => _products.where((p) => p.isActive).length;
  int get lowStockProducts => _products.where((p) => p.isLowStock).length;
  int get outOfStockProducts => _products.where((p) => p.isOutOfStock).length;



  static const List<String> genders = [
    'All', 'Men', 'Women', 'Unisex', 'Kids'
  ];
  static const List<String> availableSizes = [
    'UK 5', 'UK 6', 'UK 7', 'UK 8', 'UK 9', 'UK 10', 'UK 11', 'UK 12', 'S', 'M', 'L', 'XL', 'XXL'
  ];
  static const List<String> availableColors = [
    'Black', 'White', 'Red', 'Blue', 'Green', 'Grey', 'Brown', 'Navy',
    'Beige', 'Orange', 'Pink', 'Multi'
  ];

  ProductProvider() {
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('/admin/products?take=1000');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> items = [];
        if (data is Map && data.containsKey('data')) {
           items = data['data'] is List ? data['data'] : data['data']['items'] ?? [];
        } else if (data is List) {
           items = data;
        }
        
        List<Product> parsedProducts = [];
        for (var e in items) {
          try {
            parsedProducts.add(Product.fromMap(e, e['id'] ?? ''));
          } catch (err, stack) {
            debugPrint('Error parsing product ${e["id"]}: $err\n$stack');
          }
        }
        _products = parsedProducts;
        debugPrint('Successfully loaded ${_products.length} products.');
      } else {
        debugPrint('Failed to load products: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stack) {
      debugPrint('Error fetching products: $e\n$stack');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setGender(String gender) {
    _selectedGender = gender;
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    try {
      final response = await ApiService.post('/admin/products', product.toMap());
      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchProducts(); // Refresh list
      } else {
        String errMsg = 'Failed to add product';
        try {
          final body = json.decode(response.body);
          if (body['message'] != null) {
            errMsg = body['message'];
          }
        } catch (_) {}
        throw errMsg;
      }
    } catch (e) {
      debugPrint('Error adding product: $e');
      rethrow;
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      final response = await ApiService.put('/admin/products/${product.id}', product.toMap());
      if (response.statusCode == 200) {
        await fetchProducts();
      } else {
        String errMsg = 'Failed to update product';
        try {
          final body = json.decode(response.body);
          if (body['message'] != null) {
            errMsg = body['message'];
          }
        } catch (_) {}
        throw errMsg;
      }
    } catch (e) {
      debugPrint('Error updating product: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      final response = await ApiService.delete('/admin/products/$productId');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _products.removeWhere((p) => p.id == productId);
        notifyListeners();
      } else {
        String errMsg = 'Failed to delete product';
        try {
          final body = json.decode(response.body);
          if (body['message'] != null) {
            errMsg = body['message'];
          }
        } catch (_) {}
        throw errMsg;
      }
    } catch (e) {
      debugPrint('Error deleting product: $e');
      rethrow;
    }
  }

  Future<void> toggleProductActive(String productId) async {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final product = _products[index];
      final newStatus = !product.isActive;
      try {
        final updateMap = product.toMap();
        updateMap['isActive'] = newStatus;
        final response = await ApiService.put('/admin/products/$productId', updateMap);
        if (response.statusCode == 200) {
          await fetchProducts();
        }
      } catch (e) {
        debugPrint('Error toggling product active status: $e');
      }
    }
  }

  Future<void> updateStock(String productId, int newQuantity) async {
    final product = getProductById(productId);
    if (product == null) {
      debugPrint('updateStock: Product not found.');
      return;
    }

    if (product.variants.isEmpty) {
      debugPrint('updateStock: Cannot update stock for product without variants.');
      return;
    }

    int totalVariants = product.variants.length;
    int stockPerVariant = totalVariants > 0 ? newQuantity ~/ totalVariants : 0;
    int remainder = totalVariants > 0 ? newQuantity % totalVariants : 0;

    List<ProductVariant> updatedVariants = [];
    for (int i = 0; i < product.variants.length; i++) {
      int variantQuantity = stockPerVariant + (i < remainder ? 1 : 0);
      updatedVariants.add(product.variants[i].copyWith(quantity: variantQuantity));
    }

    final updatedProduct = product.copyWith(variants: updatedVariants);

    try {
      await updateProduct(updatedProduct);
      debugPrint('Successfully updated stock for product $productId');
    } catch (e) {
      debugPrint('Error updating stock: $e');
    }
  }

  Product? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
