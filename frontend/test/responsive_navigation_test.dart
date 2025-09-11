import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cred_manager/models/auth_state.dart';
import 'package:cred_manager/models/dashboard_state.dart';
import 'package:cred_manager/screens/main_dashboard_screen_responsive.dart';
import 'package:cred_manager/services/credential_storage_service.dart';

void main() {
  group('Responsive Navigation Tests', () {
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

    Widget createTestWidget({required Size screenSize}) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthState>.value(value: authState),
              ChangeNotifierProvider<DashboardState>.value(value: dashboardState),
            ],
            child: const MainDashboardScreenResponsive(),
          ),
        ),
      );
    }

    testWidgets('Desktop layout shows sidebar navigation', (WidgetTester tester) async {
      // Desktop breakpoint: >= 1200px
      const desktopSize = Size(1400, 800);
      
      await tester.pumpWidget(createTestWidget(screenSize: desktopSize));
      await tester.pumpAndSettle();

      // Should show sidebar container with fixed width
      expect(find.byType(Container), findsWidgets);
      
      // Should NOT show drawer
      expect(find.byType(Drawer), findsNothing);
      
      // Should NOT show bottom navigation
      expect(find.byType(BottomNavigationBar), findsNothing);
    });

    testWidgets('Tablet layout shows appropriate navigation', (WidgetTester tester) async {
      // Tablet breakpoint: 600-1199px
      const tabletSize = Size(800, 600);
      
      await tester.pumpWidget(createTestWidget(screenSize: tabletSize));
      await tester.pumpAndSettle();

      // Should adapt to tablet layout
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Mobile layout shows drawer and bottom navigation', (WidgetTester tester) async {
      // Mobile breakpoint: < 600px
      const mobileSize = Size(375, 667);
      
      await tester.pumpWidget(createTestWidget(screenSize: mobileSize));
      await tester.pumpAndSettle();

      // Should show bottom navigation bar
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Should show hamburger menu button in app bar
      expect(find.byIcon(Icons.menu), findsOneWidget);

      // Drawer should be available but not visible until opened
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.drawer, isNotNull);
    });

    testWidgets('Breakpoint detection works correctly', (WidgetTester tester) async {
      // Test mobile breakpoint
      await tester.pumpWidget(createTestWidget(screenSize: const Size(599, 800)));
      await tester.pumpAndSettle();
      final mobileScaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(mobileScaffold.drawer, isNotNull);

      // Test tablet breakpoint
      await tester.pumpWidget(createTestWidget(screenSize: const Size(600, 800)));
      await tester.pumpAndSettle();
      
      // Test desktop breakpoint
      await tester.pumpWidget(createTestWidget(screenSize: const Size(1200, 800)));
      await tester.pumpAndSettle();
    });

    testWidgets('Navigation state persists across screen size changes', (WidgetTester tester) async {
      // Start with desktop
      await tester.pumpWidget(createTestWidget(screenSize: const Size(1400, 800)));
      await tester.pumpAndSettle();

      // Navigate to projects overview
      dashboardState.showProjectsOverview();
      await tester.pumpAndSettle();

      // Switch to mobile
      await tester.pumpWidget(createTestWidget(screenSize: const Size(375, 667)));
      await tester.pumpAndSettle();

      // Navigation state should be preserved
      expect(dashboardState.currentView, equals('projects_overview'));
    });

    testWidgets('Drawer opens and closes correctly on mobile', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(screenSize: const Size(375, 667)));
      await tester.pumpAndSettle();

      // Find and tap hamburger menu
      final menuButton = find.byIcon(Icons.menu);
      expect(menuButton, findsOneWidget);
      
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Drawer should be open (visible)
      expect(find.byType(Drawer), findsOneWidget);
    });
  });
}
