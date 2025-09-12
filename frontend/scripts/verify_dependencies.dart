#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

/// Dependency verification script for API Key Manager
/// Validates that all required packages and platform libraries are available

void main() async {
  print('🔍 API Key Manager - Dependency Verification\n');
  
  bool allValid = true;
  
  // Check Flutter/Dart versions
  allValid &= await checkFlutterVersion();
  allValid &= await checkDartVersion();
  
  // Check pubspec dependencies
  allValid &= await checkPubspecDependencies();
  
  // Check platform-specific requirements
  if (Platform.isLinux) {
    allValid &= await checkLinuxDependencies();
  } else if (Platform.isWindows) {
    allValid &= await checkWindowsDependencies();
  } else if (Platform.isMacOS) {
    allValid &= await checkMacOSDependencies();
  }
  
  // Summary
  print('\n' + '='*50);
  if (allValid) {
    print('✅ All dependencies verified successfully!');
    print('🚀 Ready to run: flutter run');
    exit(0);
  } else {
    print('❌ Some dependencies are missing or invalid');
    print('📋 See SETUP_REQUIREMENTS.md for detailed setup instructions');
    exit(1);
  }
}

Future<bool> checkFlutterVersion() async {
  print('📱 Checking Flutter version...');
  try {
    final result = await Process.run('flutter', ['--version']);
    if (result.exitCode == 0) {
      final output = result.stdout.toString();
      final versionMatch = RegExp(r'Flutter (\d+\.\d+\.\d+)').firstMatch(output);
      if (versionMatch != null) {
        final version = versionMatch.group(1)!;
        print('   ✅ Flutter $version detected');
        return _isVersionValid(version, '3.10.0');
      }
    }
  } catch (e) {
    print('   ❌ Flutter not found in PATH');
    return false;
  }
  print('   ❌ Could not determine Flutter version');
  return false;
}

Future<bool> checkDartVersion() async {
  print('🎯 Checking Dart version...');
  try {
    final result = await Process.run('dart', ['--version']);
    if (result.exitCode == 0) {
      final output = result.stdout.toString();
      final versionMatch = RegExp(r'Dart SDK version: (\d+\.\d+\.\d+)').firstMatch(output);
      if (versionMatch != null) {
        final version = versionMatch.group(1)!;
        print('   ✅ Dart $version detected');
        return _isVersionValid(version, '3.0.0');
      }
    }
  } catch (e) {
    print('   ❌ Dart not found in PATH');
    return false;
  }
  print('   ❌ Could not determine Dart version');
  return false;
}

Future<bool> checkPubspecDependencies() async {
  print('📦 Checking pubspec.yaml dependencies...');
  
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('   ❌ pubspec.yaml not found');
    return false;
  }
  
  final content = await pubspecFile.readAsString();
  final requiredDeps = [
    'sqflite_sqlcipher',
    'sqflite_common_ffi', 
    'sqlite3_flutter_libs',
    'cryptography',
    'crypto',
    'local_auth',
    'path_provider'
  ];
  
  bool allFound = true;
  for (final dep in requiredDeps) {
    if (content.contains('$dep:')) {
      print('   ✅ $dep');
    } else {
      print('   ❌ $dep (missing)');
      allFound = false;
    }
  }
  
  return allFound;
}

Future<bool> checkLinuxDependencies() async {
  print('🐧 Checking Linux system dependencies...');
  
  final libraries = [
    'libsqlite3.so',
    'libsecret-1.so',
    'libgtk-3.so'
  ];
  
  bool allFound = true;
  for (final lib in libraries) {
    final result = await Process.run('ldconfig', ['-p'], runInShell: true);
    if (result.stdout.toString().contains(lib)) {
      print('   ✅ $lib');
    } else {
      print('   ❌ $lib (not found)');
      allFound = false;
    }
  }
  
  return allFound;
}

Future<bool> checkWindowsDependencies() async {
  print('🪟 Checking Windows dependencies...');
  // Basic Windows checks - most dependencies are bundled
  print('   ✅ Windows platform detected');
  return true;
}

Future<bool> checkMacOSDependencies() async {
  print('🍎 Checking macOS dependencies...');
  // Basic macOS checks - most dependencies are bundled
  print('   ✅ macOS platform detected');
  return true;
}

bool _isVersionValid(String current, String minimum) {
  final currentParts = current.split('.').map(int.parse).toList();
  final minimumParts = minimum.split('.').map(int.parse).toList();
  
  for (int i = 0; i < 3; i++) {
    if (currentParts[i] > minimumParts[i]) return true;
    if (currentParts[i] < minimumParts[i]) return false;
  }
  return true; // Equal versions are valid
}