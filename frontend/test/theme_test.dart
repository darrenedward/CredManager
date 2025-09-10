import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../lib/main.dart';
import '../lib/models/auth_state.dart';
import '../lib/utils/constants.dart';

void main() {
  group('Material 3 Theme Tests', () {
    testWidgets('App uses Material 3 with correct color scheme', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => AuthState(),
          child: const ApiKeyManagerApp(),
        ),
      );

      // Get the MaterialApp widget
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      
      // Verify Material 3 is enabled
      expect(materialApp.theme?.useMaterial3, true);
      
      // Verify ColorScheme is using our seed colors
      final colorScheme = materialApp.theme?.colorScheme;
      expect(colorScheme, isNotNull);
      
      // The primary color should be derived from our navy blue seed
      // Note: ColorScheme.fromSeed() may modify the exact color, but it should be navy-based
      expect(colorScheme!.primary.value, isNot(equals(Colors.blue.value))); // Should not be default blue
      
      print('Primary color: ${colorScheme.primary}');
      print('Secondary color: ${colorScheme.secondary}');
      print('Surface color: ${colorScheme.surface}');
    });

    testWidgets('Color constants are updated correctly', (WidgetTester tester) async {
      // Test that our color constants have been updated
      expect(AppConstants.primaryColor, const Color(0xFF0f172a)); // Navy blue
      expect(AppConstants.secondaryColor, const Color(0xFFf59e0b)); // Orange (was teal)
      expect(AppConstants.accentColor, const Color(0xFFf59e0b)); // Orange
      
      // Verify we have Material 3 seed colors
      expect(AppConstants.primarySeed, const Color(0xFF0f172a));
      expect(AppConstants.secondarySeed, const Color(0xFFf59e0b));
    });

    testWidgets('Theme components are configured correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (context) => AuthState(),
          child: const ApiKeyManagerApp(),
        ),
      );

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final theme = materialApp.theme!;
      
      // Test AppBar theme
      expect(theme.appBarTheme.backgroundColor, AppConstants.surfaceColor);
      expect(theme.appBarTheme.foregroundColor, AppConstants.primaryColor);
      expect(theme.appBarTheme.elevation, 0);
      
      // Test ElevatedButton theme
      final elevatedButtonStyle = theme.elevatedButtonTheme.style!;
      expect(elevatedButtonStyle.backgroundColor?.resolve({}), AppConstants.primaryColor);
      expect(elevatedButtonStyle.foregroundColor?.resolve({}), Colors.white);
      
      // Test Card theme
      expect(theme.cardTheme.color, AppConstants.surfaceColor);
      expect(theme.cardTheme.elevation, 2);
    });
  });
}
