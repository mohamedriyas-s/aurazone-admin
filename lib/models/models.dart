import 'package:uuid/uuid.dart';

enum UserRole { admin, user }

class AppUser {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? avatarUrl;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.avatarUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isAdmin => role == UserRole.admin;
}

class Store {
  final String id;
  final String name;
  final String slug;
  final bool isActive;

  Store({required this.id, required this.name, required this.slug, this.isActive = true});

  factory Store.fromMap(Map<String, dynamic> map) {
    return Store(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      slug: map['slug'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }
}

class Category {
  final String id;
  final String name;
  final String storeId;
  final String slug;

  Category({required this.id, required this.name, required this.storeId, required this.slug});

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      storeId: map['storeId'] ?? '',
      slug: map['slug'] ?? '',
    );
  }
}

class ProductVariantAttribute {
  final String key;
  final String value;

  ProductVariantAttribute({required this.key, required this.value});

  Map<String, dynamic> toMap() => {'key': key, 'value': value};

  factory ProductVariantAttribute.fromMap(Map<String, dynamic> map) {
    return ProductVariantAttribute(
      key: map['key'] ?? '',
      value: map['value'] ?? '',
    );
  }
}

class ProductVariant {
  final String? id;
  final String sku;
  final double price;
  final double? compareAtPrice;
  final bool isAvailable;
  final int quantity;
  final List<ProductVariantAttribute> attributes;
  final List<String> imageUrls;

  ProductVariant({
    this.id,
    required this.sku,
    required this.price,
    this.compareAtPrice,
    this.isAvailable = true,
    this.quantity = 0,
    required this.attributes,
    this.imageUrls = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'sku': sku,
      'price': price,
      if (compareAtPrice != null) 'compareAtPrice': compareAtPrice,
      'isAvailable': isAvailable,
      'quantity': quantity,
      'attributes': attributes.map((x) => x.toMap()).toList(),
      'imageUrls': imageUrls,
    };
  }

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      id: map['id'],
      sku: map['sku'] ?? '',
      price: map['price'] != null ? (double.tryParse(map['price'].toString()) ?? 0.0) : 0.0,
      compareAtPrice: map['compareAtPrice'] != null ? double.tryParse(map['compareAtPrice'].toString()) : null,
      isAvailable: map['isAvailable'] ?? true,
      quantity: (map['inventory'] is Map && map['inventory']['quantity'] != null)
          ? map['inventory']['quantity']
          : (map['quantity'] ?? 0),
      attributes: (map['attributes'] as List<dynamic>?)
              ?.map((x) => ProductVariantAttribute.fromMap(x))
              .toList() ??
          [],
      imageUrls: (map['images'] as List<dynamic>?)?.map((x) => x['url'].toString()).toList() ?? 
                 (map['imageUrls'] as List<dynamic>?)?.map((x) => x.toString()).toList() ?? [],
    );
  }
}

class Product {
  final String id;
  final String storeId;
  final String categoryId;
  final String name;
  final String? brand;
  final String? modelNumber;
  final String gender;
  final String description;
  final String shortDescription;
  final List<String> tags;
  final bool hasVariants;
  final bool isActive;
  final bool isFeatured;
  final List<ProductVariant> variants;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Flattened helpers for UI compatibility
  double get price => variants.isNotEmpty ? variants.first.price : 0.0;
  double? get originalPrice => variants.isNotEmpty ? variants.first.compareAtPrice : null;
  double? get discountPercentage => originalPrice != null && originalPrice! > price ? ((originalPrice! - price) / originalPrice!) * 100 : null;
  String get category => categoryId;
  int get stockQuantity => variants.fold(0, (sum, v) => sum + v.quantity);
  bool get isLowStock => stockQuantity > 0 && stockQuantity <= 5;
  bool get isOutOfStock => stockQuantity <= 0;
  List<String> get imageUrls => variants.isNotEmpty ? variants.first.imageUrls : [];
  
  List<String> get sizes {
    final s = <String>{};
    for (var v in variants) {
      for (var a in v.attributes) {
        if (a.key.toLowerCase() == 'size') s.add(a.value);
      }
    }
    return s.toList();
  }
  
  List<String> get colors {
    final c = <String>{};
    for (var v in variants) {
      for (var a in v.attributes) {
        if (a.key.toLowerCase() == 'color') c.add(a.value);
      }
    }
    return c.toList();
  }

  Product({
    String? id,
    required this.storeId,
    required this.categoryId,
    required this.name,
    this.brand,
    this.modelNumber,
    required this.gender,
    required this.description,
    this.shortDescription = '',
    this.tags = const [],
    this.hasVariants = true,
    this.isActive = true,
    this.isFeatured = false,
    required this.variants,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'storeId': storeId,
      'categoryId': categoryId,
      'name': name,
      if (brand != null && brand!.isNotEmpty) 'brand': brand,
      if (modelNumber != null && modelNumber!.isNotEmpty) 'modelNumber': modelNumber,
      if (gender != 'Not Specified' && gender.isNotEmpty) 'gender': gender.toUpperCase(),
      'description': description,
      if (shortDescription.isNotEmpty) 'shortDescription': shortDescription,
      'tags': tags,
      'hasVariants': hasVariants,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'variants': variants.map((x) => x.toMap()).toList(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, String docId) {
    return Product(
      id: map['id'] ?? docId,
      storeId: map['storeId'] ?? '',
      categoryId: map['categoryId'] ?? '',
      name: map['name'] ?? '',
      brand: map['brand'],
      modelNumber: map['modelNumber'],
      gender: map['gender'] != null ? map['gender'].toString().toLowerCase() : 'Not Specified',
      description: map['description'] ?? '',
      shortDescription: map['shortDescription'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      hasVariants: map['hasVariants'] ?? true,
      isActive: map['isActive'] ?? true,
      isFeatured: map['isFeatured'] ?? false,
      variants: (map['variants'] as List<dynamic>?)
              ?.map((x) => ProductVariant.fromMap(x))
              .toList() ??
          [],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }
}

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled,
  refunded,
}

class OrderItem {
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;
  final String size;
  final String color;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
    required this.size,
    required this.color,
  });

  double get total => price * quantity;
}

class Order {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final List<OrderItem> items;
  final double subtotal;
  final double shippingCost;
  final double tax;
  final double total;
  final OrderStatus status;
  final String shippingAddress;
  final String? trackingNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    String? id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.items,
    required this.subtotal,
    this.shippingCost = 0,
    this.tax = 0,
    required this.total,
    this.status = OrderStatus.pending,
    required this.shippingAddress,
    this.trackingNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? 'ORD-${const Uuid().v4().substring(0, 8).toUpperCase()}',
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Order copyWith({OrderStatus? status, String? trackingNumber}) {
    return Order(
      id: id,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      items: items,
      subtotal: subtotal,
      shippingCost: shippingCost,
      tax: tax,
      total: total,
      status: status ?? this.status,
      shippingAddress: shippingAddress,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
