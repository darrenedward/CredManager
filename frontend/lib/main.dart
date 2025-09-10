import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/setup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/recovery_screen.dart';
import 'screens/reset_passphrase_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/main_dashboard_screen.dart';
import 'screens/theme_test_screen.dart';
import 'models/auth_state.dart';
import 'models/dashboard_state.dart';
import 'utils/constants.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthState()),
        ChangeNotifierProxyProvider<AuthState, DashboardState>(
          create: (context) => DashboardState(
            Provider.of<AuthState>(context, listen: false).credentialStorage,
          ),
          update: (context, authState, dashboardState) {
            // Update dashboard state when auth state changes
            if (authState.hasValidSession) {
              // User logged in - ensure dashboard has access to credential storage
              return dashboardState ?? DashboardState(authState.credentialStorage);
            } else {
              // User logged out - return new dashboard state
              return DashboardState(authState.credentialStorage);
            }
          },
        ),
      ],
      child: const ApiKeyManagerApp(),
    ),
  );
}

class ApiKeyManagerApp extends StatelessWidget {
  const ApiKeyManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primarySeed,
          secondary: AppConstants.secondarySeed,
          brightness: Brightness.light,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppConstants.surfaceColor,
          foregroundColor: AppConstants.primaryColor,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: AppConstants.surfaceColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/setup': (context) => const SetupScreen(),
        '/login': (context) => const LoginScreen(),
        '/recovery': (context) => const RecoveryScreen(),
        '/reset-passphrase': (context) => const ResetPassphraseScreen(recoveryToken: ''),
        '/settings': (context) => const SettingsScreen(),
        '/dashboard': (context) => const MainDashboardScreen(),
        '/theme-test': (context) => const ThemeTestScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitializing = true;
  bool _setupCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final authState = Provider.of<AuthState>(context, listen: false);
    print('DEBUG: AuthWrapper - Starting initialization');
    await authState.initialize();

    // Check setup completion flag
    _setupCompleted = await authState.isSetupCompleted();

    print('DEBUG: AuthWrapper - Initialization complete, setup completed: $_setupCompleted');
    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = Provider.of<AuthState>(context);
    print('DEBUG: AuthWrapper build - isInitializing: $_isInitializing, isInitialized: ${authState.isInitialized}, setupCompleted: $_setupCompleted, isLoggedIn: ${authState.isLoggedIn}, hasValidSession: ${authState.hasValidSession}');

    // Show loading screen while initializing
    if (_isInitializing || !authState.isInitialized) {
      print('DEBUG: AuthWrapper - Still initializing, showing loading screen');
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.security,
                size: 60,
                color: Colors.amber,
              ),
              SizedBox(height: 20),
              Text(
                'Initializing Cred Manager...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    if (!_setupCompleted) {
      // Setup not completed - first time user
      print('DEBUG: AuthWrapper - Setup not completed, showing SetupScreen');
      return const SetupScreen();
    } else if (authState.hasValidSession) {
      // Setup completed and has valid active session
      print('DEBUG: AuthWrapper - Setup completed with valid session, showing MainDashboardScreen');
      return const MainDashboardScreen();
    } else {
      // Setup completed but no valid session - needs to login
      print('DEBUG: AuthWrapper - Setup completed but no valid session, showing LoginScreen');
      return const LoginScreen();
    }
  }
}