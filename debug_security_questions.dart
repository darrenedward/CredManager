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
    print('=== DEBUGGING SECURITY QUESTIONS ===\n');
    
    // Get all security questions from the database
    final results = await db.query('security_questions', orderBy: 'created_at ASC');
    
    if (results.isEmpty) {
      print('No security questions found in the database.');
      return;
    }
    
    print('Found ${results.length} security questions:\n');
    
    for (int i = 0; i < results.length; i++) {
      final row = results[i];
      print('Question ${i + 1}:');
      print('  ID: ${row['id']}');
      print('  Question: ${row['question']}');
      print('  Encrypted Answer Hash: ${row['encrypted_answer_hash']}');
      print('  Is Custom: ${row['is_custom'] == 1 ? 'Yes' : 'No'}');
      print('  Created At: ${DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int)}');
      print('');
    }
    
    print('=== HASH FORMAT ANALYSIS ===\n');
    
    for (int i = 0; i < results.length; i++) {
      final row = results[i];
      final hash = row['encrypted_answer_hash'] as String;
      
      print('Question ${i + 1} Hash Analysis:');
      print('  Hash: $hash');
      
      if (hash.startsWith('\$argon2id\$')) {
        print('  Format: Argon2 hash (modern)');
        final parts = hash.split('\$');
        if (parts.length >= 4) {
          print('  Algorithm: ${parts[1]}');
          print('  Variant: ${parts[2]}');
          print('  Parameters: ${parts[3]}');
        }
      } else if (hash.contains('\$salt:')) {
        print('  Format: Legacy SHA-256 with salt');
        final parts = hash.split('\$salt:');
        if (parts.length == 2) {
          print('  Hash part: ${parts[0]}');
          print('  Salt: ${parts[1]}');
        }
      } else {
        print('  Format: Unknown or plain text');
      }
      print('');
    }
    
    print('=== ANSWER TESTING GUIDE ===\n');
    print('To test your answers:');
    print('1. For Argon2 hashes: The system will hash your answer using Argon2 and compare');
    print('2. For legacy hashes: The system will hash your answer with SHA-256 + salt and compare');
    print('3. All comparisons are case-insensitive (converted to lowercase)');
    print('4. Leading/trailing whitespace is trimmed');
    print('\nTry entering your answers exactly as you remember them during recovery.');
    
  } catch (e) {
    print('Error reading database: $e');
  } finally {
    await db.close();
  }
}
