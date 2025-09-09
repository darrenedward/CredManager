import 'package:flutter_test/flutter_test.dart';
import 'package:api_key_manager/services/jwt_service.dart';

void main() {
  group('JwtService', () {
    test('generateToken and verifyToken work correctly', () {
      final payload = {
        'sub': 'test_user',
        'iss': 'test_issuer',
      };
      final secret = 'test_secret';
      
      final token = JwtService.generateToken(payload, secret);
      expect(token, isNotNull);
      expect(token, isNotEmpty);
      
      final isValid = JwtService.verifyToken(token, secret);
      expect(isValid, isTrue);
    });
    
    test('verifyToken fails with wrong secret', () {
      final payload = {
        'sub': 'test_user',
        'iss': 'test_issuer',
      };
      final secret = 'test_secret';
      final wrongSecret = 'wrong_secret';
      
      final token = JwtService.generateToken(payload, secret);
      final isValid = JwtService.verifyToken(token, wrongSecret);
      expect(isValid, isFalse);
    });
    
    test('isTokenExpired works correctly', () {
      final payload = {
        'sub': 'test_user',
        'iss': 'test_issuer',
        'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 - 3600, // 1 hour ago
      };
      final secret = 'test_secret';
      
      final token = JwtService.generateToken(payload, secret);
      final isExpired = JwtService.isTokenExpired(token);
      expect(isExpired, isTrue);
    });
  });
}