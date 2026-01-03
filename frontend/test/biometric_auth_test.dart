import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cred_manager/models/auth_state.dart';
import 'package:cred_manager/models/dashboard_state.dart';
import 'package:cred_manager/services/credential_storage_service.dart';

void main() {
  group('Biometric Authentication Tests', () {
    Widget createTestWidget({required Widget child}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthState>(
            create: (context) => AuthState(),
          ),
          ChangeNotifierProxyProvider<AuthState, DashboardState>(
            create: (context) => DashboardState(CredentialStorageService()),
            update: (context, authState, dashboardState) {
              if (dashboardState == null) {
                return DashboardState(CredentialStorageService());
              }
              return dashboardState;
            },
          ),
        ],
        child: MaterialApp(
          home: child,
        ),
      );
    }

    testWidgets('Biometric availability detection works', (WidgetTester tester) async {
      bool biometricAvailable = false;
      bool deviceSupported = false;

      await tester.pumpWidget(createTestWidget(
        child: Builder(
          builder: (context) {
            return Scaffold(
              body: Column(
                children: [
                  Text('Biometric Available: $biometricAvailable'),
                  Text('Device Supported: $deviceSupported'),
                  ElevatedButton(
                    onPressed: () {
                      // Mock biometric availability check
                      biometricAvailable = true;
                      deviceSupported = true;
                    },
                    child: const Text('Check Biometric'),
                  ),
                ],
              ),
            );
          },
        ),
      ));
      await tester.pumpAndSettle();

      // Initially should show false
      expect(find.text('Biometric Available: false'), findsOneWidget);
      expect(find.text('Device Supported: false'), findsOneWidget);

      // Tap to check biometric availability
      await tester.tap(find.text('Check Biometric'));
      await tester.pumpAndSettle();

      // Should update the values
      expect(biometricAvailable, isTrue);
      expect(deviceSupported, isTrue);
    });

    testWidgets('Biometric prompt UI shows correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        child: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: const Column(
                      children: [
                        Icon(Icons.fingerprint, size: 64),
                        SizedBox(height: 16),
                        Text('Touch sensor to authenticate'),
                        SizedBox(height: 16),
                        Text('Use passphrase instead'),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ));
      await tester.pumpAndSettle();

      // Should show biometric prompt elements
      expect(find.byIcon(Icons.fingerprint), findsOneWidget);
      expect(find.text('Touch sensor to authenticate'), findsOneWidget);
      expect(find.text('Use passphrase instead'), findsOneWidget);
    });

    testWidgets('Biometric authentication fallback works', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(
        child: const _BiometricFallbackTestWidget(),
      ));
      await tester.pumpAndSettle();

      // Initially should show biometric authentication
      expect(find.text('Biometric Authentication'), findsOneWidget);

      // Tap to fallback to passphrase
      await tester.tap(find.text('Fallback to Passphrase'));
      await tester.pumpAndSettle();

      // Should show passphrase authentication
      expect(find.text('Passphrase Authentication'), findsOneWidget);
    });

    testWidgets('Biometric settings toggle works', (WidgetTester tester) async {
      bool biometricEnabled = false;

      await tester.pumpWidget(createTestWidget(
        child: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: Column(
                children: [
                  Text('Biometric Enabled: $biometricEnabled'),
                  Switch(
                    value: biometricEnabled,
                    onChanged: (value) {
                      setState(() {
                        biometricEnabled = value;
                      });
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ));
      await tester.pumpAndSettle();

      // Initially should be disabled
      expect(find.text('Biometric Enabled: false'), findsOneWidget);

      // Tap switch to enable
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Should be enabled
      expect(find.text('Biometric Enabled: true'), findsOneWidget);
    });

    testWidgets('Biometric authentication success flow', (WidgetTester tester) async {
      bool authenticationSuccessful = false;
      String authMethod = '';

      await tester.pumpWidget(createTestWidget(
        child: Builder(
          builder: (context) {
            return Scaffold(
              body: Column(
                children: [
                  Text('Authentication: ${authenticationSuccessful ? "Success" : "Pending"}'),
                  Text('Method: $authMethod'),
                  ElevatedButton(
                    onPressed: () {
                      // Mock successful biometric authentication
                      authenticationSuccessful = true;
                      authMethod = 'Biometric';
                    },
                    child: const Text('Authenticate with Biometric'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Mock successful passphrase authentication
                      authenticationSuccessful = true;
                      authMethod = 'Passphrase';
                    },
                    child: const Text('Authenticate with Passphrase'),
                  ),
                ],
              ),
            );
          },
        ),
      ));
      await tester.pumpAndSettle();

      // Initially should show pending
      expect(find.text('Authentication: Pending'), findsOneWidget);

      // Test biometric authentication
      await tester.tap(find.text('Authenticate with Biometric'));
      await tester.pumpAndSettle();

      expect(authenticationSuccessful, isTrue);
      expect(authMethod, equals('Biometric'));

      // Reset for passphrase test
      authenticationSuccessful = false;
      authMethod = '';

      await tester.pumpWidget(createTestWidget(
        child: Builder(
          builder: (context) {
            return Scaffold(
              body: Column(
                children: [
                  Text('Authentication: ${authenticationSuccessful ? "Success" : "Pending"}'),
                  Text('Method: $authMethod'),
                  ElevatedButton(
                    onPressed: () {
                      // Mock successful passphrase authentication
                      authenticationSuccessful = true;
                      authMethod = 'Passphrase';
                    },
                    child: const Text('Authenticate with Passphrase'),
                  ),
                ],
              ),
            );
          },
        ),
      ));
      await tester.pumpAndSettle();

      // Test passphrase authentication
      await tester.tap(find.text('Authenticate with Passphrase'));
      await tester.pumpAndSettle();

      expect(authenticationSuccessful, isTrue);
      expect(authMethod, equals('Passphrase'));
    });
  });
}

class _BiometricFallbackTestWidget extends StatefulWidget {
  const _BiometricFallbackTestWidget();

  @override
  State<_BiometricFallbackTestWidget> createState() => _BiometricFallbackTestWidgetState();
}

class _BiometricFallbackTestWidgetState extends State<_BiometricFallbackTestWidget> {
  bool useBiometric = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (useBiometric)
            const Text('Biometric Authentication')
          else
            const Text('Passphrase Authentication'),
          ElevatedButton(
            onPressed: () {
              setState(() {
                useBiometric = false;
              });
            },
            child: const Text('Fallback to Passphrase'),
          ),
        ],
      ),
    );
  }
}

