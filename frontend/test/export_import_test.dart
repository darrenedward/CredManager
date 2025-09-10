import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../lib/screens/settings_screen.dart';
import '../lib/models/auth_state.dart';

void main() {
  group('Data Export/Import Tests', () {
    testWidgets('Settings screen has export and import functionality', (WidgetTester tester) async {
      // Build the settings screen
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (context) => AuthState(),
            child: const SettingsScreen(),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Look for the Data Management section
      expect(find.text('Data Management'), findsOneWidget);
      
      // Look for export and import options
      expect(find.text('Export Data'), findsOneWidget);
      expect(find.text('Import Data'), findsOneWidget);
      
      // Verify the descriptions are updated
      expect(find.text('Export all your settings as JSON'), findsOneWidget);
      expect(find.text('Import settings from JSON data'), findsOneWidget);
    });

    testWidgets('Export functionality can be triggered', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (context) => AuthState(),
            child: const SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the Data Management section to expand it
      await tester.tap(find.text('Data Management'));
      await tester.pumpAndSettle();

      // Find and tap the Export Data option
      await tester.tap(find.text('Export Data'));
      await tester.pumpAndSettle();

      // Should show a snackbar with success message
      expect(find.text('Data exported to clipboard! Paste into a text file to save.'), findsOneWidget);
    });

    testWidgets('Import dialog can be opened', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (context) => AuthState(),
            child: const SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the Data Management section to expand it
      await tester.tap(find.text('Data Management'));
      await tester.pumpAndSettle();

      // Find and tap the Import Data option
      await tester.tap(find.text('Import Data'));
      await tester.pumpAndSettle();

      // Should show the import dialog
      expect(find.text('Import Data'), findsWidgets); // Title appears twice (in list and dialog)
      expect(find.text('Paste your exported JSON data below:'), findsOneWidget);
      expect(find.text('Paste JSON data here...'), findsOneWidget);
    });
  });
}
