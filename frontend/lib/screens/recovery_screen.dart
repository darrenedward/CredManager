import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/security_questions.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/emergency_backup_service.dart';
import '../utils/validation.dart';
import '../utils/constants.dart';
import 'login_screen.dart';
import 'reset_passphrase_screen.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final EmergencyBackupService _backupService = EmergencyBackupService();

  late TabController _tabController;

  bool _isLoading = false;
  String? _errorMessage;

  // Security questions state
  List<String> _selectedQuestions = [];
  List<TextEditingController> _answerControllers = [];
  String? _recoveryToken;

  // Emergency backup code state
  final TextEditingController _backupCodeController = TextEditingController();
  bool _hasBackupCode = false;
  bool _backupCodeUsed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRecoveryQuestions();
    _checkBackupCodeStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var controller in _answerControllers) {
      controller.dispose();
    }
    _backupCodeController.dispose();
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

  Future<void> _checkBackupCodeStatus() async {
    final hasCode = await _backupService.hasBackupCode();
    final wasUsed = await _backupService.wasBackupCodeUsed();

    setState(() {
      _hasBackupCode = hasCode;
      _backupCodeUsed = wasUsed;
    });
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

  Future<void> _verifyBackupCode() async {
    final backupCode = _backupCodeController.text.trim();

    if (backupCode.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your backup code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Verify the backup code
      final isValid = await _backupService.verifyBackupCode(backupCode);

      if (isValid && mounted) {
        // Mark the backup code as used (one-time use)
        await _backupService.markBackupCodeAsUsed();

        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup code verified! You can now reset your passphrase.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to reset passphrase screen
        final token = await _authService.requestRecoveryToken();
        if (token != null && mounted) {
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
          _errorMessage = 'Invalid backup code. Please check and try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Verification failed. Please try again.';
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Security Questions', icon: Icon(Icons.help_outline)),
            Tab(text: 'Emergency Code', icon: Icon(Icons.vpn_key)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSecurityQuestionsTab(),
          _buildBackupCodeTab(),
        ],
      ),
    );
  }

  Widget _buildSecurityQuestionsTab() {
    return Padding(
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
    );
  }

  Widget _buildBackupCodeTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.vpn_key,
            size: 80,
            color: AppConstants.accentColor,
          ),
          const SizedBox(height: 20),
          const Text(
            'Emergency Backup Code',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text('Enter your emergency backup code to recover your passphrase'),
          const SizedBox(height: 30),

          // Status indicator
          if (!_hasBackupCode) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border.all(color: Colors.orange[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700]),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'No emergency backup code has been generated for this account. Please use security questions to recover.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ] else if (_backupCodeUsed) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'The emergency backup code has already been used. Please generate a new one or use security questions.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          if (_hasBackupCode && !_backupCodeUsed) ...[
            TextField(
              controller: _backupCodeController,
              decoration: const InputDecoration(
                labelText: 'Emergency Backup Code',
                hintText: 'Enter your 24-word phrase or Base32 code',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.code),
              ),
              maxLines: 3,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _verifyBackupCode,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.verify),
              label: const Text('Verify Backup Code'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: AppConstants.accentColor,
              ),
            ),

            const SizedBox(height: 20),

            // Paste button
            OutlinedButton.icon(
              onPressed: _isLoading ? null : () async {
                final clipboard = await Clipboard.getData('text.clipboard');
                if (clipboard?.text?.isNotEmpty == true) {
                  _backupCodeController.text = clipboard!.text!;
                }
              },
              icon: const Icon(Icons.paste),
              label: const Text('Paste from Clipboard'),
            ),
          ],

          if (_errorMessage != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 30),

          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Back to Login'),
          ),
        ],
      ),
    );
  }
}