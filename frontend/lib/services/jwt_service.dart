import 'package:jwt_decode/jwt_decode.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class JwtService {
  /// Decodes a JWT token and returns the payload
  static Map<String, dynamic> decodeToken(String token) {
    try {
      return Jwt.parseJwt(token);
    } catch (e) {
      throw Exception('Invalid token: $e');
    }
  }

  /// Verifies if a token is expired
  static bool isTokenExpired(String token) {
    try {
      final payload = Jwt.parseJwt(token);
      if (payload['exp'] != null) {
        final expiration = DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
        return DateTime.now().isAfter(expiration);
      }
      return false;
    } catch (e) {
      return true; // If we can't parse the token, consider it expired
    }
  }

  /// Gets the expiration time of a token
  static DateTime? getTokenExpiration(String token) {
    try {
      final payload = Jwt.parseJwt(token);
      if (payload['exp'] != null) {
        return DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Generates a simple JWT token for offline use (not for production security)
  /// This is a simplified implementation for demonstration purposes
  static String generateToken(Map<String, dynamic> payload, String secret) {
    // Add issued at time if not present
    final now = DateTime.now();
    final Map<String, dynamic> fullPayload = Map<String, dynamic>.from(payload);
    
    if (!fullPayload.containsKey('iat')) {
      fullPayload['iat'] = now.millisecondsSinceEpoch ~/ 1000;
    }
    
    // Add expiration time (1 hour default)
    if (!fullPayload.containsKey('exp')) {
      final exp = now.add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
      fullPayload['exp'] = exp;
    }
    
    // Create header
    final header = base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'));
    
    // Create payload
    final payloadEncoded = base64Url.encode(utf8.encode(jsonEncode(fullPayload)));
    
    // Create signature
    final data = '$header.$payloadEncoded';
    final key = utf8.encode(secret);
    final bytes = utf8.encode(data);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    final signature = base64Url.encode(digest.bytes);
    
    return '$data.$signature';
  }

  /// Verifies a locally generated JWT token
  static bool verifyToken(String token, String secret) {
    try {
      // Split token into parts
      final parts = token.split('.');
      if (parts.length != 3) return false;
      
      final header = parts[0];
      final payload = parts[1];
      final signature = parts[2];
      
      // Recreate signature
      final data = '$header.$payload';
      final key = utf8.encode(secret);
      final bytes = utf8.encode(data);
      final hmac = Hmac(sha256, key);
      final digest = hmac.convert(bytes);
      final expectedSignature = base64Url.encode(digest.bytes);
      
      // Compare signatures
      if (signature != expectedSignature) return false;
      
      // Check expiration
      return !isTokenExpired(token);
    } catch (e) {
      return false;
    }
  }
}