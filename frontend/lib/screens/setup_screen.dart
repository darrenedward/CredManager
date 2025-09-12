import 'package:flutter/material.dart';
import '../widgets/progress_indicator.dart';
import '../widgets/auth_form.dart';
import '../widgets/security_questions.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../utils/validation.dart';
import '../utils/constants.dart';
import 'setup_success_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _passphraseController = TextEditingController();
  final _confirmPassphraseController = TextEditingController();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  int _currentStep = 0;
  bool _isLoading = false;
  String? _error;

  
  // Custom questions (optional)
  final List<String> _customQuestions = ['', ''];

  // Controllers for answers
  final List<TextEditingController> _answerControllers = [];

  @override
  void initState() {
    super.initState();
    // Initialize answer controllers for custom questions only
    _updateAnswerControllers();
  }

  void _updateAnswerControllers() {
    // Clear existing controllers
    for (var controller in _answerControllers) {
      controller.dispose();
    }
    _answerControllers.clear();

    // Create controllers for custom questions only
    final totalQuestions = _customQuestions.where((q) => q.trim().isNotEmpty).length;
    _answerControllers.addAll(List.generate(totalQuestions, (_) => TextEditingController()));
  }

  @override
  void dispose() {
    _passphraseController.dispose();
    _confirmPassphraseController.dispose();
    for (var controller in _answerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _nextStep() {
    if (_validateStep()) {
      setState(() {
        _currentStep++;
      });
    }
  }

  bool _validateStep() {
    switch (_currentStep) {
      case 0: // Passphrase step
        final passphraseError = validatePassphraseError(_passphraseController.text);
        final confirmError = validateConfirmPassphraseError(
          _passphraseController.text,
          _confirmPassphraseController.text,
        );
        
        if (passphraseError != null) {
          _setError(passphraseError);
          return false;
        }
        
        if (confirmError != null) {
          _setError(confirmError);
          return false;
        }
        
        return true;
        
      case 1: // Security questions step
        // Check that we have at least 3 custom questions with content
        final totalQuestions = _customQuestions.where((q) => q.trim().isNotEmpty).length;

        if (totalQuestions < 3) {
          _setError('Please create at least 3 custom security questions');
          return false;
        }

        // Check that custom questions are valid (minimum 10 characters)
        for (int i = 0; i < _customQuestions.length; i++) {
          if (_customQuestions[i].trim().isNotEmpty) {
            if (_customQuestions[i].trim().length < 10) {
              _setError('Custom question ${i + 1} must be at least 10 characters');
              return false;
            }
          }
        }

        // Check that answers for all custom questions are provided
        int answerIndex = 0;
        for (int i = 0; i < _customQuestions.length; i++) {
          if (_customQuestions[i].trim().isNotEmpty) {
            final answerError = validateAnswerError(_answerControllers[answerIndex].text);
            if (answerError != null) {
              _setError('Answer for custom question ${i + 1}: $answerError');
              return false;
            }
            answerIndex++;
          }
        }

        return true;
        
      default:
        return true;
    }
  }

  void _setError(String error) {
    setState(() {
      _error = error;
    });
    
    // Clear error after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _error = null;
        });
      }
    });
  }

  Future<void> _completeSetup() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('Starting setup completion process');
      
      // Prepare security questions data (custom questions only)
      final List<Map<String, String>> securityQuestions = [];

      // Add custom questions (only those with content)
      print('Adding ${_customQuestions.length} custom questions');
      int answerIndex = 0;
      for (int i = 0; i < _customQuestions.length; i++) {
        if (_customQuestions[i].trim().isNotEmpty) {
          final question = _customQuestions[i];
          final answer = _answerControllers[answerIndex].text;
          print('Adding custom question $i: $question with answer: $answer');
          securityQuestions.add({
            'question': question,
            'answer': answer,
            'isCustom': 'true',
          });
          answerIndex++;
        }
      }
      
      print('Total security questions to store: ${securityQuestions.length}');

      // Create passphrase and get JWT token for automatic login
      print('Calling createPassphrase with passphrase: ${_passphraseController.text}');
      final token = await _authService.createPassphrase(
        _passphraseController.text,
        securityQuestions,
      );
      print('Received token from createPassphrase: $token');

      if (token != null && mounted) {
        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Setup completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Small delay to show the success message before navigating
        await Future.delayed(const Duration(seconds: 2));
        
        // Navigate to the setup success screen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const SetupSuccessScreen(),
            ),
          );
        }
      } else {
        print('Token was null or context not mounted');
      }
    } catch (e, stackTrace) {
      print('Error in _completeSetup: $e');
      print('Stack trace: $stackTrace');
      
      // Secure error handling - generic messages
      if (mounted) {
        setState(() {
          _error = 'Setup failed. Please try again.';
        });
        
        // Show error feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Setup failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onCustomQuestionChanged(int index, String value) {
    setState(() {
      if (index >= 0 && index < _customQuestions.length) {
        _customQuestions[index] = value;
        _updateAnswerControllers(); // Update controllers when custom questions change
      }
    });
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
          children: [
            SetupProgressIndicator(currentStep: _currentStep),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
              ),
            ],
            const SizedBox(height: 20),
            Expanded(
              child: Stepper(
                currentStep: _currentStep,
                onStepContinue: _nextStep,
                onStepCancel: _currentStep > 0 
                  ? () => setState(() => _currentStep--) 
                  : null,
                onStepTapped: (step) {
                  setState(() {
                    // Ensure step is within valid range (0 to 2)
                    if (step >= 0 && step < 3) {
                      _currentStep = step;
                    }
                  });
                },
                controlsBuilder: (context, details) {
                  // Customize controls for the final step
                  if (_currentStep == 2) {
                    return Row(
                      children: [
                        if (_currentStep > 0)
                          TextButton(
                            onPressed: details.onStepCancel,
                            child: const Text('Back'),
                          ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _completeSetup,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Finalize Setup'),
                        ),
                      ],
                    );
                  }
                  // Security questions step - use Preview instead of Continue
                  else if (_currentStep == 1) {
                    return Row(
                      children: [
                        if (details.onStepCancel != null)
                          TextButton(
                            onPressed: details.onStepCancel,
                            child: const Text('Back'),
                          ),
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: details.onStepContinue,
                          child: const Text('Preview'),
                        ),
                      ],
                    );
                  }
                  // Default controls for other steps (passphrase step)
                  return Row(
                    children: [
                      if (details.onStepCancel != null)
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Back'),
                        ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Continue'),
                      ),
                    ],
                  );
                },
                steps: [
                  Step(
                    title: const Text('Create Passphrase'),
                    content: AuthForm(
                      title: 'Create your secure passphrase',
                      controller: _passphraseController,
                      confirmController: _confirmPassphraseController,
                      isSetup: true,
                      isLoading: _isLoading,
                    ),
                    isActive: _currentStep == 0,
                    state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                  ),
                  Step(
                    title: const Text('Create Security Questions'),
                    content: _buildSecurityQuestionsStep(),
                    isActive: _currentStep == 1,
                    state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                    subtitle: _currentStep == 1 ? const Text('Create custom questions') : null,
                  ),
                  Step(
                    title: const Text('Complete'),
                    content: Column(
                      children: [
                        const Text(
                          'Please keep your passphrase safe and secure.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Your passphrase is the only way to access your account. If you forget it, you\'ll need to use your security questions to recover it.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Click "Finalize Setup" to complete your account configuration and proceed to the dashboard.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                    isActive: _currentStep == 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityQuestionsStep() {
    // Create security questions list: custom questions only
    final List<SecurityQuestion> questions = _customQuestions
        .where((q) => q.trim().isNotEmpty)
        .map((q) => SecurityQuestion(question: q, isCustom: true))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Create at least 3 custom security questions:',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 15),

        // Custom questions only
        const Text('Custom Security Questions (required):', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        SecurityQuestionsWidget(
          questions: questions,
          answerControllers: _answerControllers,
          isLoading: _isLoading,
          onCustomQuestionChanged: _onCustomQuestionChanged,
        ),

        const SizedBox(height: 10),
        const Text(
          'Note: You must create at least 3 custom security questions. Each question must be at least 10 characters long.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}