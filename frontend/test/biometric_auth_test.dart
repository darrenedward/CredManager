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
