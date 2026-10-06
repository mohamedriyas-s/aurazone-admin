import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aurazone_admin/services/api_service.dart';
import 'package:aurazone_admin/config.dart';

void main() {
  group('ApiService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('get appends authorization header if token exists', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'my_token'});

      ApiService.client = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer my_token');
        expect(request.headers['Content-Type'], 'application/json');
        return http.Response(jsonEncode({'success': true}), 200);
      });

      final response = await ApiService.get('/test');
      expect(response.statusCode, 200);
    });

    test('post sends JSON body correctly', () async {
      ApiService.client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.body, '{"name":"test"}');
        return http.Response(jsonEncode({'success': true}), 201);
      });

      final response = await ApiService.post('/test', {'name': 'test'});
      expect(response.statusCode, 201);
    });

    test('token refresh logic on 401', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'expired_token',
        'refresh_token': 'valid_refresh',
      });

      int attempt = 0;
      ApiService.client = MockClient((request) async {
        if (request.url.path.endsWith('/auth/refresh')) {
          // Mock token refresh response
          return http.Response(jsonEncode({
            'data': {
              'accessToken': 'new_token',
              'refreshToken': 'new_refresh'
            }
          }), 200);
        }

        if (attempt == 0) {
          attempt++;
          // First attempt returns 401
          return http.Response('Unauthorized', 401);
        } else {
          // Second attempt should have the new token
          expect(request.headers['Authorization'], 'Bearer new_token');
          return http.Response(jsonEncode({'success': true}), 200);
        }
      });

      final response = await ApiService.get('/protected');
      expect(response.statusCode, 200);
      
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), 'new_token');
      expect(prefs.getString('refresh_token'), 'new_refresh');
    });
  });
}
