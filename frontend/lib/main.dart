import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/setup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/recovery_screen.dart';
import 'screens/reset_passphrase_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/main_dashboard_screen.dart';
import 'models/auth_state.dart';
import 'utils/constants.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthState(),
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
        primaryColor: AppConstants.primaryColor,
        primarySwatch: const MaterialColor(
          0xFF0f172a,
          <int, Color>{
            50: Color(0xFFF1F5F9),
            100: Color(0xFFE2E8F0),
            200: Color(0xFFCBD5E1),
            300: Color(0xFF94A3B8),
            400: Color(0xFF64748B),
            500: Color(0xFF0f172a),
            600: Color(0xFF0F172A),
            700: Color(0xFF0F172A),
            800: Color(0xFF0F172A),
            900: Color(0xFF0F172A),
          },
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/setup': (context) => const SetupScreen(),
        '/login': (context) => const LoginScreen(),
        '/recovery': (context) => const RecoveryScreen(),
        '/reset-passphrase': (context) => const ResetPassphraseScreen(recoveryToken: ''),
        '/settings': (context) => const SettingsScreen(),
        '/dashboard': (context) => const MainDashboardScreen(),
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