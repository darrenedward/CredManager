import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Cred Manager';
  static const String appTagline = 'Your secrets are safe with me';
  static const int defaultSessionTimeout = 30; // minutes

  // 🎨 **Material 3 Color Palette**
  static const Color primaryColor = Color(0xFF0f172a); // Navy Blue - Primary brand color
  static const Color secondaryColor = Color(0xFFf59e0b); // Orange - Secondary brand color (was teal)
  static const Color accentColor = Color(0xFFf59e0b); // Orange - Highlights, Security Icons

  // 🎨 **Material 3 Seed Colors**
  static const Color primarySeed = Color(0xFF0f172a); // Navy Blue seed for Material 3
  static const Color secondarySeed = Color(0xFFf59e0b); // Orange seed for Material 3

  // 🎨 **Extended Palette**
  static const Color primaryLight = Color(0xFF1e293b); // Lighter Navy
  static const Color secondaryLight = Color(0xFFfbbf24); // Lighter Orange (was teal)
  static const Color accentLight = Color(0xFFfbbf24); // Lighter Orange

  // 🎯 **Semantic Colors**
  static const Color successColor = Color(0xFF10b981); // Green - Save buttons, success states
  static const Color errorColor = Color(0xFFef4444); // Red - Delete buttons, error states
  static const Color warningColor = Color(0xFFf59e0b); // Amber - Warnings

  // 🎨 **Background Colors**
  static const Color backgroundColor = Color(0xFFf8fafc); // Light background
  static const Color surfaceColor = Colors.white; // Card/surface backgrounds
  static const Color cardColor = Color(0xFFf1f5f9); // Subtle card backgrounds

  // 🎨 **Icon Colors by Category**
  static const Color securityIconColor = accentColor; // Security shield, locks
  static const Color projectIconColor = primaryColor; // Project/folder icons
  static const Color aiIconColor = accentColor; // AI/auto awesome icons
  static const Color actionIconColor = Color(0xFF64748b); // Generic action icons
  static const Color copyIconColor = Color(0xFF3b82f6); // Copy action
  static const Color editIconColor = Color(0xFFf59e0b); // Edit action
  static const Color deleteIconColor = errorColor; // Delete action

  // 🎨 **Subtle Icon Colors for Support Section**
  static const Color supportIconColor1 = Color(0xFF4A90E2); // Soft blue
  static const Color supportIconColor2 = Color(0xFF7B68EE); // Medium slate blue (subtle)
  static const Color supportIconColor3 = Color(0xFF20B2AA); // Light sea green
  static const Color supportIconColor4 = Color(0xFF9370DB); // Medium purple (subtle)
  static const Color supportIconColor5 = Color(0xFF3CB371); // Medium sea green

  // 📄 **Footer Information**
  static const String appVersion = '1.0.0';
  static const String copyright = '© 2025 Darren Edward House of Jones';
  static const String copyrightNotice = '''
Copyright (c) 2025 Darren Edward House of Jones

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
''';
  static const String licenseText = '''
Cred Manager v1.0.0
An open-source credential management application

This software is free to use, modify, and distribute under the terms
of the permissive open source license shown above.

Key Points:
• Free for both personal and commercial use
• Source code is available for review and modification
• No warranty provided - use at your own risk
• You retain full ownership of your data
• All data is stored locally on your device
''';

}