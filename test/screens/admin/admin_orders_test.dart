import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aurazone_admin/screens/admin/admin_orders.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUp(() {
    setupMockApiService();
  });

  testWidgets('AdminOrders renders correctly and shows list', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetWithProviders(const AdminOrders()));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    // Verify title
    expect(find.text('Orders'), findsOneWidget);

    // Verify the mock order from our provider
    expect(find.text('ORD-123'), findsOneWidget);
    
    // Tap on the order to expand or view details (if applicable)
    await tester.tap(find.text('ORD-123'));
    await tester.pumpAndSettle();
  });
}
