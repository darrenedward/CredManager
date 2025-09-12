import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:cred_manager/main.dart';
import 'package:cred_manager/models/auth_state.dart';
import 'package:cred_manager/models/dashboard_state.dart';
import 'package:cred_manager/services/theme_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('complete user flow', (tester) async {
      // Start the app
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (context) => ThemeService()),
            ChangeNotifierProvider(create: (context) => AuthState()),
            ChangeNotifierProxyProvider<AuthState, DashboardState>(
              create: (context) => DashboardState(
                Provider.of<AuthState>(context, listen: false).credentialStorage,
              ),
              update: (context, authState, dashboardState) {
                // Update dashboard state when auth state changes
                if (authState.hasValidSession) {
                  // User logged in - ensure dashboard has access to credential storage
                  return dashboardState ?? DashboardState(authState.credentialStorage);
                } else {
                  // User logged out - return new dashboard state
                  return DashboardState(authState.credentialStorage);
                }
              },
            ),
          ],
          child: const ApiKeyManagerApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify we're on the login screen
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Enter your passphrase to continue'), findsOneWidget);

      // Test form validation - empty passphrase
      final loginButton = find.text('Login');
      await tester.tap(loginButton);
      await tester.pump();

      // Should show validation error
      expect(find.textContaining('required'), findsOneWidget);

      // Test with short passphrase
      final passphraseField = find.byType(TextField);
      await tester.enterText(passphraseField, '123');
      await tester.tap(loginButton);
      await tester.pump();

      // Should show length validation error
      expect(find.textContaining('at least'), findsOneWidget);

      print('✅ Basic validation tests passed');
    });

    testWidgets('navigation flow', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (context) => ThemeService()),
            ChangeNotifierProvider(create: (context) => AuthState()),
            ChangeNotifierProxyProvider<AuthState, DashboardState>(
              create: (context) => DashboardState(
                Provider.of<AuthState>(context, listen: false).credentialStorage,
              ),
              update: (context, authState, dashboardState) {
                // Update dashboard state when auth state changes
                if (authState.hasValidSession) {
                  // User logged in - ensure dashboard has access to credential storage
                  return dashboardState ?? DashboardState(authState.credentialStorage);
                } else {
                  // User logged out - return new dashboard state
                  return DashboardState(authState.credentialStorage);
                }
              },
            ),
          ],
          child: const ApiKeyManagerApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Test navigation elements are present
      expect(find.text('Forgot Passphrase?'), findsOneWidget);

      print('✅ Navigation elements present');
    });
  });
}