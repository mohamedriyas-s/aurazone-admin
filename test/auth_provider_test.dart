import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aurazone_admin/providers/auth_provider.dart';
import 'package:aurazone_admin/models/models.dart';

void main() {
  group('AuthProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initial state is not logged in', () {
      final auth = AuthProvider();
      expect(auth.isLoggedIn, false);
      expect(auth.isAdmin, false);
      expect(auth.currentUser, null);
      expect(auth.isLoading, false);
      expect(auth.error, null);
    });

    test('clearError sets error to null', () {
      final auth = AuthProvider();
      auth.clearError();
      expect(auth.error, null);
    });

    test('logout clears all state and tokens', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'test_access_token',
        'refresh_token': 'test_refresh_token',
      });

      final auth = AuthProvider();
      await auth.logout();

      expect(auth.isLoggedIn, false);
      expect(auth.currentUser, null);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), null);
      expect(prefs.getString('refresh_token'), null);
    });

    test('initialize without token stays logged out', () async {
      SharedPreferences.setMockInitialValues({});
      final auth = AuthProvider();
      await auth.initialize();
      expect(auth.isLoggedIn, false);
      expect(auth.isLoading, false);
    });
  });
}
