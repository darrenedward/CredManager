import 'package:flutter/material.dart';
import '../utils/constants.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppConstants.backgroundColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Support & Documentation',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Everything you need to know about Cred Manager',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 30),

              // App Overview
              Card(
                elevation: 2,
                color: AppConstants.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        AppConstants.surfaceColor,
                        AppConstants.surfaceColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.security,
                              color: AppConstants.accentColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'About Cred Manager',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Text(
                          'Cred Manager is a secure, offline-first application designed to help you manage your API keys, passwords, and other sensitive credentials. All data is encrypted and stored locally on your device.',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildFeatureList(),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // How It Works
              Card(
                elevation: 2,
                color: AppConstants.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        AppConstants.surfaceColor,
                        AppConstants.surfaceColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.settings,
                              color: AppConstants.secondaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'How It Works',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildHowItWorksStep(1, 'Setup', 'Create a secure passphrase to protect your data'),
                        _buildHowItWorksStep(2, 'Organize', 'Create projects to group related credentials'),
                        _buildHowItWorksStep(3, 'Store', 'Add API keys, passwords, and connection strings'),
                        _buildHowItWorksStep(4, 'Access', 'View, copy, and manage your credentials securely'),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Examples
              Card(
                elevation: 2,
                color: AppConstants.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        AppConstants.surfaceColor,
                        AppConstants.surfaceColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb,
                              color: AppConstants.accentColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Examples & Use Cases',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildExample(
                          'E-commerce Platform',
                          'Store database connection strings, payment gateway API keys, admin passwords, and webhook secrets all in one secure project.',
                        ),
                        const SizedBox(height: 15),
                        _buildExample(
                          'AI Development',
                          'Manage API keys for OpenAI, Anthropic, and other AI services. Keep track of different environments (dev/staging/prod).',
                        ),
                        const SizedBox(height: 15),
                        _buildExample(
                          'DevOps & Infrastructure',
                          'Store cloud provider credentials, SSH keys, database passwords, and deployment tokens organized by environment.',
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Security Features
              Card(
                elevation: 2,
                color: AppConstants.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        AppConstants.surfaceColor,
                        AppConstants.surfaceColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.shield,
                              color: AppConstants.successColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Security Features',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildSecurityFeature('Offline-First', 'All data stored locally on your device'),
                        _buildSecurityFeature('End-to-End Encryption', 'Your passphrase protects all stored data'),
                        _buildSecurityFeature('No Data Transmission', 'Credentials never leave your device'),
                        _buildSecurityFeature('Secure Hashing', 'Passwords are hashed using industry-standard algorithms'),
                        _buildSecurityFeature('Session Management', 'Automatic logout after inactivity'),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Stats
              Card(
                elevation: 2,
                color: AppConstants.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        AppConstants.surfaceColor,
                        AppConstants.surfaceColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.bar_chart,
                              color: AppConstants.primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'App Statistics',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildStatItem('Current Version', '1.0.0'),
                        const SizedBox(height: 12),
                        _buildStatItem('Framework', 'Built with Flutter'),
                        const SizedBox(height: 12),
                        _buildStatItem('Platforms', 'Windows, macOS, Linux, Android, iOS'),
                        const SizedBox(height: 12),
                        _buildStatItem('Security', 'End-to-end encryption'),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Getting Started Guide
              Card(
                elevation: 2,
                color: AppConstants.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        AppConstants.surfaceColor,
                        AppConstants.surfaceColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.play_circle_outline,
                              color: AppConstants.accentColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Getting Started Guide',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildGettingStartedStep(
                          '1. Create Your First Project',
                          'Navigate to the Projects tab and click "New Project". Give it a name and description to organize your credentials by purpose or environment.',
                          Icons.folder_outlined,
                        ),
                        _buildGettingStartedStep(
                          '2. Add Credentials',
                          'Click "Add Credential" in your project. Enter the service name, credential type (API Key, Password, etc.), and the actual credential value.',
                          Icons.add_circle_outline,
                        ),
                        _buildGettingStartedStep(
                          '3. Setup AI Services',
                          'Use the AI Services tab to manage API keys for OpenAI, Anthropic, and other AI platforms with pre-configured templates.',
                          Icons.auto_awesome_outlined,
                        ),
                        _buildGettingStartedStep(
                          '4. Configure Security',
                          'Go to Settings to adjust auto-lock timeout, enable biometric authentication, and configure backup preferences.',
                          Icons.security_outlined,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Data Management
              Card(
                elevation: 2,
                color: AppConstants.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        AppConstants.surfaceColor,
                        AppConstants.surfaceColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.storage,
                              color: AppConstants.secondaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Data Management',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildDataManagementItem(
                          'Backup Your Data',
                          'Click the "Backup Data" button in the dashboard quick actions. Choose a secure location to save your encrypted backup file. This creates a complete backup of all your projects and credentials.',
                          Icons.backup,
                        ),
                        _buildDataManagementItem(
                          'Import Data',
                          'Use "Import Data" from the dashboard to restore from a backup file. You can also import from other password managers by converting to the supported JSON format.',
                          Icons.upload,
                        ),
                        _buildDataManagementItem(
                          'Export Individual Projects',
                          'Right-click any project to export just that project\'s credentials. Useful for sharing specific credentials with team members.',
                          Icons.download,
                        ),
                        _buildDataManagementItem(
                          'Sync Across Devices',
                          'While the app is offline-first, you can manually sync by backing up on one device and importing on another. Cloud sync is planned for future releases.',
                          Icons.sync,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Project Management Guide
              Card(
                elevation: 2,
                color: AppConstants.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        AppConstants.surfaceColor,
                        AppConstants.surfaceColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.folder_open,
                              color: AppConstants.accentColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Project Management',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildProjectManagementItem(
                          'Creating Projects',
                          'Go to Projects tab → Click "New Project" → Enter name and description → Save. Projects help organize credentials by purpose (e.g., "Production APIs", "Development Keys").',
                          Icons.create_new_folder,
                        ),
                        _buildProjectManagementItem(
                          'Adding Credentials to Projects',
                          'Open a project → Click "Add Credential" → Choose type (API Key, Password, Token, etc.) → Enter service name and credential value → Save securely.',
                          Icons.add_circle,
                        ),
                        _buildProjectManagementItem(
                          'Project Export',
                          'Right-click any project → Select "Export Project" → Choose location → Save encrypted file. Perfect for sharing project credentials with team members.',
                          Icons.file_download,
                        ),
                        _buildProjectManagementItem(
                          'Project Import',
                          'Projects tab → Click "Import Project" → Select exported project file → Enter passphrase → All credentials will be imported into a new project.',
                          Icons.file_upload,
                        ),
                        _buildProjectManagementItem(
                          'Deleting Projects',
                          'Right-click project → Select "Delete Project" → Confirm deletion. Warning: This permanently removes all credentials in the project.',
                          Icons.delete_forever,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Credential Management
              Card(
                elevation: 2,
                color: AppConstants.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        AppConstants.surfaceColor,
                        AppConstants.surfaceColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.key,
                              color: AppConstants.successColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Credential Management',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildCredentialManagementItem(
                          'Supported Credential Types',
                          'API Keys, Passwords, Database Connection Strings, SSH Keys, Tokens, Certificates, and Custom credential types. Each type has optimized input fields.',
                          Icons.category,
                        ),
                        _buildCredentialManagementItem(
                          'Quick Copy Feature',
                          'Click the copy icon next to any credential to instantly copy it to clipboard. The app will show a confirmation and auto-clear clipboard after 30 seconds for security.',
                          Icons.content_copy,
                        ),
                        _buildCredentialManagementItem(
                          'Editing Credentials',
                          'Click on any credential → Edit button → Update values → Save. You can change the service name, credential type, or the actual credential value.',
                          Icons.edit,
                        ),
                        _buildCredentialManagementItem(
                          'Credential Search',
                          'Use the search bar at the top to quickly find credentials by service name, project, or credential type. Search works across all projects.',
                          Icons.search,
                        ),
                        _buildCredentialManagementItem(
                          'Password Generator',
                          'When adding passwords, click the generate button to create strong passwords with customizable length, symbols, and character sets.',
                          Icons.auto_fix_high,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Security & Privacy
              Card(
                elevation: 2,
                color: AppConstants.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        AppConstants.surfaceColor,
                        AppConstants.surfaceColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.security,
                              color: AppConstants.errorColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Security & Privacy',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildSecurityItem(
                          'Auto-Lock Settings',
                          'Go to Settings → Security → Set auto-lock timeout (5-60 minutes). App automatically locks when inactive to protect your credentials.',
                          Icons.lock_clock,
                        ),
                        _buildSecurityItem(
                          'Changing Master Passphrase',
                          'Settings → Security → "Change Passphrase" → Enter current passphrase → Enter new passphrase → Confirm. All data is re-encrypted with the new passphrase.',
                          Icons.password,
                        ),
                        _buildSecurityItem(
                          'Clear All Data',
                          'Settings → Security → "Clear All Data" → Type "DELETE" to confirm. This permanently removes all projects, credentials, and settings. Cannot be undone.',
                          Icons.delete_sweep,
                        ),
                        _buildSecurityItem(
                          'Biometric Authentication',
                          'Settings → Security → Enable "Biometric Login" (if supported). Use fingerprint or face recognition to unlock the app instead of typing passphrase.',
                          Icons.fingerprint,
                        ),
                        _buildSecurityItem(
                          'Offline Security',
                          'All data is stored locally and encrypted. No data is sent to external servers. Your credentials never leave your device unless you explicitly export them.',
                          Icons.cloud_off,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Troubleshooting
              Card(
                elevation: 2,
                color: AppConstants.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        AppConstants.surfaceColor,
                        AppConstants.surfaceColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.help_outline,
                              color: AppConstants.warningColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Troubleshooting',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildTroubleshootingItem(
                          'Forgot Master Passphrase',
                          'Unfortunately, if you forget your master passphrase, your data cannot be recovered. This is by design for security. You\'ll need to clear all data and start fresh.',
                          Icons.lock_reset,
                        ),
                        _buildTroubleshootingItem(
                          'Import/Export Not Working',
                          'Ensure the file is not corrupted and you have the correct passphrase. Check file permissions and try saving/loading from a different location.',
                          Icons.error_outline,
                        ),
                        _buildTroubleshootingItem(
                          'App Won\'t Start',
                          'Try restarting the app. If the issue persists, check if your system meets the minimum requirements. Consider clearing app data as a last resort.',
                          Icons.refresh,
                        ),
                        _buildTroubleshootingItem(
                          'Performance Issues',
                          'Large numbers of credentials (1000+) may slow the app. Consider organizing into more projects or archiving old credentials by exporting and removing them.',
                          Icons.speed,
                        ),
                        _buildTroubleshootingItem(
                          'Backup File Corrupted',
                          'Always keep multiple backup copies in different locations. Test backup files periodically by importing them into a test environment.',
                          Icons.backup,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // FAQ Section
              Card(
                elevation: 2,
                color: AppConstants.surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        AppConstants.surfaceColor,
                        AppConstants.surfaceColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.quiz,
                              color: AppConstants.primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Frequently Asked Questions',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildFAQSection(),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureList() {
    return Column(
      children: [
        _buildFeature('🔐 Secure Storage', 'All credentials encrypted with your passphrase'),
        _buildFeature('📁 Project Organization', 'Group credentials by project or service'),
        _buildFeature('🤖 AI Service Integration', 'Built-in support for popular AI platforms'),
        _buildFeature('🔄 Password Generator', 'Create strong, secure passwords'),
        _buildFeature('📋 One-Click Copy', 'Quick access to your credentials'),
        _buildFeature('🌙 Offline Mode', 'Works without internet connection'),
      ],
    );
  }

  Widget _buildFeature(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 16, color: Colors.black),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksStep(int step, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppConstants.secondaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppConstants.secondaryColor.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExample(String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityFeature(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: AppConstants.successColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: AppConstants.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildGettingStartedStep(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: AppConstants.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(
              icon,
              color: AppConstants.accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagementItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: AppConstants.secondaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(
              icon,
              color: AppConstants.secondaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectManagementItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: AppConstants.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(
              icon,
              color: AppConstants.accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialManagementItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: AppConstants.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(
              icon,
              color: AppConstants.successColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: AppConstants.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(
              icon,
              color: AppConstants.errorColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: AppConstants.warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(
              icon,
              color: AppConstants.warningColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    return Column(
      children: [
        _FAQExpansionTile(
          title: 'Why does biometric authentication show "Not Available"?',
          content: 'Biometric authentication requires compatible hardware like fingerprint readers, Face ID cameras, or Windows Hello. On desktop systems like Linux, these features may not be available or supported. The app works perfectly without biometrics - it\'s an optional convenience feature, not a security requirement.',
          icon: Icons.fingerprint,
        ),
        const SizedBox(height: 8),
        _FAQExpansionTile(
          title: 'How secure is my data storage?',
          content: 'All your data is encrypted using military-grade encryption standards. Your master passphrase protects everything, and data never leaves your device unless you explicitly export it. The app uses multiple layers of security including encrypted databases and secure memory handling.',
          icon: Icons.security,
        ),
        const SizedBox(height: 8),
        _FAQExpansionTile(
          title: 'What platforms support biometric authentication?',
          content: 'Biometric authentication is available on:\n• Android devices with fingerprint/face unlock\n• iOS devices with Touch ID or Face ID\n• Windows devices with Windows Hello\n• macOS devices with Touch ID\n• Linux systems with compatible fingerprint hardware',
          icon: Icons.devices,
        ),
        const SizedBox(height: 8),
        _FAQExpansionTile(
          title: 'Can I use the app without biometrics?',
          content: 'Absolutely! Biometric authentication is entirely optional. The app is designed to work fully with just your master passphrase. Biometrics simply provide a convenient way to unlock the app more quickly on supported devices.',
          icon: Icons.lock,
        ),
        const SizedBox(height: 8),
        _FAQExpansionTile(
          title: 'How does offline storage work?',
          content: 'All your credentials are stored locally on your device in an encrypted database. Nothing is sent to external servers or cloud services. This ensures complete privacy and allows the app to work without an internet connection.',
          icon: Icons.cloud_off,
        ),
        const SizedBox(height: 8),
        _FAQExpansionTile(
          title: 'What happens if I lose my device?',
          content: 'Your data remains secure because it\'s encrypted with your master passphrase. Without the passphrase, the data cannot be accessed. This is why regular backups are important - you can restore your data on a new device using your backup file and passphrase.',
          icon: Icons.phone_android,
        ),
        const SizedBox(height: 8),
        _FAQExpansionTile(
          title: 'Can I sync data between devices?',
          content: 'Currently, the app is designed for single-device use with manual backup/restore for transferring data. You can export your data from one device and import it on another. Cloud synchronization may be added in future versions while maintaining security.',
          icon: Icons.sync,
        ),
      ],
    );
  }

  Widget _FAQExpansionTile({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Builder(
      builder: (context) => Card(
        elevation: 1,
        color: AppConstants.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
          child: ExpansionTile(
            leading: Icon(
              icon,
              color: AppConstants.primaryColor,
              size: 20,
            ),
            title: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppConstants.primaryColor,
              ),
            ),
            iconColor: AppConstants.primaryColor,
            collapsedIconColor: AppConstants.primaryColor,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  bottom: 16.0,
                  top: 0.0,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    content,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}