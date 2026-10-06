import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class CategoryProvider extends ChangeNotifier {
  List<Category> _categories = [];
  bool _isLoading = false;

  CategoryProvider() {
    fetchCategories();
  }

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;

  Future<void> fetchCategories([String? storeId]) async {
    _isLoading = true;
    notifyListeners();

    try {
      final endpoint = storeId != null ? '/admin/categories?storeId=$storeId&take=1000' : '/admin/categories?take=1000';
      final response = await ApiService.get(endpoint);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> items = [];
        if (data is Map && data.containsKey('data')) {
           items = data['data'] is List ? data['data'] : data['data']['items'] ?? [];
        } else if (data is List) {
           items = data;
        }
        
        _categories = items.map((e) => Category.fromMap(e)).toList();
      } else {
        debugPrint('Failed to fetch categories. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
