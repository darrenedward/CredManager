import 'package:flutter/material.dart';
import '../widgets/auth_form.dart';
import '../services/auth_service.dart';
import '../utils/validation.dart';
import '../utils/constants.dart';
import 'login_screen.dart';

class ResetPassphraseScreen extends StatefulWidget {
  final String recoveryToken;
  
  const ResetPassphraseScreen({super.key, required this.recoveryToken});

  @override
  State<ResetPassphraseScreen> createState() => _ResetPassphraseScreenState();
}

class _ResetPassphraseScreenState extends State<ResetPassphraseScreen> {
  final _passphraseController = TextEditingController();
  final _confirmPassphraseController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passphraseController.dispose();
    _confirmPassphraseController.dispose();
    super.dispose();
  }

  Future<void> _resetPassphrase() async {
    // Validate passphrase
    final passphraseError = validatePassphraseError(_passphraseController.text);
    final confirmError = validateConfirmPassphraseError(
      _passphraseController.text,
      _confirmPassphraseController.text,
    );
    
    if (passphraseError != null) {
      _showError(passphraseError);
      return;
    }
    
    if (confirmError != null) {
      _showError(confirmError);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Reset passphrase using recovery token
      final token = await _authService.resetPassphrase(
        widget.recoveryToken,
        _passphraseController.text,
      );
      
      if (mounted) {
        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passphrase reset successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to login screen with auto-login
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => token != null 
                    ? LoginScreen(autoLoginToken: token) 
                    : const LoginScreen(),
              ),
            );
          }
        });
      }
    } catch (e) {
      // Secure error handling - generic messages
      _showError('Failed to reset passphrase. Please try again.');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Passphrase'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_reset,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 20),
            const Text(
              'Create New Passphrase',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Enter your new secure passphrase'),
            const SizedBox(height: 30),
            AuthForm(
              title: 'New Passphrase',
              controller: _passphraseController,
              confirmController: _confirmPassphraseController,
              isSetup: true, // Use setup mode for confirmation
              onSubmit: _resetPassphrase,
              isLoading: _isLoading,
              errorMessage: _errorMessage,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Back to Login'),
            ),
          ],
        ),
      ),
    );
  }
}