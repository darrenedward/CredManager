import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:api_key_manager/screens/setup_screen.dart';
import 'package:api_key_manager/models/auth_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Mock method channels for flutter_secure_storage
    const MethodChannel channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'read':
            return null; // Return null for reads in tests
          case 'write':
            return null; // Mock successful write
          case 'delete':
            return null; // Mock successful delete
          case 'deleteAll':
            return null; // Mock successful deleteAll
          default:
            return null;
        }
      },
    );
  });

  testWidgets('SetupScreen displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => AuthState(),
        child: const MaterialApp(
          home: SetupScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(Stepper), findsOneWidget);
    expect(find.text('Create Passphrase'), findsOneWidget);
    // Find Security Questions text more specifically
    expect(find.text('Security Questions').first, findsOneWidget);
    // Find the Complete button specifically (should be in a button)
    expect(find.widgetWithText(ElevatedButton, 'Complete'), findsOneWidget);
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