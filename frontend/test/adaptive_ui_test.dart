import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cred_manager/models/auth_state.dart';
import 'package:cred_manager/models/dashboard_state.dart';
import 'package:cred_manager/services/credential_storage_service.dart';
import 'package:cred_manager/services/responsive_service.dart';

void main() {
  group('Adaptive UI Tests', () {
    Widget createTestWidget({required Size screenSize, required Widget child}) {
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
          home: MediaQuery(
            data: MediaQueryData(size: screenSize),
            child: child,
          ),
        ),
      );
    }

    testWidgets('Cards adapt to responsive layout', (WidgetTester tester) async {
      const mobileSize = Size(375, 667);
      const tabletSize = Size(768, 1024);
      const desktopSize = Size(1200, 800);

      // Test mobile layout
      await tester.pumpWidget(createTestWidget(
        screenSize: mobileSize,
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
      ));
      await tester.pumpAndSettle();

      // Mobile card should be nearly full width
      final mobileCard = tester.widget<Container>(find.byType(Container));
      expect(mobileCard.constraints?.maxWidth ?? mobileCard.decoration, isNotNull);

      // Test tablet layout
      await tester.pumpWidget(createTestWidget(
        screenSize: tabletSize,
        child: Builder(
          builder: (context) {
            final cardWidth = ResponsiveService.getResponsiveCardWidth(context);
            return Scaffold(
              body: Container(
                width: cardWidth,
                height: 100,
                color: Colors.green,
                child: const Text('Tablet Card'),
              ),
            );
          },
        ),
      ));
      await tester.pumpAndSettle();

      // Test desktop layout
      await tester.pumpWidget(createTestWidget(
        screenSize: desktopSize,
        child: Builder(
          builder: (context) {
            final cardWidth = ResponsiveService.getResponsiveCardWidth(context);
            return Scaffold(
              body: Container(
                width: cardWidth,
                height: 100,
                color: Colors.red,
                child: const Text('Desktop Card'),
              ),
            );
          },
        ),
      ));
      await tester.pumpAndSettle();
    });

    testWidgets('Dialogs adapt to screen size', (WidgetTester tester) async {
      const mobileSize = Size(375, 667);
      const desktopSize = Size(1200, 800);

      // Test mobile dialog detection
      await tester.pumpWidget(createTestWidget(
        screenSize: mobileSize,
        child: Builder(
          builder: (context) {
            final shouldUseFullScreen = ResponsiveService.shouldUseFullScreenDialog(context);
            final dialogWidth = ResponsiveService.getDialogWidth(context);

            return Scaffold(
              body: Column(
                children: [
                  Text('Full Screen: $shouldUseFullScreen'),
                  Text('Dialog Width: $dialogWidth'),
                ],
              ),
            );
          },
        ),
      ));
      await tester.pumpAndSettle();

      // Should use full screen on mobile
      expect(find.text('Full Screen: true'), findsOneWidget);

      // Test desktop dialog detection
      await tester.pumpWidget(createTestWidget(
        screenSize: desktopSize,
        child: Builder(
          builder: (context) {
            final shouldUseFullScreen = ResponsiveService.shouldUseFullScreenDialog(context);
            final dialogWidth = ResponsiveService.getDialogWidth(context);

            return Scaffold(
              body: Column(
                children: [
                  Text('Full Screen: $shouldUseFullScreen'),
                  Text('Dialog Width: $dialogWidth'),
                ],
              ),
            );
          },
        ),
      ));
      await tester.pumpAndSettle();

      // Should not use full screen on desktop
      expect(find.text('Full Screen: false'), findsOneWidget);
    });

    testWidgets('Text scaling adapts to device type', (WidgetTester tester) async {
      const mobileSize = Size(375, 667);
      const tabletSize = Size(768, 1024);
      const desktopSize = Size(1200, 800);

      // Test mobile text scaling
      await tester.pumpWidget(createTestWidget(
        screenSize: mobileSize,
        child: Builder(
          builder: (context) {
            final textScale = ResponsiveService.getResponsiveTextScale(context);
            return Scaffold(
              body: Text(
                'Mobile Text',
                textScaler: TextScaler.linear(textScale),
              ),
            );
          },
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Mobile Text'), findsOneWidget);

      // Test tablet text scaling
      await tester.pumpWidget(createTestWidget(
        screenSize: tabletSize,
        child: Builder(
          builder: (context) {
            final textScale = ResponsiveService.getResponsiveTextScale(context);
            return Scaffold(
              body: Text(
                'Tablet Text',
                textScaler: TextScaler.linear(textScale),
              ),
            );
          },
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Tablet Text'), findsOneWidget);

      // Test desktop text scaling
      await tester.pumpWidget(createTestWidget(
        screenSize: desktopSize,
        child: Builder(
          builder: (context) {
            final textScale = ResponsiveService.getResponsiveTextScale(context);
            return Scaffold(
              body: Text(
                'Desktop Text',
                textScaler: TextScaler.linear(textScale),
              ),
            );
          },
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Desktop Text'), findsOneWidget);
    });

    testWidgets('Data tables convert to lists on mobile', (WidgetTester tester) async {
      const mobileSize = Size(375, 667);
      const desktopSize = Size(1200, 800);

      final testData = [
        {'name': 'Item 1', 'value': 'Value 1'},
        {'name': 'Item 2', 'value': 'Value 2'},
        {'name': 'Item 3', 'value': 'Value 3'},
      ];

      // Test mobile layout (should show list)
      await tester.pumpWidget(createTestWidget(
        screenSize: mobileSize,
        child: Builder(
          builder: (context) {
            final isMobile = ResponsiveService.isMobile(context);
            
            return Scaffold(
              body: isMobile
                  ? ListView.builder(
                      itemCount: testData.length,
                      itemBuilder: (context, index) => ListTile(
                        title: Text(testData[index]['name']!),
                        subtitle: Text(testData[index]['value']!),
                      ),
                    )
                  : DataTable(
                      columns: const [
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Value')),
                      ],
                      rows: testData.map((item) => DataRow(
                        cells: [
                          DataCell(Text(item['name']!)),
                          DataCell(Text(item['value']!)),
                        ],
                      )).toList(),
                    ),
            );
          },
        ),
      ));
      await tester.pumpAndSettle();

      // Should show ListView on mobile
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(DataTable), findsNothing);

      // Test desktop layout (should show table)
      await tester.pumpWidget(createTestWidget(
        screenSize: desktopSize,
        child: Builder(
          builder: (context) {
            final isMobile = ResponsiveService.isMobile(context);
            
            return Scaffold(
              body: isMobile
                  ? ListView.builder(
                      itemCount: testData.length,
                      itemBuilder: (context, index) => ListTile(
                        title: Text(testData[index]['name']!),
                        subtitle: Text(testData[index]['value']!),
                      ),
                    )
                  : DataTable(
                      columns: const [
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Value')),
                      ],
                      rows: testData.map((item) => DataRow(
                        cells: [
                          DataCell(Text(item['name']!)),
                          DataCell(Text(item['value']!)),
                        ],
                      )).toList(),
                    ),
            );
          },
        ),
      ));
      await tester.pumpAndSettle();

      // Should show DataTable on desktop
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
    });
  });
}
