import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aurazone_admin/screens/admin/admin_dashboard.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUp(() {
    setupMockApiService();
  });

  testWidgets('AdminDashboard renders stats and recent orders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetWithProviders(const AdminDashboard()));
    await tester.pumpAndSettle(); // Initial frame
    await tester.pump(const Duration(milliseconds: 100)); // Wait for data fetching
    await tester.pumpAndSettle(); // Settle after fetch
    // Check header
    expect(find.text('Overview'), findsOneWidget);
    
    // Check if stats are rendered
    expect(find.text('Total Revenue'), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Low Stock'), findsOneWidget);
    expect(find.text('Out of Stock'), findsOneWidget);

    // Scroll to see recent orders
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    // Check if the mock order is rendered in recent orders
    expect(find.text('Recent Orders'), findsOneWidget);
    expect(find.text('ORD-123'), findsOneWidget);
  });
}
