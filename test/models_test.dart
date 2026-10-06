import 'package:flutter_test/flutter_test.dart';
import 'package:aurazone_admin/models/models.dart';

void main() {
  // ──────────────────────────────────────────────────────────────
  // AppUser Tests
  // ──────────────────────────────────────────────────────────────
  group('AppUser', () {
    test('isAdmin returns true for admin role', () {
      final admin = AppUser(id: '1', email: 'a@b.com', name: 'Admin', role: UserRole.admin);
      expect(admin.isAdmin, true);
    });

    test('isAdmin returns false for user role', () {
      final user = AppUser(id: '2', email: 'u@b.com', name: 'User', role: UserRole.user);
      expect(user.isAdmin, false);
    });

    test('createdAt defaults to now when not provided', () {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final user = AppUser(id: '3', email: 'e@b.com', name: 'Test', role: UserRole.user);
      expect(user.createdAt.isAfter(before), true);
    });
  });

  // ──────────────────────────────────────────────────────────────
  // Store Tests
  // ──────────────────────────────────────────────────────────────
  group('Store', () {
    test('fromMap parses correctly', () {
      final store = Store.fromMap({
        'id': 'store-1',
        'name': 'Aura Electronics',
        'slug': 'aura-electronics',
        'isActive': true,
      });
      expect(store.id, 'store-1');
      expect(store.name, 'Aura Electronics');
      expect(store.slug, 'aura-electronics');
      expect(store.isActive, true);
    });

    test('fromMap handles missing fields gracefully', () {
      final store = Store.fromMap({});
      expect(store.id, '');
      expect(store.name, '');
      expect(store.isActive, true); // defaults to true
    });
  });

  // ──────────────────────────────────────────────────────────────
  // Category Tests
  // ──────────────────────────────────────────────────────────────
  group('Category', () {
    test('fromMap parses correctly', () {
      final cat = Category.fromMap({
        'id': 'cat-1',
        'name': 'Earbuds',
        'storeId': 'store-1',
        'slug': 'earbuds',
      });
      expect(cat.id, 'cat-1');
      expect(cat.name, 'Earbuds');
      expect(cat.storeId, 'store-1');
    });

    test('fromMap handles missing fields gracefully', () {
      final cat = Category.fromMap({});
      expect(cat.id, '');
      expect(cat.name, '');
      expect(cat.storeId, '');
    });
  });

  // ──────────────────────────────────────────────────────────────
  // ProductVariantAttribute Tests
  // ──────────────────────────────────────────────────────────────
  group('ProductVariantAttribute', () {
    test('toMap and fromMap are symmetric', () {
      final attr = ProductVariantAttribute(key: 'Size', value: 'XL');
      final map = attr.toMap();
      final restored = ProductVariantAttribute.fromMap(map);
      expect(restored.key, 'Size');
      expect(restored.value, 'XL');
    });
  });

  // ──────────────────────────────────────────────────────────────
  // ProductVariant Tests
  // ──────────────────────────────────────────────────────────────
  group('ProductVariant', () {
    test('toMap correctly maps imageUrls to images array of objects', () {
      final variant = ProductVariant(
        sku: 'SKU-001',
        price: 99.99,
        compareAtPrice: 129.99,
        quantity: 10,
        imageUrls: ['http://example.com/a.jpg', 'http://example.com/b.jpg'],
        attributes: [ProductVariantAttribute(key: 'Color', value: 'Red')],
      );
      final map = variant.toMap();
      expect(map['images'], isA<List>());
      expect(map['images'].length, 2);
      expect(map['images'][0]['url'], 'http://example.com/a.jpg');
      expect(map['images'][1]['url'], 'http://example.com/b.jpg');
      // Should NOT contain imageUrls key (backend expects 'images')
      expect(map.containsKey('imageUrls'), false);
    });

    test('toMap includes id only when non-null', () {
      final withId = ProductVariant(id: 'v-1', sku: 'S', price: 10, attributes: []);
      final withoutId = ProductVariant(sku: 'S', price: 10, attributes: []);
      expect(withId.toMap().containsKey('id'), true);
      expect(withoutId.toMap().containsKey('id'), false);
    });

    test('fromMap reads inventory.quantity correctly', () {
      final variant = ProductVariant.fromMap({
        'sku': 'SKU-002',
        'price': 50,
        'inventory': {'quantity': 25},
        'attributes': [],
        'images': [{'url': 'http://example.com/c.jpg'}],
      });
      expect(variant.quantity, 25);
      expect(variant.imageUrls.first, 'http://example.com/c.jpg');
    });

    test('fromMap falls back to quantity when inventory is absent', () {
      final variant = ProductVariant.fromMap({
        'sku': 'SKU-003',
        'price': 30,
        'quantity': 5,
        'attributes': [],
      });
      expect(variant.quantity, 5);
    });

    test('fromMap defaults quantity to 0 when missing', () {
      final variant = ProductVariant.fromMap({
        'sku': 'SKU-004',
        'price': 10,
        'attributes': [],
      });
      expect(variant.quantity, 0);
    });

    test('fromMap parses Decimal price strings from Prisma', () {
      final variant = ProductVariant.fromMap({
        'sku': 'SKU-005',
        'price': '199.99',
        'compareAtPrice': '299.99',
        'attributes': [],
      });
      expect(variant.price, 199.99);
      expect(variant.compareAtPrice, 299.99);
    });
  });

  // ──────────────────────────────────────────────────────────────
  // Product Tests
  // ──────────────────────────────────────────────────────────────
  group('Product', () {
    late Product product;

    setUp(() {
      product = Product.fromMap({
        'id': 'prod-1',
        'storeId': 'store-1',
        'categoryId': 'cat-1',
        'name': 'Wireless Earbuds',
        'brand': 'Aura',
        'gender': 'UNISEX',
        'description': 'Great sound',
        'tags': ['audio', 'wireless'],
        'isActive': true,
        'isFeatured': false,
        'variants': [
          {
            'id': 'v1',
            'sku': 'WE-S-Black',
            'price': 1999,
            'compareAtPrice': 2999,
            'inventory': {'quantity': 3},
            'attributes': [
              {'key': 'Size', 'value': 'S'},
              {'key': 'Color', 'value': 'Black'},
            ],
            'images': [{'url': 'http://example.com/earbuds.jpg'}],
          },
          {
            'id': 'v2',
            'sku': 'WE-M-White',
            'price': 1999,
            'inventory': {'quantity': 0},
            'attributes': [
              {'key': 'Size', 'value': 'M'},
              {'key': 'Color', 'value': 'White'},
            ],
            'images': [],
          },
        ],
        'createdAt': '2026-10-01T10:00:00Z',
      }, 'prod-1');
    });

    test('price is taken from first variant', () {
      expect(product.price, 1999);
    });

    test('originalPrice is taken from first variant compareAtPrice', () {
      expect(product.originalPrice, 2999);
    });

    test('discountPercentage is calculated correctly', () {
      // (2999-1999)/2999 * 100 ≈ 33.34
      expect(product.discountPercentage, closeTo(33.34, 0.1));
    });

    test('stockQuantity sums across all variants', () {
      // 3 + 0 = 3
      expect(product.stockQuantity, 3);
    });

    test('isLowStock is true when stock <= 5 and > 0', () {
      expect(product.isLowStock, true);
    });

    test('isOutOfStock is true when stock is 0', () {
      expect(product.isOutOfStock, false);
      // Create a product with zero stock
      final oos = Product(
        storeId: 's', categoryId: 'c', name: 'X', gender: 'MEN',
        description: '', variants: [
          ProductVariant(sku: 'x', price: 10, quantity: 0, attributes: []),
        ],
      );
      expect(oos.isOutOfStock, true);
    });

    test('sizes extracts unique sizes from all variants', () {
      expect(product.sizes, containsAll(['S', 'M']));
      expect(product.sizes.length, 2);
    });

    test('colors extracts unique colors from all variants', () {
      expect(product.colors, containsAll(['Black', 'White']));
      expect(product.colors.length, 2);
    });

    test('imageUrls come from first variant', () {
      expect(product.imageUrls.first, 'http://example.com/earbuds.jpg');
    });

    test('gender is lowercased from backend', () {
      expect(product.gender, 'unisex');
    });

    test('tags are preserved', () {
      expect(product.tags, ['audio', 'wireless']);
    });

    test('toMap produces correct structure for backend', () {
      final map = product.toMap();
      expect(map['storeId'], 'store-1');
      expect(map['categoryId'], 'cat-1');
      expect(map['name'], 'Wireless Earbuds');
      expect(map['variants'], isA<List>());
      expect(map['variants'].length, 2);
      // gender should be uppercased for the backend
      expect(map['gender'], 'UNISEX');
    });

    test('toMap omits brand/model when empty', () {
      final p = Product(
        storeId: 's', categoryId: 'c', name: 'X', gender: 'Not Specified',
        description: '', variants: [
          ProductVariant(sku: 'x', price: 10, attributes: []),
        ],
      );
      final map = p.toMap();
      expect(map.containsKey('brand'), false);
      expect(map.containsKey('modelNumber'), false);
      expect(map.containsKey('gender'), false);
    });
  });

  // ──────────────────────────────────────────────────────────────
  // OrderItem Tests
  // ──────────────────────────────────────────────────────────────
  group('OrderItem', () {
    test('fromMap extracts product name from nested variant.product', () {
      final item = OrderItem.fromMap({
        'quantity': 2,
        'price': '499.00',
        'subtotal': '998.00',
        'variant': {
          'productId': 'prod-1',
          'product': {'name': 'Cool Sneakers'},
          'images': [{'url': 'http://img.com/sneakers.jpg'}],
        },
        'attributesSnapshot': {'size': 'UK 9', 'color': 'Black'},
      });
      expect(item.productName, 'Cool Sneakers');
      expect(item.productImage, 'http://img.com/sneakers.jpg');
      expect(item.price, 499.0);
      expect(item.quantity, 2);
      expect(item.total, 998.0);
      expect(item.size, 'UK 9');
      expect(item.color, 'Black');
    });

    test('fromMap handles missing variant gracefully', () {
      final item = OrderItem.fromMap({
        'quantity': 1,
        'price': '100',
      });
      expect(item.productName, '');
      expect(item.productImage, '');
    });

    test('fromMap handles legacy flat productName/imageUrl fields', () {
      final item = OrderItem.fromMap({
        'productName': 'Legacy Product',
        'imageUrl': 'http://legacy.com/img.jpg',
        'quantity': 1,
        'price': '50',
      });
      expect(item.productName, 'Legacy Product');
      expect(item.productImage, 'http://legacy.com/img.jpg');
    });
  });

  // ──────────────────────────────────────────────────────────────
  // Order Tests
  // ──────────────────────────────────────────────────────────────
  group('Order', () {
    test('fromMap constructs shippingAddress from orderAddress', () {
      final order = Order.fromMap({
        'id': 'ord-1',
        'userId': 'u-1',
        'totalAmount': '1500.00',
        'status': 'PENDING',
        'orderAddress': {
          'addressLine1': '42 Baker Street',
          'city': 'London',
          'state': 'England',
          'postalCode': 'NW1 6XE',
        },
        'items': [],
      });
      expect(order.shippingAddress, '42 Baker Street, London, England, NW1 6XE');
    });

    test('fromMap falls back to flat shippingAddress field', () {
      final order = Order.fromMap({
        'id': 'ord-2',
        'totalAmount': 200,
        'status': 'SHIPPED',
        'shippingAddress': '123 Main St, Springfield',
        'items': [],
      });
      expect(order.shippingAddress, '123 Main St, Springfield');
    });

    test('fromMap defaults to "No Address" when nothing is provided', () {
      final order = Order.fromMap({
        'id': 'ord-3',
        'totalAmount': 100,
        'status': 'PENDING',
        'items': [],
      });
      expect(order.shippingAddress, 'No Address');
    });

    test('status mapping works for all backend values', () {
      final cases = {
        'PENDING': OrderStatus.pending,
        'RECEIVED': OrderStatus.confirmed,
        'SHIPPED': OrderStatus.shipped,
        'DELIVERED': OrderStatus.delivered,
        'SUCCESS': OrderStatus.delivered,
        'FAILED': OrderStatus.cancelled,
        'CANCELLED': OrderStatus.cancelled,
        'SOMETHING_ELSE': OrderStatus.pending,
      };
      for (final entry in cases.entries) {
        final order = Order.fromMap({
          'id': 'o', 'totalAmount': 0, 'status': entry.key, 'items': [],
        });
        expect(order.status, entry.value, reason: 'Status ${entry.key} should map to ${entry.value}');
      }
    });

    test('subtotal is calculated from items when not directly provided', () {
      final order = Order.fromMap({
        'id': 'ord-4',
        'totalAmount': 300,
        'status': 'PENDING',
        'items': [
          {'quantity': 1, 'price': '100', 'subtotal': '100'},
          {'quantity': 2, 'price': '100', 'subtotal': '200'},
        ],
      });
      expect(order.subtotal, 300.0);
    });

    test('total is parsed from totalAmount field', () {
      final order = Order.fromMap({
        'id': 'ord-5',
        'totalAmount': '1234.56',
        'status': 'PENDING',
        'items': [],
      });
      expect(order.total, 1234.56);
    });

    test('user info is extracted correctly', () {
      final order = Order.fromMap({
        'id': 'ord-6',
        'totalAmount': 0,
        'status': 'PENDING',
        'items': [],
        'user': {
          'id': 'user-1',
          'fullName': 'John Doe',
          'email': 'john@example.com',
        },
      });
      expect(order.userId, 'user-1');
      expect(order.userName, 'John Doe');
      expect(order.userEmail, 'john@example.com');
    });

    test('copyWith updates status but preserves other fields', () {
      final order = Order.fromMap({
        'id': 'ord-7',
        'totalAmount': 500,
        'status': 'PENDING',
        'items': [],
        'shippingAddress': 'Some address',
      });
      final updated = order.copyWith(status: OrderStatus.shipped, trackingNumber: 'TRACK123');
      expect(updated.status, OrderStatus.shipped);
      expect(updated.trackingNumber, 'TRACK123');
      expect(updated.total, 500.0);
      expect(updated.shippingAddress, 'Some address');
      expect(updated.id, 'ord-7');
    });

    test('createdAt and updatedAt are parsed correctly', () {
      final order = Order.fromMap({
        'id': 'ord-8',
        'totalAmount': 0,
        'status': 'PENDING',
        'items': [],
        'createdAt': '2026-10-01T10:00:00Z',
        'updatedAt': '2026-10-02T15:30:00Z',
      });
      expect(order.createdAt.year, 2026);
      expect(order.createdAt.month, 10);
      expect(order.updatedAt.day, 2);
    });
  });
}