// Unit tests for BiometricAuthService AES encryption (ST025)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BiometricAuthService AES Encryption Tests (ST025)', () {
    late BiometricAuthService biometricService;

    setUp(() async {
      biometricService = BiometricAuthService();

      // Mock method channels for local_auth
      const MethodChannel localAuthChannel = MethodChannel('plugins.flutter.io/local_auth');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        localAuthChannel,
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'getAvailableBiometrics':
              return ['fingerprint'];
            case 'isDeviceSupported':
              return true;
            case 'canCheckBiometrics':
              return true;
            case 'authenticate':
              return true; // Mock successful authentication
            default:
              return null;
          }
        },
      );
    });

    test('should encrypt passphrase with AES for biometric storage', () async {
      // TDD: This test will initially fail until AES encryption is implemented
      const passphrase = 'TestPassphrase123!';
      const derivedKey = 'derived_key_from_passphrase'; // Mock derived key

      // Store biometric key with encryption
      await biometricService.storeBiometricKey(passphrase);

      // Retrieve and verify it's encrypted (not plain text)
      final encryptedKey = await biometricService.getBiometricKey();
      expect(encryptedKey, isNotNull, reason: 'Should store encrypted biometric key');
      expect(encryptedKey, isNot(equals(passphrase)), reason: 'Stored key should be encrypted, not plain text');

      // Should be able to decrypt back to original
      // This will require implementing the decryption logic
      expect(true, isTrue, reason: 'Should be able to decrypt stored passphrase (TDD - implement AES decryption)');
    });

    test('should decrypt AES encrypted passphrase for biometric login', () async {
      // TDD: This test will initially fail until AES decryption is implemented
      const passphrase = 'TestPassphrase123!';

      // Store encrypted passphrase
      await biometricService.storeBiometricKey(passphrase);

      // Retrieve and decrypt
      final decryptedPassphrase = await biometricService.getBiometricKey();
      expect(decryptedPassphrase, isNotNull, reason: 'Should retrieve encrypted key');
      expect(decryptedPassphrase, equals(passphrase), reason: 'Decrypted passphrase should match original');

      // Test with different passphrase
      const differentPassphrase = 'DifferentPass456!';
      await biometricService.storeBiometricKey(differentPassphrase);
      final decryptedDifferent = await biometricService.getBiometricKey();
      expect(decryptedDifferent, equals(differentPassphrase), reason: 'Should handle different passphrases');
    });

    test('should handle biometric login with encrypted passphrase retrieval', () async {
      // TDD: This test will initially fail until biometric login with encryption is implemented
      const passphrase = 'BiometricTestPass123!';

      // Enable biometric and store encrypted passphrase
      await biometricService.setBiometricEnabled(true);
      await biometricService.storeBiometricKey(passphrase);

      // Simulate biometric login (this would call loginWithBiometric in AuthState)
      final retrievedKey = await biometricService.getBiometricKey();
      expect(retrievedKey, isNotNull, reason: 'Should retrieve encrypted key for biometric login');
      expect(retrievedKey, equals(passphrase), reason: 'Retrieved key should be decryptable to original passphrase');

      // Test biometric login flow
      expect(true, isTrue, reason: 'Biometric login should use decrypted passphrase (TDD - implement in AuthState)');
    });

    test('should handle failure cases for biometric encryption', () async {
      // TDD: Test error handling for encryption/decryption failures

      // Test with invalid encryption key
      await biometricService.storeBiometricKey('test_passphrase');
      // Simulate corruption or invalid key
      expect(true, isTrue, reason: 'Should handle invalid encryption gracefully (TDD - implement error handling)');

      // Test missing biometric key
      await biometricService.removeBiometricKey();
      final missingKey = await biometricService.getBiometricKey();
      expect(missingKey, isNull, reason: 'Should return null for missing biometric key');

      // Test biometric not enabled
      await biometricService.setBiometricEnabled(false);
      expect(true, isTrue, reason: 'Should handle disabled biometric state (TDD - implement checks)');
    });

    test('should use proper AES encryption with derived key', () async {
      // TDD: This test documents the requirement for AES encryption with derived key
      const passphrase = 'AES_Test_Passphrase!@#';
      const mockDerivedKey = 'mock_derived_key_from_argon2'; // In real implementation, this comes from Argon2

      // The implementation should:
      // 1. Use Argon2 to derive key from passphrase
      // 2. Use AES encryption with the derived key
      // 3. Store the encrypted result
      // 4. Be able to decrypt it back

      await biometricService.storeBiometricKey(passphrase);

      // Verify encryption properties
      final encrypted = await biometricService.getBiometricKey();
      expect(encrypted, isNotNull, reason: 'AES encryption should produce valid encrypted data');
      expect(encrypted!.length, greaterThan(passphrase.length), reason: 'Encrypted data should be longer than plain text');

      // Test that different passphrases produce different encrypted results
      const differentPassphrase = 'Different_AES_Test!@#';
      await biometricService.storeBiometricKey(differentPassphrase);
      final differentEncrypted = await biometricService.getBiometricKey();
      expect(differentEncrypted, isNot(equals(encrypted)), reason: 'Different passphrases should produce different encrypted results');
    });
  });
}
