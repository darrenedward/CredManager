import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'package:api_key_manager/main.dart';
import 'package:api_key_manager/models/auth_state.dart';
import 'package:api_key_manager/utils/constants.dart';

// Mock AuthState that doesn't start timers
class MockAuthState extends ChangeNotifier {
  bool _isInitialized = true;
  bool _isLoggedIn = false;
  bool _setupCompleted = false;

  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _isLoggedIn;
  bool get setupCompleted => _setupCompleted;
  bool get hasValidSession => false;

  Future<void> initialize() async {
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> isSetupCompleted() async {
    return _setupCompleted;
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Mock method channels for flutter_secure_storage
    const MethodChannel secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      secureStorageChannel,
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

    // Mock method channels for shared_preferences
    const MethodChannel sharedPrefsChannel = MethodChannel('plugins.flutter.io/shared_preferences');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      sharedPrefsChannel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getAll':
            return {}; // Return empty map for getAll
          case 'setBool':
            return true; // Mock successful setBool
          case 'setString':
            return true; // Mock successful setString
          case 'remove':
            return true; // Mock successful remove
          case 'clear':
            return true; // Mock successful clear
          default:
            return null;
        }
      },
    );
  });

  testWidgets('App starts and shows loading screen initially', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => MockAuthState(),
        child: const ApiKeyManagerApp(),
      ),
    );

    // Initial pump to start the app
    await tester.pump();

    // Verify that the loading screen appears initially
    expect(find.text('Initializing Cred Manager...'), findsOneWidget);
    expect(find.byIcon(Icons.security), findsOneWidget);
  });

  testWidgets('App has correct MaterialApp structure', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => MockAuthState(),
        child: const ApiKeyManagerApp(),
      ),
    );

    // Initial pump
    await tester.pump();

    // Verify MaterialApp is present
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('App title is correct', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => MockAuthState(),
        child: const ApiKeyManagerApp(),
      ),
    );

    // Initial pump
    await tester.pump();

    // The app title is set in MaterialApp
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.title, equals('Cred Manager'));
  });
}
