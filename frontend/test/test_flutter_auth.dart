import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

// Replicate the Flutter auth service logic
class TestAuthService {
  // Legacy hash method
  String _hashPassphraseLegacy(String passphrase, String salt) {
    final bytes = utf8.encode(passphrase + salt);
    final digest = sha256.convert(bytes);
    return '${digest.toString()}\$salt:$salt';
  }

  // Verify answer (case-insensitive)
  bool _verifyAnswerCaseInsensitive(String answer, String storedHash) {
    // Legacy SHA-256 hash format
    if (!storedHash.contains('\$salt:')) return false;

    final parts = storedHash.split('\$salt:');
    final salt = parts[1];

    // Hash the input answer with the extracted salt (legacy method, lowercase for case-insensitive comparison)
    final hashedInput = _hashPassphraseLegacy(answer.toLowerCase().trim(), salt);

    // Compare the hashes
    return hashedInput == storedHash;
  }

  // Simulate verifyRecoveryAnswers
  Future<bool> verifyRecoveryAnswers(List<Map<String, String>> answers, List<Map<String, String>> storedQuestions) async {
    int correctAnswers = 0;
    
    for (var answer in answers) {
      final question = answer['question'];
      final answerText = answer['answer'];
      
      if (question != null && answerText != null) {
        // Find matching question in stored questions
        final matchingQuestion = storedQuestions.firstWhere(
          (q) => q['question'] == question,
          orElse: () => {'question': '', 'answerHash': ''},
        );
        
        if (matchingQuestion['question'] != '') {
          // Verify answer against stored hash (case-insensitive)
          if (_verifyAnswerCaseInsensitive(answerText, matchingQuestion['answerHash']!)) {
            correctAnswers++;
          }
        }
      }
    }
    
    // All answers must be correct
    final isValid = correctAnswers == answers.length && answers.length == storedQuestions.length;
    return isValid;
  }
}

void main() async {
  print('=== FLUTTER AUTH SERVICE TEST ===\n');
  
  // Initialize SQLite FFI
  sqfliteFfiInit();
  
  // Open database
  final dbPath = '/home/curryman/Documents/APIKeyManager/api_key_manager.db';
  final db = await databaseFactoryFfi.openDatabase(dbPath);
  
  try {
    // Get stored questions
    final results = await db.query('security_questions', orderBy: 'created_at ASC');
    
    final storedQuestions = results.map((row) => {
      'question': row['question'] as String,
      'answerHash': row['encrypted_answer_hash'] as String,
    }).toList();
    
    print('Stored questions:');
    for (int i = 0; i < storedQuestions.length; i++) {
      print('  ${i+1}. ${storedQuestions[i]['question']}');
    }
    print('');
    
    // Your answers
    final userAnswers = [
      {'question': 'What is the name of your first pet?', 'answer': 'gismo'},
      {'question': 'What is your mother\'s maiden name?', 'answer': 'lister'},
      {'question': 'What is the name of the street you grew up on?', 'answer': 'westminister'},
    ];
    
    print('Your answers:');
    for (int i = 0; i < userAnswers.length; i++) {
      print('  ${i+1}. ${userAnswers[i]['answer']}');
    }
    print('');
    
    // Test verification
    final authService = TestAuthService();
    final isValid = await authService.verifyRecoveryAnswers(userAnswers, storedQuestions);
    
    print('Verification result: ${isValid ? 'SUCCESS' : 'FAILED'}');
    
    if (isValid) {
      print('✓ Recovery should work in the Flutter app!');
    } else {
      print('✗ Recovery would fail in the Flutter app.');
    }
    
  } finally {
    await db.close();
  }
}
