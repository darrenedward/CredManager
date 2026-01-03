import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../widgets/auth_form.dart';
import '../services/auth_service.dart';
import '../services/biometric_auth_service.dart';
import '../models/auth_state.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import '../utils/validation.dart';

class LoginScreen extends StatefulWidget {
  final String? autoLoginToken;
  
  const LoginScreen({super.key, this.autoLoginToken});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _passphraseController = TextEditingController();
  final AuthService _authService = AuthService();
  final BiometricAuthService _biometricService = BiometricAuthService();
  bool _isLoading = false;
  String? _errorMessage;

  // Migration prompt state
  String? _migrationMessage;
  bool _showMigrationPrompt = false;


  @override
  void initState() {
    super.initState();
    // If we have an auto-login token, attempt to log in automatically
    if (widget.autoLoginToken != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoLogin(widget.autoLoginToken!);
      });
    } else {
      // Check migration status and biometric login availability
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _checkMigrationPrompt();
        _checkBiometricAutoLogin();
      });
    }
  }

  Future<void> _checkMigrationPrompt() async {
    try {
      final status = await _authService.checkMigrationStatus();
      if (status['needsMigration'] == true && status['message'] != null) {
        setState(() {
          _migrationMessage = status['message'];
          _showMigrationPrompt = true;
        });
      } else {
        setState(() {
          _migrationMessage = null;
          _showMigrationPrompt = false;
        });
      }
    } catch (e) {
      setState(() {
        _migrationMessage = null;
        _showMigrationPrompt = false;
      });
    }
  }

  Future<void> _checkBiometricAutoLogin() async {
    try {
      final isAvailable = await _biometricService.isBiometricAvailable();
      final isEnabled = await _biometricService.isBiometricEnabled();
      
      if (isAvailable && isEnabled) {
        // Don't auto-trigger, just make the option available
        // User can tap the biometric button if they want to use it
        setState(() {
          // This will trigger a rebuild to show the biometric button
        });
      }
    } catch (e) {
      // Silently fail, user can still use regular login
      print('DEBUG: Error checking biometric availability: $e');
    }
  }

  @override
  void dispose() {
    _passphraseController.dispose();
    super.dispose();
  }

  Future<void> _autoLogin(String token) async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('DEBUG: Starting auto-login process');
      final authState = Provider.of<AuthState>(context, listen: false);
      await authState.autoLogin(token);

      if (mounted) {
        print('DEBUG: Auto-login successful');
        _showSuccess('Welcome back!');
        // AuthWrapper will automatically navigate to dashboard due to state change
      }
    } catch (e) {
      print('DEBUG: Auto-login failed: $e');
      if (mounted) {
        _showError('Auto-login failed. Please log in manually.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _biometricLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('DEBUG: Starting biometric login');
      final authState = Provider.of<AuthState>(context, listen: false);
      
      final success = await authState.performBiometricQuickUnlock();
      
      if (success) {
        print('DEBUG: Biometric login successful');
        _showSuccess('Biometric login successful!');
        // AuthWrapper will automatically navigate to dashboard due to state change
      } else {
        print('DEBUG: Biometric login failed');
        // Error message is already set in AuthState
      }
    } catch (e) {
      print('DEBUG: Biometric login error: $e');
      _showError('Biometric authentication failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _login() async {
    // Validate passphrase using validation utility
    final validationError = validatePassphraseError(_passphraseController.text);
    if (validationError != null) {
      _showError(validationError);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('DEBUG: Starting login process via AuthState');
      final authState = Provider.of<AuthState>(context, listen: false);
      await authState.login(_passphraseController.text);

      if (mounted) {
        // Check if login was actually successful by verifying auth state
        if (authState.hasValidSession) {
          print('DEBUG: Login successful - hasValidSession: true');
          _showSuccess('Welcome back!');
          // AuthWrapper will automatically navigate to dashboard due to state change
        } else {
          print('DEBUG: Login failed - hasValidSession: false, error: ${authState.error}');
          _showError(authState.error ?? 'Login failed. Please try again.');
        }
      }
    } catch (e) {
      // Secure error handling - generic messages
      print('DEBUG: Login failed with exception: $e');
      if (mounted) {
        _showError('Login failed. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
    
    // Show snackbar with error
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.security,
                  size: 32,
                  color: AppConstants.accentColor,
                ),
                const SizedBox(width: 12),
                Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Migration prompt UI
            if (_showMigrationPrompt && _migrationMessage != null) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.yellow[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.yellow[700]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.upgrade, color: Colors.orange[800], size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _migrationMessage!,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Text(
              'Welcome back',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Enter your passphrase to continue'),
            const SizedBox(height: 30),
            AuthForm(
              title: 'Passphrase',
              controller: _passphraseController,
              isSetup: false,
              onSubmit: _login,
              isLoading: _isLoading,
              errorMessage: _errorMessage,
            ),
            const SizedBox(height: 20),
            
            // Biometric authentication button removed for PT006
            
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/recovery');
              },
              child: const Text('Forgot Passphrase?'),
            ),
          ],
        ),
      ),
    );
  }
}