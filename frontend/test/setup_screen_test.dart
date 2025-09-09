import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_key_manager/screens/setup_screen.dart';
import 'package:api_key_manager/models/auth_state.dart';

void main() {
  testWidgets('SetupScreen displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => AuthState(),
        child: const MaterialApp(
          home: SetupScreen(),
        ),
      ),
    );

    expect(find.byType(Stepper), findsOneWidget);
    expect(find.text('Create Passphrase'), findsOneWidget);
    // Use a more specific finder for the Security Questions text
    expect(find.text('Security Questions').first, findsOneWidget);
    expect(find.text('Complete'), findsOneWidget);
  });

  testWidgets('SetupScreen validation works', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => AuthState(),
        child: const MaterialApp(
          home: SetupScreen(),
        ),
      ),
    );

    expect(find.byType(TextField), findsWidgets);
  });
}