import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aurazone_admin/providers/order_provider.dart';
import 'package:aurazone_admin/models/models.dart';
import 'package:aurazone_admin/services/api_service.dart';

void main() {
  group('OrderProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initial state and successful fetch', () async {
      ApiService.client = MockClient((request) async {
        return http.Response(jsonEncode({
          'data': {
            'items': [
              {
                'id': 'order1',
                'status': 'PENDING',
                'totalAmount': 100.0,
                'createdAt': DateTime.now().toIso8601String(),
                'updatedAt': DateTime.now().toIso8601String(),
              }
            ]
          }
        }), 200);
      });

      final provider = OrderProvider();
      expect(provider.isLoading, true);
      expect(provider.allOrders, isEmpty);

      // Wait for fetchOrders to complete
      await Future.delayed(Duration.zero);

      expect(provider.isLoading, false);
      expect(provider.allOrders.length, 1);
      expect(provider.totalOrders, 1);
      expect(provider.pendingOrders, 1);
      expect(provider.totalRevenue, 100.0);
      
      provider.dispose(); // clean up timer
    });

    test('filtering orders by status', () async {
      ApiService.client = MockClient((request) async {
        return http.Response(jsonEncode({
          'data': {
            'items': [
              {
                'id': 'o1',
                'status': 'PENDING',
                'totalAmount': 50.0,
              },
              {
                'id': 'o2',
                'status': 'DELIVERED',
                'totalAmount': 150.0,
              }
            ]
          }
        }), 200);
      });

      final provider = OrderProvider();
      await Future.delayed(Duration.zero);

      expect(provider.orders.length, 2); // All
      
      provider.setStatusFilter('Pending');
      expect(provider.orders.length, 1);
      expect(provider.orders.first.id, 'o1');
      
      provider.setStatusFilter('Delivered');
      expect(provider.orders.length, 1);
      expect(provider.orders.first.id, 'o2');

      provider.dispose();
    });

    test('updateOrderStatus updates local state', () async {
      ApiService.client = MockClient((request) => Future.value(http.Response('{"data": {"items": [{"id":"o1", "status":"PENDING"}]}}', 200)));
      
      final provider = OrderProvider();
      await Future.delayed(Duration.zero);
      
      provider.updateOrderStatus('o1', OrderStatus.shipped);
      expect(provider.getOrderById('o1')?.status, OrderStatus.shipped);
      
      provider.dispose();
    });
  });
}
