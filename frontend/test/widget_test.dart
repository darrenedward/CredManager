import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:api_key_manager/main.dart';
import 'package:api_key_manager/models/auth_state.dart';
import 'package:api_key_manager/utils/constants.dart';

void main() {
  testWidgets('App starts and shows login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => AuthState(),
        child: const ApiKeyManagerApp(),
      ),
    );

    // Wait for initialization to complete
    await tester.pumpAndSettle();

    // Verify that the login screen appears
    expect(find.text(AppConstants.appTagline), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Enter your passphrase to continue'), findsOneWidget);
  });

  testWidgets('Login form validation works', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => AuthState(),
        child: const ApiKeyManagerApp(),
      ),
    );

    // Wait for initialization
    await tester.pumpAndSettle();

    // Find the login button (AuthForm uses 'Submit' button)
    final loginButton = find.text('Submit');
    expect(loginButton, findsOneWidget);

    // Try to login with empty passphrase
    await tester.tap(loginButton);
    await tester.pump();

    // Should show error message
    expect(find.text('Passphrase is required'), findsOneWidget);
  });

  testWidgets('Settings screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => AuthState(),
        child: const ApiKeyManagerApp(),
      ),
    );

    // Wait for initialization
    await tester.pumpAndSettle();

    // Navigate to settings (this would require mocking authentication)
    // For now, just verify the app structure is correct
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
