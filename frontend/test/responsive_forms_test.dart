import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cred_manager/models/auth_state.dart';
import 'package:cred_manager/models/dashboard_state.dart';
import 'package:cred_manager/services/credential_storage_service.dart';
import 'package:cred_manager/services/responsive_service.dart';

void main() {
  group('Responsive Forms Tests', () {
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

    testWidgets('Form fields adapt to mobile layout', (WidgetTester tester) async {
      const mobileSize = Size(375, 667);
      const desktopSize = Size(1200, 800);

      // Test mobile form layout
      await tester.pumpWidget(createTestWidget(
        screenSize: mobileSize,
        child: Builder(
          builder: (context) {
            final padding = ResponsiveService.getResponsivePadding(context);
            final minTapTarget = ResponsiveService.getMinTapTargetSize(context);
            
            return Scaffold(
              body: SingleChildScrollView(
                padding: padding,
                child: Form(
                  child: Column(
                    children: [
                      SizedBox(
                        height: minTapTarget,
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Mobile Field',
                          ),
                        ),
                      ),
                      SizedBox(height: padding.vertical),
                      SizedBox(
                        height: minTapTarget,
                        child: ElevatedButton(
                          onPressed: () {},
                          child: const Text('Submit'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      // Test desktop form layout
      await tester.pumpWidget(createTestWidget(
        screenSize: desktopSize,
        child: Builder(
          builder: (context) {
            final padding = ResponsiveService.getResponsivePadding(context);
            final minTapTarget = ResponsiveService.getMinTapTargetSize(context);
            
            return Scaffold(
              body: SingleChildScrollView(
                padding: padding,
                child: Form(
                  child: Column(
                    children: [
                      SizedBox(
                        height: minTapTarget,
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Desktop Field',
                          ),
                        ),
                      ),
                      SizedBox(height: padding.vertical),
                      SizedBox(
                        height: minTapTarget,
                        child: ElevatedButton(
                          onPressed: () {},
                          child: const Text('Submit'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('Form has proper keyboard avoidance', (WidgetTester tester) async {
      const mobileSize = Size(375, 667);

      await tester.pumpWidget(createTestWidget(
        screenSize: mobileSize,
        child: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Field 1',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Field 2',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Field 3',
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Submit'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Should have SingleChildScrollView for keyboard avoidance
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('Input field sizing adapts to screen size', (WidgetTester tester) async {
      const mobileSize = Size(375, 667);
      const tabletSize = Size(768, 1024);

      // Test mobile input sizing
      await tester.pumpWidget(createTestWidget(
        screenSize: mobileSize,
        child: Builder(
          builder: (context) {
            final minTapTarget = ResponsiveService.getMinTapTargetSize(context);
            
            return Scaffold(
              body: Container(
                height: minTapTarget,
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Mobile Input',
                  ),
                ),
              ),
            );
          },
        ),
      ));
      await tester.pumpAndSettle();

      final mobileField = tester.widget<Container>(find.byType(Container));
      expect(mobileField.constraints?.minHeight, equals(48.0));

      // Test tablet input sizing
      await tester.pumpWidget(createTestWidget(
        screenSize: tabletSize,
        child: Builder(
          builder: (context) {
            final minTapTarget = ResponsiveService.getMinTapTargetSize(context);
            
            return Scaffold(
              body: Container(
                height: minTapTarget,
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Tablet Input',
                  ),
                ),
              ),
            );
          },
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Tablet Input'), findsOneWidget);
    });

    testWidgets('Date picker adapts to mobile', (WidgetTester tester) async {
      const mobileSize = Size(375, 667);

      await tester.pumpWidget(createTestWidget(
        screenSize: mobileSize,
        child: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                  },
                  child: const Text('Pick Date'),
                ),
              ),
            );
          },
        ),
      ));
      await tester.pumpAndSettle();

      // Tap to show date picker
      await tester.tap(find.text('Pick Date'));
      await tester.pumpAndSettle();

      // Should show date picker
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('Dropdown adapts to mobile layout', (WidgetTester tester) async {
      const mobileSize = Size(375, 667);

      await tester.pumpWidget(createTestWidget(
        screenSize: mobileSize,
        child: Builder(
          builder: (context) {
            final minTapTarget = ResponsiveService.getMinTapTargetSize(context);
            
            return Scaffold(
              body: Container(
                height: minTapTarget,
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Select Option',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'option1', child: Text('Option 1')),
                    DropdownMenuItem(value: 'option2', child: Text('Option 2')),
                    DropdownMenuItem(value: 'option3', child: Text('Option 3')),
                  ],
                  onChanged: (value) {},
                ),
              ),
            );
          },
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      
      // Tap to open dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Should show dropdown options
      expect(find.text('Option 1'), findsOneWidget);
      expect(find.text('Option 2'), findsOneWidget);
      expect(find.text('Option 3'), findsOneWidget);
    });
  });
}
