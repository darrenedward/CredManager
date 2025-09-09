import 'package:flutter_test/flutter_test.dart';
import 'package:api_key_manager/services/auth_service.dart';

void main() {
  late AuthService authService;

  setUp(() {
    // We'll test the AuthService methods directly since they're now local
    authService = AuthService();
  });

  test('createPassphrase succeeds', () async {
    final token = await authService.createPassphrase('ValidPass123', [
      {'question': 'What is your favorite color?', 'answerHash': 'hash1'},
      {'question': 'What was your first pet?', 'answerHash': 'hash2'}
    ]);
    expect(token, isNotNull);
    expect(token, isA<String>());
  });

  test('login succeeds with valid passphrase', () async {
    // First create a passphrase to test login
    await authService.createPassphrase('ValidPass123', [
      {'question': 'What is your favorite color?', 'answerHash': 'hash1'},
      {'question': 'What was your first pet?', 'answerHash': 'hash2'}
    ]);
    
    final token = await authService.login('ValidPass123');
    expect(token, isNotNull);
    expect(token, isA<String>());
  });

  test('initiateRecovery returns questions', () async {
    // First create security questions
    await authService.createPassphrase('ValidPass123', [
      {'question': 'What is your favorite color?', 'answerHash': 'hash1'},
      {'question': 'What was your first pet?', 'answerHash': 'hash2'}
    ]);
    
    final questions = await authService.initiateRecovery();
    expect(questions, isNotNull);
    expect(questions, isA<List<String>>());
  });

  test('verifyToken succeeds with valid token', () async {
    final token = await authService.createPassphrase('ValidPass123', [
      {'question': 'What is your favorite color?', 'answerHash': 'hash1'},
      {'question': 'What was your first pet?', 'answerHash': 'hash2'}
    ]);
    
    final result = await authService.verifyToken(token!);
    expect(result, true);
  });
}