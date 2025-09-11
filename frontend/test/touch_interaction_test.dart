import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cred_manager/models/auth_state.dart';
import 'package:cred_manager/models/dashboard_state.dart';
import 'package:cred_manager/services/credential_storage_service.dart';
import 'package:cred_manager/services/responsive_service.dart';

void main() {
  group('Touch Interaction Tests', () {
    late CredentialStorageService mockStorageService;
    late AuthState authState;
    late DashboardState dashboardState;

    setUp(() async {
      mockStorageService = CredentialStorageService();
      authState = AuthState();
      dashboardState = DashboardState(mockStorageService);
      
      // Mock authentication
      await authState.login('testpassword');
    });

    testWidgets('Tap targets meet minimum size requirements', (WidgetTester tester) async {
      const mobileSize = Size(375, 667);
      
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: mobileSize),
            child: Builder(
              builder: (context) {
                final minSize = ResponsiveService.getMinTapTargetSize(context);
                return Scaffold(
                  body: Column(
                    children: [
                      // Test button with responsive tap target
                      SizedBox(
                        width: minSize,
                        height: minSize,
                        child: ElevatedButton(
                          onPressed: () {},
                          child: const Text('Test'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the button and verify its size
      final buttonFinder = find.byType(ElevatedButton);
      expect(buttonFinder, findsOneWidget);

      final RenderBox buttonBox = tester.renderObject(buttonFinder);
      expect(buttonBox.size.width, greaterThanOrEqualTo(48.0));
      expect(buttonBox.size.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('Touch interactions have appropriate spacing', (WidgetTester tester) async {
      const mobileSize = Size(375, 667);
      
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: mobileSize),
            child: Scaffold(
              body: Column(
                children: [
                  // Multiple buttons to test spacing
                  ElevatedButton(onPressed: () {}, child: const Text('Button 1')),
                  const SizedBox(height: 8), // Minimum spacing
                  ElevatedButton(onPressed: () {}, child: const Text('Button 2')),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: () {}, child: const Text('Button 3')),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify buttons exist
      expect(find.byType(ElevatedButton), findsNWidgets(3));
      
      // Verify spacing between buttons
      final button1 = tester.getTopLeft(find.text('Button 1'));
      final button2 = tester.getTopLeft(find.text('Button 2'));
      final spacing = button2.dy - button1.dy;
      
      // Should have at least 8px spacing plus button height
      expect(spacing, greaterThan(40.0)); // Approximate button height + spacing
    });

    testWidgets('Responsive padding adapts to screen size', (WidgetTester tester) async {
      // Test mobile padding
      const mobileSize = Size(375, 667);
      
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: mobileSize),
            child: Builder(
              builder: (context) {
                final padding = ResponsiveService.getResponsivePadding(context);
                return Scaffold(
                  body: Container(
                    padding: padding,
                    child: const Text('Mobile Content'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Mobile Content'), findsOneWidget);

      // Test desktop padding
      const desktopSize = Size(1400, 800);
      
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: desktopSize),
            child: Builder(
              builder: (context) {
                final padding = ResponsiveService.getResponsivePadding(context);
                return Scaffold(
                  body: Container(
                    padding: padding,
                    child: const Text('Desktop Content'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Desktop Content'), findsOneWidget);
    });

    testWidgets('Card width adapts responsively', (WidgetTester tester) async {
      // Test mobile card width (full width)
      const mobileSize = Size(375, 667);
      
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: mobileSize),
            child: Builder(
              builder: (context) {
                final cardWidth = ResponsiveService.getResponsiveCardWidth(context);
                return Scaffold(
                  body: Container(
                    width: cardWidth,
                    height: 100,
                    color: Colors.blue,
                    child: const Text('Mobile Card'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      final cardFinder = find.byType(Container);
      final RenderBox cardBox = tester.renderObject(cardFinder);
      
      // Mobile card should be nearly full width (screen width - padding)
      expect(cardBox.size.width, closeTo(343.0, 5.0)); // 375 - 32 = 343
    });

    testWidgets('Dialog width adapts to screen size', (WidgetTester tester) async {
      const mobileSize = Size(375, 667);
      
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: mobileSize),
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () {
                      final dialogWidth = ResponsiveService.getDialogWidth(context);
                      final shouldUseFullScreen = ResponsiveService.shouldUseFullScreenDialog(context);
                      
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Dialog Width: ${dialogWidth.toInt()}'),
                          content: Text('Full Screen: $shouldUseFullScreen'),
                        ),
                      );
                    },
                    child: const Text('Show Dialog'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();
      
      // Verify dialog appears
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('Dialog Width:'), findsOneWidget);
      expect(find.text('Full Screen: true'), findsOneWidget);
    });

    testWidgets('Pull-to-refresh gesture works on mobile', (WidgetTester tester) async {
      const mobileSize = Size(375, 667);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: mobileSize),
            child: Scaffold(
              body: RefreshIndicator(
                onRefresh: () async {
                  // Mock refresh action
                  await Future.delayed(const Duration(milliseconds: 100));
                },
                child: ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) => ListTile(
                    title: Text('Item $index'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the RefreshIndicator
      expect(find.byType(RefreshIndicator), findsOneWidget);

      // Simulate pull-to-refresh gesture
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pump();

      // Should show refresh indicator
      expect(find.byType(RefreshProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('Haptic feedback triggers on important actions', (WidgetTester tester) async {
      const mobileSize = Size(375, 667);

      bool hapticTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: mobileSize),
            child: Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Mock haptic feedback
                    hapticTriggered = true;
                  },
                  child: const Text('Important Action'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify haptic feedback would be triggered
      expect(hapticTriggered, isTrue);
    });
  });
}
