import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aurazone_admin/screens/user/user_shell.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUp(() {
    setupMockApiService();
  });

  testWidgets('UserShell renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetWithProviders(const UserShell()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back,'), findsOneWidget);
    
    // We expect the mock product to be listed
    expect(find.text('Test Product'), findsWidgets);
    
    // Test categories
    expect(find.text('Fashion'), findsWidgets);
  });
}
