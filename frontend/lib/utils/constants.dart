import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Cred Manager';
  static const String appTagline = 'Your secrets are safe with me';
  static const String apiBaseUrl = 'http://localhost:8080/api'; // Adjust for production and desktop targets
  static const int defaultSessionTimeout = 30; // minutes

  // 🎨 **Main Color Palette (3 Colors)**
  static const Color primaryColor = Color(0xFF0f172a); // Navy Blue - Headers, Primary Buttons
  static const Color secondaryColor = Color(0xFF14b8a6); // Teal - Secondary Elements, Accents
  static const Color accentColor = Color(0xFFf59e0b); // Amber - Highlights, Security Icons

  // 🎨 **Extended Palette**
  static const Color primaryLight = Color(0xFF1e293b); // Lighter Navy
  static const Color secondaryLight = Color(0xFF2dd4bf); // Lighter Teal
  static const Color accentLight = Color(0xFFfbbf24); // Lighter Amber

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
  static const Color aiIconColor = secondaryColor; // AI/auto awesome icons
  static const Color actionIconColor = Color(0xFF64748b); // Generic action icons
  static const Color copyIconColor = Color(0xFF3b82f6); // Copy action
  static const Color editIconColor = Color(0xFFf59e0b); // Edit action
  static const Color deleteIconColor = errorColor; // Delete action

  // 📄 **Footer Information**
  static const String appVersion = '1.0.0';
  static const String copyright = '© 2025 Darren Edward House of Jones';
  static const String licenseText = '''
Cred Manager - Free Open Source Software

This software is provided "as is" without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose and noninfringement.

In no event shall the authors or copyright holders be liable for any claim, damages or other liability, whether in an action of contract, tort or otherwise, arising from, out of or in connection with the software or the use or other dealings in the software.

Users of this application do so at their own risk. The developers assume no responsibility for any loss of data, security breaches, or any other issues that may arise from the use of this application.

This software is free to use and distribute under the MIT License.
''';

  static const List<String> predefinedSecurityQuestions = [
    'What is the name of your first pet?',
    'What is your mother\'s maiden name?',
    'What is the name of the street you grew up on?',
    'What is your favorite book?',
    'What is the name of your first school?',
  ];
}