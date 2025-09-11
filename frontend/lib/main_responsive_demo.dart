import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/auth_state.dart';
import 'models/dashboard_state.dart';
import 'screens/main_dashboard_screen_responsive.dart';
import 'services/credential_storage_service.dart';
import 'utils/constants.dart';

void main() {
  runApp(const ResponsiveDemoApp());
}

class ResponsiveDemoApp extends StatelessWidget {
  const ResponsiveDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
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
        title: 'Responsive Demo - ${AppConstants.appName}',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppConstants.primarySeed,
            secondary: AppConstants.secondarySeed,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: const ResponsiveDemoScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class ResponsiveDemoScreen extends StatefulWidget {
  const ResponsiveDemoScreen({super.key});

  @override
  State<ResponsiveDemoScreen> createState() => _ResponsiveDemoScreenState();
}

class _ResponsiveDemoScreenState extends State<ResponsiveDemoScreen> {
  @override
  void initState() {
    super.initState();
    // For demo purposes, we'll just show the responsive layout directly
    // In a real app, users would need to authenticate first
  }

  @override
  Widget build(BuildContext context) {
    // For demo purposes, show the responsive layout directly
    // In a real app, this would check authentication state
    return const MainDashboardScreenResponsive();
  }
}
