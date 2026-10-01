import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class StoreProvider extends ChangeNotifier {
  List<Store> _stores = [];
  bool _isLoading = false;

  StoreProvider() {
    fetchStores();
  }

  List<Store> get stores => _stores;
  bool get isLoading => _isLoading;

  Future<void> fetchStores() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.get('/admin/stores');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> items = [];
        if (data is Map && data.containsKey('data')) {
           items = data['data'] is List ? data['data'] : data['data']['items'] ?? [];
        } else if (data is List) {
           items = data;
        }
        
        _stores = items.map((e) => Store.fromMap(e)).toList();
      } else {
        debugPrint('Failed to fetch stores. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching stores: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
