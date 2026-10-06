import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aurazone_admin/screens/admin/admin_products.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUp(() {
    setupMockApiService();
  });

  testWidgets('AdminProducts renders correctly and searches', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetWithProviders(const AdminProducts()));
    await tester.pumpAndSettle();

    // The screen title should be visible
    expect(find.text('Products'), findsOneWidget);

    // The mock product should be visible
    expect(find.text('Test Product'), findsOneWidget);

    // Tap search icon to open search sheet
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();

    // Enter a search query
    await tester.enterText(find.byType(TextField).first, 'Nonexistent');
    await tester.pumpAndSettle();

    // Mock product should not be visible
    expect(find.text('Test Product'), findsNothing);

    // Enter matching search query
    await tester.enterText(find.byType(TextField).first, 'Test');
    await tester.pumpAndSettle();
    expect(find.text('Test Product'), findsOneWidget);
  });
}
