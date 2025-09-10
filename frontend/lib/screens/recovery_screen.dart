import 'package:flutter/material.dart';
import '../widgets/security_questions.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../utils/validation.dart';
import '../utils/constants.dart';
import 'login_screen.dart';
import 'reset_passphrase_screen.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  bool _isLoading = false;
  String? _errorMessage;
  List<String> _selectedQuestions = [];
  List<TextEditingController> _answerControllers = [];
  String? _recoveryToken;

  @override
  void initState() {
    super.initState();
    _loadRecoveryQuestions();
  }

  @override
  void dispose() {
    for (var controller in _answerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadRecoveryQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get recovery questions (with random ordering)
      final questions = await _authService.initiateRecovery();
      
      if (questions != null && questions.isNotEmpty && mounted) {
        setState(() {
          _selectedQuestions = questions;
          _answerControllers = List.generate(questions.length, (index) => TextEditingController());
        });
      } else if (mounted) {
        setState(() {
          _errorMessage = 'No security questions found. Please contact support.';
        });
      }
    } catch (e) {
      // Secure error handling - generic messages
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load recovery questions. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyAnswers() async {
    if (_validateAnswers()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Prepare answers for verification
        final answers = <Map<String, String>>[];
        for (int i = 0; i < _selectedQuestions.length; i++) {
          answers.add({
            'question': _selectedQuestions[i],
            'answer': _answerControllers[i].text,
          });
        }
        
        // Verify answers
        final isValid = await _authService.verifyRecoveryAnswers(answers);
        
        if (isValid && mounted) {
          // Request recovery token
          final token = await _authService.requestRecoveryToken();
          
          if (token != null && mounted) {
            // Show success feedback and navigate to reset passphrase screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Answers verified successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            
            // Navigate to reset passphrase screen
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResetPassphraseScreen(recoveryToken: token),
                  ),
                );
              }
            });
          } else if (mounted) {
            setState(() {
              _errorMessage = 'Failed to process recovery. Please try again.';
            });
          }
        } else if (mounted) {
          setState(() {
            _errorMessage = 'Invalid answers. Please try again.';
          });
        }
      } catch (e) {
        // Secure error handling - generic messages
        if (mounted) {
          setState(() {
            _errorMessage = e.toString().contains('lockout') 
                ? e.toString() 
                : 'Verification failed. Please try again.';
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  bool _validateAnswers() {
    // Validate answers using utils/validation.dart
    for (var controller in _answerControllers) {
      final answerError = validateAnswerError(controller.text);
      if (answerError != null) {
        setState(() {
          _errorMessage = answerError;
        });
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Passphrase Recovery'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.security,
              size: 80,
              color: AppConstants.accentColor,
            ),
            const SizedBox(height: 20),
            const Text(
              'Security Questions',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Answer the following questions to recover your passphrase'),
            const SizedBox(height: 30),
            if (_isLoading && _selectedQuestions.isEmpty) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
            ] else if (_selectedQuestions.isNotEmpty) ...[
              SecurityQuestionsWidget(
                questions: _selectedQuestions.map((q) => SecurityQuestion(question: q, isCustom: false)).toList(),
                answerControllers: _answerControllers,
                isRecovery: true,
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading || _selectedQuestions.isEmpty ? null : _verifyAnswers,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Verify Answers'),
            ),
            const SizedBox(height: 10),
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