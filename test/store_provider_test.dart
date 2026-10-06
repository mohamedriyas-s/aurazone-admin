import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aurazone_admin/providers/store_provider.dart';
import 'package:aurazone_admin/services/api_service.dart';

void main() {
  group('StoreProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initial state and successful fetch', () async {
      ApiService.client = MockClient((request) async {
        return http.Response(jsonEncode({
          'data': {
            'items': [
              {
                'id': 'store1',
                'name': 'Test Store',
                'description': 'Description',
                'contactEmail': 'store@test.com',
                'contactPhone': '1234567890',
                'status': 'ACTIVE',
                'createdAt': DateTime.now().toIso8601String(),
                'updatedAt': DateTime.now().toIso8601String(),
              }
            ]
          }
        }), 200);
      });

      final provider = StoreProvider();
      expect(provider.isLoading, true);
      expect(provider.stores, isEmpty);

      // wait for fetchStores to complete
      await Future.delayed(Duration.zero);

      expect(provider.isLoading, false);
      expect(provider.stores.length, 1);
      expect(provider.stores.first.id, 'store1');
      expect(provider.stores.first.name, 'Test Store');
    });

    test('handles API error without crashing', () async {
      ApiService.client = MockClient((request) async {
        return http.Response('Error', 500);
      });

      final provider = StoreProvider();
      
      await Future.delayed(Duration.zero);

      expect(provider.isLoading, false);
      expect(provider.stores, isEmpty);
    });
  });
}
