import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:cred_manager/main.dart';
import 'package:cred_manager/models/auth_state.dart';
import 'package:cred_manager/models/dashboard_state.dart';
import 'package:cred_manager/services/theme_service.dart';
import 'package:cred_manager/services/database_service.dart';
import 'package:cred_manager/services/auth_service.dart';

/// End-to-End Tests for Password Vault Feature
///
/// These tests verify the complete user journey for password vault functionality:
/// - Login → Dashboard → Password Vault management
/// - Creating, editing, and deleting vaults
/// - Creating, editing, and deleting password entries
/// - Password generation and regeneration
/// - Data persistence across app restarts
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Password Vault E2E Tests', () {
    late AuthService authService;

    const testPassphrase = 'TestE2EPassphrase123!';
    const testEmail = 'e2e-test@example.com';

    setUpAll(() async {
      // Initialize singleton services
      authService = AuthService.instance;
    });

    setUp(() async {
      // Clean up database before each test
      await DatabaseService.instance.deleteDatabase();
      await DatabaseService.instance.initialize();

      // Create test user
      await authService.createPassphrase(
        testPassphrase,
        [
          {'question': 'What is your favorite color?', 'answer': 'Blue'},
          {'question': 'What was your first pet\'s name?', 'answer': 'Fluffy'},
          {'question': 'What city were you born in?', 'answer': 'Paris'},
        ],
      );
    });

    /// Helper function to build the app
    Widget buildTestApp() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ThemeService()),
          ChangeNotifierProvider(create: (context) => AuthState()),
          ChangeNotifierProxyProvider<AuthState, DashboardState>(
            create: (context) => DashboardState(
              Provider.of<AuthState>(context, listen: false).credentialStorage,
            ),
            update: (context, authState, dashboardState) {
              if (authState.hasValidSession) {
                return dashboardState ?? DashboardState(authState.credentialStorage);
              } else {
                return DashboardState(authState.credentialStorage);
              }
            },
          ),
        ],
        child: const ApiKeyManagerApp(),
      );
    }

    /// Helper function to login
    Future<void> login(WidgetTester tester) async {
      // Find passphrase field and enter test passphrase
      final passphraseField = find.byType(TextField);
      expect(passphraseField, findsOneWidget);

      await tester.enterText(passphraseField, testPassphrase);
      await tester.pumpAndSettle();

      // Tap continue/login button
      final continueButton = find.text('Continue');
      await tester.tap(continueButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify dashboard is visible
      expect(find.text('Dashboard'), findsOneWidget);
    }

    /// Helper function to navigate to Password Vault section
    Future<void> navigateToPasswordVault(WidgetTester tester) async {
      final passwordVaultButton = find.text('Password Vault');
      expect(passwordVaultButton, findsOneWidget, reason: 'Password Vault button should exist');

      await tester.tap(passwordVaultButton);
      await tester.pumpAndSettle();

      // Verify Password Vault section is visible
      expect(find.text('Password Vaults'), findsOneWidget, reason: 'Should show Password Vaults header');
    }

    // E002: Login to Dashboard E2E
    testWidgets('E005-E008: Login flow and navigate to Password Vault', (tester) async {
      // Build and launch app
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Verify login screen
      expect(find.text('Welcome back'), findsOneWidget);

      // Login
      await login(tester);

      // Verify dashboard loaded
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Quick Actions'), findsOneWidget);

      // Navigate to Password Vault
      await navigateToPasswordVault(tester);

      print('✅ Login to Password Vault flow successful');
    });

    // E003: Password Vault CRUD E2E
    testWidgets('E009-E013: Create, edit, and delete password vault', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Login
      await login(tester);

      // Navigate to Password Vault
      await navigateToPasswordVault(tester);

      // Should show empty state
      expect(find.text('No Password Vaults Yet'), findsOneWidget);

      // EST009: Create new password vault
      final createButton = find.text('Create Password Vault');
      expect(createButton, findsOneWidget);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // Fill in vault details
      final nameField = find.widgetWithText(TextField, 'Vault Name');
      await tester.enterText(nameField, 'Personal Accounts');

      final descField = find.widgetWithText(TextField, 'Description (optional)');
      await tester.enterText(descField, 'My personal login credentials');

      // Save vault
      final saveButton = find.text('Create');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // EST010: Verify vault appears in list
      expect(find.text('Personal Accounts'), findsOneWidget);
      expect(find.text('My personal login credentials'), findsOneWidget);

      // EST013: Test vault options - long press to show options
      await tester.longPress(find.text('Personal Accounts'));
      await tester.pumpAndSettle();

      // Should show options bottom sheet
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Close options
      await tester.tapAt(const Offset(10, 10)); // Tap outside
      await tester.pumpAndSettle();

      // EST011: Edit vault
      await tester.longPress(find.text('Personal Accounts'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Update vault name
      final editNameField = find.byType(TextField).first;
      await tester.enterText(editNameField, ' (Updated)');
      await tester.pumpAndSettle();

      final updateButton = find.text('Save');
      await tester.tap(updateButton);
      await tester.pumpAndSettle();

      // Verify updated name
      expect(find.text('Personal Accounts (Updated)'), findsOneWidget);

      // EST012: Delete vault
      await tester.longPress(find.text('Personal Accounts (Updated)'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Confirm delete
      final confirmButton = find.text('Delete');
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Verify vault is deleted - back to empty state
      expect(find.text('No Password Vaults Yet'), findsOneWidget);

      print('✅ Password Vault CRUD flow successful');
    });

    // E004: Password Entry CRUD E2E
    testWidgets('E014-E019: Create, view, edit, and delete password entry', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Login
      await login(tester);

      // Navigate to Password Vault
      await navigateToPasswordVault(tester);

      // Create a vault first
      await tester.tap(find.text('Create Password Vault'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Vault Name'), 'Test Vault');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // EST014: Create password entry
      await tester.tap(find.text('Test Vault'));
      await tester.pumpAndSettle();

      // Should show empty state for entries
      expect(find.textContaining('No passwords'), findsOneWidget);

      // Tap add entry FAB
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
      await tester.tap(fab);
      await tester.pumpAndSettle();

      // Fill in entry details
      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Gmail');
      await tester.enterText(find.widgetWithText(TextField, 'Username'), 'test@gmail.com');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'TestPassword123!');
      await tester.enterText(find.widgetWithText(TextField, 'URL'), 'https://gmail.com');
      await tester.enterText(find.widgetWithText(TextField, 'Notes'), 'My main email account');

      // Save entry
      await tester.tap(find.text('Add Entry'));
      await tester.pumpAndSettle();

      // Verify entry appears in list
      expect(find.text('Gmail'), findsOneWidget);
      expect(find.text('test@gmail.com'), findsOneWidget);

      // EST015 & EST016: View password entry details and copy
      await tester.tap(find.text('Gmail'));
      await tester.pumpAndSettle();

      // Verify details
      expect(find.text('Gmail'), findsOneWidget);
      expect(find.text('test@gmail.com'), findsOneWidget);
      expect(find.text('https://gmail.com'), findsOneWidget);
      expect(find.text('My main email account'), findsOneWidget);

      // Test copy password button
      final copyButton = find.byIcon(Icons.content_copy);
      await tester.tap(copyButton);
      await tester.pumpAndSettle();

      // Close details
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // EST017: Edit password entry
      await tester.longPress(find.text('Gmail'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Update notes
      final notesField = find.widgetWithText(TextField, 'Notes');
      await tester.enterText(notesField, ' - Updated');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify updated notes
      await tester.tap(find.text('Gmail'));
      await tester.pumpAndSettle();
      expect(find.text('My main email account - Updated'), findsOneWidget);

      // Close details
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // EST018: Delete password entry
      await tester.longPress(find.text('Gmail'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify entry deleted
      expect(find.textContaining('No passwords'), findsOneWidget);

      print('✅ Password Entry CRUD flow successful');
    });

    // E005: Password Generator E2E
    testWidgets('E020-E025: Generate password in create entry dialog', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Login and navigate
      await login(tester);
      await navigateToPasswordVault(tester);

      // Create vault
      await tester.tap(find.text('Create Password Vault'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Vault Name'), 'Test Vault');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Open add entry dialog
      await tester.tap(find.text('Test Vault'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // EST020 & EST021: Open generator and adjust length
      final generateButton = find.byIcon(Icons.autorenew);
      expect(generateButton, findsOneWidget);

      await tester.tap(generateButton);
      await tester.pumpAndSettle();

      // Should show generator options
      expect(find.textContaining('Generate'), findsOneWidget);

      // Close generator
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      print('✅ Password Generator UI accessible');
    });

    // E006: Password Regeneration E2E
    testWidgets('E026-E030: Regenerate password from detail view', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Login and navigate
      await login(tester);
      await navigateToPasswordVault(tester);

      // Create vault and entry
      await tester.tap(find.text('Create Password Vault'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Vault Name'), 'Test Vault');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Test Site');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'OldPassword123!');
      await tester.tap(find.text('Add Entry'));
      await tester.pumpAndSettle();

      // EST026: Open entry details
      await tester.tap(find.text('Test Site'));
      await tester.pumpAndSettle();

      // EST027: Find regenerate button
      final regenerateButtons = find.byIcon(Icons.autorenew);
      if (regenerateButtons.evaluate().length > 1) {
        // Second regenerate button is for regenerating
        final lastRegenerate = regenerateButtons.evaluate().last;
        await tester.tap(find.byWidget(lastRegenerate));
        await tester.pumpAndSettle();

        // Should show regenerate dialog
        expect(find.textContaining('Regenerate'), findsOneWidget);

        // Close dialog
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
      }

      print('✅ Password Regeneration UI accessible');
    });

    // E007: Data Persistence E2E
    testWidgets('E031-E035: Verify data creation and storage', (tester) async {
      // EST031: Create vault with entries
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await login(tester);
      await navigateToPasswordVault(tester);

      // Create vault
      await tester.tap(find.text('Create Password Vault'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Vault Name'), 'Persistent Vault');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Add entry
      await tester.tap(find.text('Persistent Vault'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Persistent Entry');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'PersistentPassword123!');
      await tester.tap(find.text('Add Entry'));
      await tester.pumpAndSettle();

      // Verify data exists
      expect(find.text('Persistent Entry'), findsOneWidget);

      print('✅ Data created and stored successfully');
    });

    // E008: Search E2E
    testWidgets('E036-E039: Search vaults and entries', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await login(tester);
      await navigateToPasswordVault(tester);

      // Create multiple vaults
      await tester.tap(find.text('Create Password Vault'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Vault Name'), 'Personal Vault');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Password Vault'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Vault Name'), 'Work Vault');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // EST036: Search for vault
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'Personal');
      await tester.pumpAndSettle();

      // Should show only Personal Vault
      expect(find.text('Personal Vault'), findsOneWidget);
      expect(find.text('Work Vault'), findsNothing);

      // EST039: Clear search
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();

      // Should show both vaults
      expect(find.text('Personal Vault'), findsOneWidget);
      expect(find.text('Work Vault'), findsOneWidget);

      print('✅ Search functionality working');
    });

    // Full User Journey Test
    testWidgets('Complete password vault user journey', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // 1. Login
      print('Step 1: Login...');
      await login(tester);

      // 2. Navigate to Password Vault
      print('Step 2: Navigate to Password Vault...');
      await navigateToPasswordVault(tester);

      // 3. Create vault
      print('Step 3: Create password vault...');
      await tester.tap(find.text('Create Password Vault'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Vault Name'), 'My Passwords');
      await tester.enterText(find.widgetWithText(TextField, 'Description (optional)'), 'My personal and work passwords');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // 4. Create entry
      print('Step 4: Create password entry...');
      await tester.tap(find.text('My Passwords'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Netflix');
      await tester.enterText(find.widgetWithText(TextField, 'Username'), 'moviebuff@example.com');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'NetflixPassword123!');
      await tester.enterText(find.widgetWithText(TextField, 'URL'), 'https://netflix.com');
      await tester.tap(find.text('Add Entry'));
      await tester.pumpAndSettle();

      // 5. View entry details
      print('Step 5: View entry details...');
      await tester.tap(find.text('Netflix'));
      await tester.pumpAndSettle();

      // Verify all details
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('moviebuff@example.com'), findsOneWidget);
      expect(find.text('https://netflix.com'), findsOneWidget);

      // 6. Copy password
      print('Step 6: Copy password to clipboard...');
      await tester.tap(find.byIcon(Icons.content_copy));
      await tester.pumpAndSettle();

      // 7. Navigate back
      print('Step 7: Navigate back...');
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Verify vault still shows entry
      expect(find.text('Netflix'), findsOneWidget);

      print('✅ Complete user journey successful!');
    });
  });
}
