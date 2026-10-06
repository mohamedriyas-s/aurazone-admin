import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aurazone_admin/providers/product_provider.dart';
import 'package:aurazone_admin/models/models.dart';
import 'package:aurazone_admin/services/api_service.dart';

void main() {
  group('ProductProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initial state and successful fetch', () async {
      ApiService.client = MockClient((request) async {
        return http.Response(jsonEncode({
          'data': {
            'items': [
              {
                'id': 'p1',
                'name': 'Test Product',
                'description': 'Description',
                'isActive': true,
                'categoryId': 'Fashion',
                'gender': 'men',
              }
            ]
          }
        }), 200);
      });

      final provider = ProductProvider();
      expect(provider.isLoading, true);
      expect(provider.allProducts, isEmpty);

      // Wait for fetchProducts to complete
      await Future.delayed(Duration.zero);

      expect(provider.isLoading, false);
      expect(provider.allProducts.length, 1);
      expect(provider.totalProducts, 1);
      expect(provider.activeProducts, 1);
    });

    test('filtering products by search query, category, and gender', () async {
      ApiService.client = MockClient((request) async {
        return http.Response(jsonEncode({
          'data': {
            'items': [
              {
                'id': 'p1',
                'name': 'Nike Shoes',
                'description': 'Running shoes',
                'categoryId': 'Fashion',
                'gender': 'men',
              },
              {
                'id': 'p2',
                'name': 'Adidas Shirt',
                'description': 'Sports shirt',
                'categoryId': 'Sports',
                'gender': 'women',
              }
            ]
          }
        }), 200);
      });

      final provider = ProductProvider();
      await Future.delayed(Duration.zero);

      expect(provider.products.length, 2);
      
      // Test search
      provider.setSearchQuery('nike');
      expect(provider.products.length, 1);
      expect(provider.products.first.id, 'p1');
      provider.setSearchQuery('');
      
      // Test category filter
      provider.setCategory('Sports');
      expect(provider.products.length, 1);
      expect(provider.products.first.id, 'p2');
      provider.setCategory('All');
      
      // Test gender filter
      provider.setGender('Women');
      expect(provider.products.length, 1);
      expect(provider.products.first.id, 'p2');
    });

    test('deleteProduct removes product on success', () async {
      int requestCount = 0;
      ApiService.client = MockClient((request) async {
        if (requestCount == 0) {
          requestCount++;
          return http.Response(jsonEncode({
            'data': {'items': [{'id': 'p1', 'name': 'P1'}]}
          }), 200);
        } else {
          return http.Response('', 204); // Success delete
        }
      });

      final provider = ProductProvider();
      await Future.delayed(Duration.zero);
      expect(provider.allProducts.length, 1);

      await provider.deleteProduct('p1');
      expect(provider.allProducts.length, 0);
    });
  });
}
