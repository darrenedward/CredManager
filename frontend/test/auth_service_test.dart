import 'package:flutter_test/flutter_test.dart';
import 'package:api_key_manager/services/auth_service.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthService authService;

  setUp(() {
    // Mock method channels for flutter_secure_storage
    const MethodChannel secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      secureStorageChannel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'read':
            return null; // Return null for reads in tests
          case 'write':
            return null; // Mock successful write
          case 'delete':
            return null; // Mock successful delete
          case 'deleteAll':
            return null; // Mock successful deleteAll
          default:
            return null;
        }
      },
    );

    // Mock method channels for shared_preferences
    const MethodChannel sharedPrefsChannel = MethodChannel('plugins.flutter.io/shared_preferences');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      sharedPrefsChannel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getAll':
            return {}; // Return empty map for getAll
          case 'setBool':
            return true; // Mock successful setBool
          case 'setString':
            return true; // Mock successful setString
          case 'remove':
            return true; // Mock successful remove
          case 'clear':
            return true; // Mock successful clear
          default:
            return null;
        }
      },
    );

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