import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class ApiService {
  static http.Client client = http.Client();

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<bool> _refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');
    if (refreshToken == null) return false;

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/auth/refresh');
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final newAccessToken = body['data']['accessToken'];
        final newRefreshToken = body['data']['refreshToken'];
        
        await prefs.setString('auth_token', newAccessToken);
        if (newRefreshToken != null) {
          await prefs.setString('refresh_token', newRefreshToken);
        }
        return true;
      }
    } catch (_) {}
    
    return false;
  }

  static void Function()? onUnauthorized;

  static Future<http.Response> _handleResponse(http.Response response, Future<http.Response> Function() retry) async {
    // If we get a 401 Unauthorized, try to refresh the token and retry the request
    if (response.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        return await retry();
      } else {
        onUnauthorized?.call();
      }
    } else if (response.statusCode == 403) {
      onUnauthorized?.call();
    }
    return response;
  }

  static Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final response = await client.get(url, headers: await _getHeaders());
    return _handleResponse(response, () async => await client.get(url, headers: await _getHeaders()));
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final response = await client.post(url, headers: await _getHeaders(), body: jsonEncode(body));
    return _handleResponse(response, () async => await client.post(url, headers: await _getHeaders(), body: jsonEncode(body)));
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final response = await client.put(url, headers: await _getHeaders(), body: jsonEncode(body));
    return _handleResponse(response, () async => await client.put(url, headers: await _getHeaders(), body: jsonEncode(body)));
  }

  static Future<http.Response> delete(String endpoint) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final response = await client.delete(url, headers: await _getHeaders());
    return _handleResponse(response, () async => await client.delete(url, headers: await _getHeaders()));
  }
}
