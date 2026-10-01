import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _currentUser;
  bool _isLoading = false;
  String? _error;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  String? get error => _error;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token != null) {
        // We can fetch user details with GET /auth/me
        final response = await ApiService.get('/auth/me');
        if (response.statusCode == 200) {
          final data = json.decode(response.body)['data']['user'];
          
          UserRole role = UserRole.user;
          if (data['role'] == 'SUPER_ADMIN' || data['role'] == 'STORE_MANAGER') {
             role = UserRole.admin;
          }

          _currentUser = AppUser(
            id: data['id'],
            email: data['email'],
            name: data['fullName'] ?? '',
            role: role,
          );
        } else {
          // Token might be invalid
          await prefs.remove('auth_token');
          await prefs.remove('refresh_token');
        }
      }
    } catch (e) {
      debugPrint('Init auth error: ');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.post('/auth/login', {
        'email': email.trim(),
        'password': password,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = json.decode(response.body);
        final data = body['data'];
        final user = data['user'];
        final token = data['accessToken'];
        final refreshToken = data['refreshToken'];

        UserRole role = UserRole.user;
        if (user['role'] == 'SUPER_ADMIN' || user['role'] == 'STORE_MANAGER') {
           role = UserRole.admin;
        }

        _currentUser = AppUser(
          id: user['id'],
          email: user['email'],
          name: user['fullName'] ?? '',
          role: role,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        if (refreshToken != null) {
          await prefs.setString('refresh_token', refreshToken);
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final body = json.decode(response.body);
        _error = body['message'] ?? 'Login failed';
      }
    } catch (e) {
      _error = 'Network error occurred';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    try {
      await ApiService.post('/auth/logout', {});
    } catch (_) {}
    
    _currentUser = null;
    _error = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('refresh_token');
    } catch (_) {}

    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
