import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aurazone_admin/providers/auth_provider.dart';
import 'package:aurazone_admin/providers/product_provider.dart';
import 'package:aurazone_admin/providers/order_provider.dart';
import 'package:aurazone_admin/providers/category_provider.dart';
import 'package:aurazone_admin/providers/store_provider.dart';
import 'package:aurazone_admin/services/api_service.dart';
import 'package:aurazone_admin/models/models.dart';

Widget createWidgetWithProviders(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()), // Assuming initialize sets it up
      ChangeNotifierProvider(create: (_) => ProductProvider()),
      ChangeNotifierProvider(create: (_) => OrderProvider(enablePolling: false)),
      ChangeNotifierProvider(create: (_) => CategoryProvider()),
      ChangeNotifierProvider(create: (_) => StoreProvider()),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void setupMockApiService() {
  SharedPreferences.setMockInitialValues({'auth_token': 'test_token'});
  
  ApiService.client = MockClient((request) async {
    final path = request.url.path;
    
    if (path.contains('/admin/products')) {
      return http.Response(jsonEncode({
        'data': {
          'items': [
            {
              'id': 'p1',
              'name': 'Test Product',
              'description': 'Desc',
              'isActive': true,
              'categoryId': 'Fashion',
              'gender': 'men',
              'variants': [
                {
                  'sku': 'SKU-1',
                  'price': 100,
                  'quantity': 10,
                  'isAvailable': true,
                  'attributes': [
                    {'key': 'Size', 'value': 'M'},
                    {'key': 'Color', 'value': 'Blue'}
                  ]
                }
              ]
            }
          ]
        }
      }), 200);
    } else if (path.contains('/admin/orders')) {
      return http.Response(jsonEncode({
        'data': {
          'items': [
            {
              'id': 'ORD-123',
              'totalAmount': 500,
              'status': 'PENDING',
              'items': [
                {
                  'productName': 'Test Product',
                  'imageUrl': 'https://example.com/img.jpg',
                  'price': 500,
                  'quantity': 1,
                }
              ]
            }
          ]
        }
      }), 200);
    } else if (path.contains('/admin/categories')) {
      return http.Response(jsonEncode({'data': {'items': []}}), 200);
    } else if (path.contains('/admin/stores')) {
      return http.Response(jsonEncode({'data': {'items': []}}), 200);
    } else if (path.contains('/auth/login')) {
      return http.Response(jsonEncode({
        'data': {
          'accessToken': 'test_token',
          'user': {'id': '1', 'name': 'Admin', 'email': 'admin@test.com', 'role': 'admin'}
        }
      }), 200);
    }
    
    return http.Response('{}', 200);
  });
}
