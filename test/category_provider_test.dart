import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aurazone_admin/providers/category_provider.dart';
import 'package:aurazone_admin/services/api_service.dart';

void main() {
  group('CategoryProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initial state and successful fetch', () async {
      ApiService.client = MockClient((request) async {
        return http.Response(jsonEncode({
          'data': {
            'items': [
              {
                'id': 'cat1',
                'name': 'Electronics',
                'description': 'Devices',
                'storeId': 'store1',
                'createdAt': DateTime.now().toIso8601String(),
                'updatedAt': DateTime.now().toIso8601String(),
              }
            ]
          }
        }), 200);
      });

      final provider = CategoryProvider();
      expect(provider.isLoading, true);
      expect(provider.categories, isEmpty);

      // wait for fetchCategories to complete
      await Future.delayed(Duration.zero);

      expect(provider.isLoading, false);
      expect(provider.categories.length, 1);
      expect(provider.categories.first.id, 'cat1');
      expect(provider.categories.first.name, 'Electronics');
    });

    test('handles API error without crashing', () async {
      ApiService.client = MockClient((request) async {
        return http.Response('Error', 500);
      });

      final provider = CategoryProvider();
      
      await Future.delayed(Duration.zero);

      expect(provider.isLoading, false);
      expect(provider.categories, isEmpty);
    });

    test('fetches for specific store', () async {
      ApiService.client = MockClient((request) async {
        expect(request.url.queryParameters['storeId'], 'store1');
        return http.Response(jsonEncode({'data': {'items': []}}), 200);
      });

      final provider = CategoryProvider();
      await provider.fetchCategories('store1');
      expect(provider.isLoading, false);
    });
  });
}
