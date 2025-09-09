import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/auth_form.dart';
import '../services/auth_service.dart';
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
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // If we have an auto-login token, attempt to log in automatically
    if (widget.autoLoginToken != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoLogin(widget.autoLoginToken!);
      });
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
        print('DEBUG: AuthState login completed successfully');
        _showSuccess('Login successful!');
        // AuthWrapper will automatically navigate to dashboard due to state change
      }
    } catch (e) {
      // Secure error handling - generic messages
      print('DEBUG: Login failed with error: $e');
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
            const Icon(
              Icons.lock_outline,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
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