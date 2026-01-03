import 'package:flutter/material.dart';
import '../widgets/progress_indicator.dart';
import '../widgets/auth_form.dart';
import '../widgets/security_questions.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/biometric_auth_service.dart';
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
  final BiometricAuthService _biometricService = BiometricAuthService();
  int _currentStep = 0;
  bool _isLoading = false;
  String? _error;

  // Migration prompt state
  String? _migrationMessage;
  bool _showMigrationPrompt = false;

  // Biometric setup state
  bool _biometricAvailable = false;
  bool _enableBiometric = false;
  String _biometricType = 'Biometric';

  // Selected predefined questions
  final List<String?> _selectedQuestions = List.filled(3, null);

  // Controllers for answers
  final List<TextEditingController> _answerControllers = [];

  @override
  void initState() {
    super.initState();
    // Initialize answer controllers for custom questions only
    _updateAnswerControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkMigrationPrompt();
      await _checkBiometricAvailability();
    });
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

  Future<void> _checkBiometricAvailability() async {
    try {
      final isAvailable = await _biometricService.isBiometricAvailable();
      if (isAvailable) {
        final biometricType = await _biometricService.getPrimaryBiometricType();
        setState(() {
          _biometricAvailable = true;
          _biometricType = biometricType;
        });
      } else {
        setState(() {
          _biometricAvailable = false;
          _biometricType = 'Biometric';
        });
      }
    } catch (e) {
      setState(() {
        _biometricAvailable = false;
        _biometricType = 'Biometric';
      });
    }
  }

  void _updateAnswerControllers() {
    // Clear existing controllers
    for (var controller in _answerControllers) {
      controller.dispose();
    }
    _answerControllers.clear();

    // Create controllers for selected questions
    final totalQuestions = _selectedQuestions.where((q) => q != null && q.isNotEmpty).length;
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
        // Check that we have selected 3 questions
        final totalQuestions = _selectedQuestions.where((q) => q != null && q.isNotEmpty).length;

        if (totalQuestions < 3) {
          _setError('Please select 3 security questions');
          return false;
        }

        // Check that answers for all selected questions are provided
        int answerIndex = 0;
        for (int i = 0; i < _selectedQuestions.length; i++) {
          if (_selectedQuestions[i] != null && _selectedQuestions[i]!.isNotEmpty) {
            final answerError = validateAnswerError(_answerControllers[answerIndex].text);
            if (answerError != null) {
              _setError('Answer for question ${i + 1}: $answerError');
              return false;
            }
            answerIndex++;
          }
        }

        return true;

      case 2: // Biometric setup step (only if available)
        if (_biometricAvailable) {
          // No validation needed for biometric step - it's optional
          return true;
        }
        return true; // Skip if not available

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

      // Prepare security questions data
      final List<Map<String, String>> securityQuestions = [];

      // Add selected questions
      print('Adding ${_selectedQuestions.length} selected questions');
      int answerIndex = 0;
      for (int i = 0; i < _selectedQuestions.length; i++) {
        if (_selectedQuestions[i] != null && _selectedQuestions[i]!.isNotEmpty) {
          final question = _selectedQuestions[i]!;
          final answer = _answerControllers[answerIndex].text;
          print('Adding question $i: $question with answer: $answer');
          securityQuestions.add({
            'question': question,
            'answer': answer,
            'isCustom': 'false',
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
        // Handle biometric setup if enabled
        if (_enableBiometric && _biometricAvailable) {
          print('Setting up biometric authentication');
          try {
            await _biometricService.setBiometricEnabled(true);
            print('Biometric authentication enabled successfully');
          } catch (e) {
            print('Error setting up biometric: $e');
            // Don't fail setup for biometric issues
          }
        }

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
      if (index >= 0 && index < _selectedQuestions.length) {
        _selectedQuestions[index] = value.isEmpty ? null : value;
        _updateAnswerControllers(); // Update controllers when questions change
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

            // Migration prompt UI
            if (_showMigrationPrompt && _migrationMessage != null) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
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
                  final totalSteps = _biometricAvailable ? 4 : 3;
                  setState(() {
                    // Ensure step is within valid range
                    if (step >= 0 && step < totalSteps) {
                      _currentStep = step;
                    }
                  });
                },
                controlsBuilder: (context, details) {
                  final totalSteps = _biometricAvailable ? 4 : 3;
                  final isFinalStep = _currentStep == totalSteps - 1;

                  // Customize controls for the final step
                  if (isFinalStep) {
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
                  // Default controls for other steps
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
                     title: const Text('Select Security Questions'),
                     content: _buildSecurityQuestionsStep(),
                     isActive: _currentStep == 1,
                     state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                     subtitle: _currentStep == 1 ? const Text('Select predefined questions') : null,
                   ),
                   if (_biometricAvailable) ...[
                     Step(
                       title: Text('Setup $_biometricType'),
                       content: _buildBiometricSetupStep(),
                       isActive: _currentStep == 2,
                       state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                       subtitle: _currentStep == 2 ? const Text('Optional convenience feature') : null,
                     ),
                   ],
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
                         if (_biometricAvailable && _enableBiometric) ...[
                           const SizedBox(height: 20),
                           Text(
                             '$_biometricType authentication has been enabled for quick unlock after passphrase login.',
                             textAlign: TextAlign.center,
                             style: TextStyle(fontSize: 14, color: Colors.green[700]),
                           ),
                         ],
                         const SizedBox(height: 20),
                         const Text(
                           'Click "Finalize Setup" to complete your account configuration and proceed to the dashboard.',
                           textAlign: TextAlign.center,
                           style: TextStyle(fontSize: 14, color: Colors.grey),
                         ),
                       ],
                     ),
                     isActive: _currentStep == (_biometricAvailable ? 3 : 2),
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
    // Create security questions list
    final List<SecurityQuestion> questions = List.generate(3, (i) => SecurityQuestion(question: _selectedQuestions[i] ?? '', isCustom: false));

    const List<String> predefinedQuestions = [
      'What street did you grow up on?',
      'What was the name of your first school?',
      'What is your favorite color?',
      'What is your mother\'s maiden name?',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select 3 security questions from the dropdowns:',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 15),

        SecurityQuestionsWidget(
          questions: questions,
          answerControllers: _answerControllers,
          isLoading: _isLoading,
          onCustomQuestionChanged: _onCustomQuestionChanged,
          predefinedQuestions: predefinedQuestions,
        ),

        const SizedBox(height: 10),
        const Text(
          'Note: You must select 3 different questions and provide answers for each.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildBiometricSetupStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enable $_biometricType for Quick Unlock',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _biometricType == 'Face ID' ? Icons.face : Icons.fingerprint,
                    color: Colors.blue[700],
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$_biometricType Available',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Your device supports biometric authentication. You can enable it for quick unlock after entering your passphrase.',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Enable $_biometricType for quick unlock?',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Switch(
                    value: _enableBiometric,
                    onChanged: (value) {
                      setState(() {
                        _enableBiometric = value;
                      });
                    },
                    activeColor: Colors.blue[700],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Note: Your passphrase remains the primary security method. Biometric authentication is only used for convenience after successful passphrase login.',
                style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_enableBiometric) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700]),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$_biometricType will be enabled for quick unlock after setup completion.',
                    style: TextStyle(color: Colors.green[700]),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[600]),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$_biometricType will not be enabled. You can enable it later in Settings.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}