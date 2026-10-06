import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aurazone_admin/screens/admin/admin_inventory.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUp(() {
    setupMockApiService();
  });

  testWidgets('AdminInventory renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetWithProviders(const AdminInventory()));
    await tester.pumpAndSettle();

    expect(find.text('Inventory'), findsOneWidget);
    
    // Test product is visible
    expect(find.text('Test Product'), findsOneWidget);
  });
}
