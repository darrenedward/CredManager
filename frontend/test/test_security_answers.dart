import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

void main() async {
  // Initialize SQLite FFI for desktop
  sqfliteFfiInit();
  
  // Open the database
  final dbPath = '/home/curryman/Documents/APIKeyManager/api_key_manager.db';
  final db = await databaseFactoryFfi.openDatabase(dbPath);
  
  try {
    print('=== SECURITY QUESTIONS TESTER ===\n');
    
    // Get all security questions from the database
    final results = await db.query('security_questions', orderBy: 'created_at ASC');
    
    if (results.isEmpty) {
      print('No security questions found in the database.');
      return;
    }
    
    print('Found ${results.length} security questions.\n');
    
    // Test each question
    for (int i = 0; i < results.length; i++) {
      final row = results[i];
      final question = row['question'] as String;
      final storedHash = row['encrypted_answer_hash'] as String;
      final isCustom = (row['is_custom'] as int) == 1;
      
      print('Question ${i + 1} ${isCustom ? '(Custom)' : '(Predefined)'}:');
      print('$question\n');
      
      // Prompt for answer
      stdout.write('Enter your answer: ');
      final userAnswer = stdin.readLineSync() ?? '';
      
      // Test the answer
      final isCorrect = await testAnswer(userAnswer, storedHash);
      
      if (isCorrect) {
        print('✓ CORRECT! This answer matches the stored hash.\n');
      } else {
        print('✗ INCORRECT. This answer does not match the stored hash.');
        print('  Stored hash: $storedHash');
        print('  Hash format: ${getHashFormat(storedHash)}\n');
      }
      
      print('─' * 50);
    }
    
  } catch (e) {
    print('Error: $e');
  } finally {
    await db.close();
  }
}

Future<bool> testAnswer(String answer, String storedHash) async {
  // Normalize the answer (case-insensitive, trimmed)
  final normalizedAnswer = answer.toLowerCase().trim();
  
  if (storedHash.startsWith('\$argon2id\$')) {
    // Argon2 hash - would need the actual Argon2 library to verify
    print('  Note: Argon2 hash verification requires the Flutter environment');
    return false;
  } else if (storedHash.contains('\$salt:')) {
    // Legacy SHA-256 hash format
    final parts = storedHash.split('\$salt:');
    if (parts.length != 2) return false;
    
    final expectedHash = parts[0];
    final salt = parts[1];
    
    // Hash the normalized answer with the salt
    final key = utf8.encode(normalizedAnswer + salt);
    final digest = sha256.convert(key);
    final computedHash = digest.toString() + '\$salt:' + salt;
    
    return computedHash == storedHash;
  }
  
  return false;
}

String getHashFormat(String hash) {
  if (hash.startsWith('\$argon2id\$')) {
    return 'Argon2 (modern, secure)';
  } else if (hash.contains('\$salt:')) {
    return 'SHA-256 with salt (legacy)';
  } else {
    return 'Unknown format';
  }
}
