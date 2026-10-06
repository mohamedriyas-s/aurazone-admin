import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class OrderProvider extends ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = false;
  String _selectedStatus = 'All';

  List<Order> get orders {
    if (_selectedStatus == 'All') return List.unmodifiable(_orders);
    final status = OrderStatus.values.firstWhere(
      (s) => s.name == _selectedStatus.toLowerCase(),
      orElse: () => OrderStatus.pending,
    );
    return _orders.where((o) => o.status == status).toList();
  }

  List<Order> get allOrders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  String get selectedStatus => _selectedStatus;

  int get totalOrders => _orders.length;
  double get totalRevenue => _orders
      .where((o) => o.status != OrderStatus.cancelled && o.status != OrderStatus.refunded)
      .fold(0.0, (sum, o) => sum + o.total);
  int get pendingOrders => _orders.where((o) => o.status == OrderStatus.pending).length;
  int get deliveredOrders => _orders.where((o) => o.status == OrderStatus.delivered).length;

  Timer? _pollingTimer;

  OrderProvider({bool enablePolling = true}) {
    fetchOrders();
    // Poll for new orders every 15 seconds for a "real-time" feel without WebSockets
    if (enablePolling) {
      _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        fetchOrders(silent: true);
      });
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchOrders({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final response = await ApiService.get('/admin/orders?take=1000');
      if (response.statusCode == 200) {
        // Assume API returns standard paginated response { data: { items: [...] } }
        final data = json.decode(response.body);
        List<dynamic> items = [];
        if (data is Map && data.containsKey('data')) {
           items = data['data'] is List ? data['data'] : data['data']['items'] ?? [];
        } else if (data is List) {
           items = data;
        }

        List<Order> parsedOrders = [];
        for (var e in items) {
          try {
            parsedOrders.add(Order.fromMap(e));
          } catch (err, stack) {
            debugPrint('Error parsing order ${e["id"]}: $err\n$stack');
          }
        }
        _orders = parsedOrders;
      } else {
        debugPrint('Failed to load orders: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setStatusFilter(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void updateOrderStatus(String orderId, OrderStatus status) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(status: status);
      notifyListeners();
    }
  }

  void updateTrackingNumber(String orderId, String trackingNumber) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(trackingNumber: trackingNumber);
      notifyListeners();
    }
  }

  Order? getOrderById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }
}
