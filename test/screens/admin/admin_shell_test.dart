import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aurazone_admin/screens/admin/admin_shell.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUp(() {
    setupMockApiService();
  });

  testWidgets('AdminShell renders and handles navigation', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetWithProviders(const AdminShell()));
    await tester.pumpAndSettle();

    // Check if bottom navigation has all 4 tabs
    expect(find.byIcon(Icons.dashboard_rounded), findsAtLeastNWidgets(1));
    expect(find.byIcon(Icons.shopping_bag_rounded), findsAtLeastNWidgets(1));
    expect(find.byIcon(Icons.receipt_long_rounded), findsAtLeastNWidgets(1));
    expect(find.byIcon(Icons.inventory_2_rounded), findsAtLeastNWidgets(1));

    // Initial tab should be Dashboard
    expect(find.text('Overview'), findsOneWidget);

    // Tap on Products tab
    await tester.tap(find.byIcon(Icons.shopping_bag_rounded).last);
    await tester.pumpAndSettle();

    // Now Products view should be visible
    expect(find.text('Products'), findsWidgets); // Can be title and tab label
  });
}
