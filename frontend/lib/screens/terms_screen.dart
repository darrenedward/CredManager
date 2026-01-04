import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';

/// Terms & Conditions Screen
///
/// This screen displays the terms of use for Cred Manager.
/// For copyright and license information, see the License dialog.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        elevation: 0,
      ),
      body: Container(
        color: AppConstants.backgroundColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Terms & Conditions',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Last Updated: ${_getCurrentDate()}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'For copyright and license information, click the copyright notice in the app footer.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 30),

              // 1. Acceptance of Terms
              _buildSectionCard(
                '1. Acceptance of Terms',
                Icons.how_to_reg,
                [
                  _buildText('By using Cred Manager, you agree to these terms. If you don\'t agree, please don\'t use the app.'),
                  _buildText('These terms may be updated occasionally. Continued use after changes means you accept the new terms.'),
                ],
              ),

              const SizedBox(height: 20),

              // 2. What You Can Do
              _buildSectionCard(
                '2. What You Can Do',
                Icons.check_circle,
                [
                  _buildText('With Cred Manager, you can:'),
                  _buildBullet('Store and manage your API keys, passwords, and other credentials'),
                  _buildBullet('Organize credentials into projects and vaults'),
                  _buildBullet('Generate strong passwords using the built-in generator'),
                  _buildBullet('Backup and restore your encrypted data'),
                  _buildBullet('Use the app for personal or business purposes'),
                ],
              ),

              const SizedBox(height: 20),

              // 3. What You Cannot Do
              _buildSectionCard(
                '3. What You Cannot Do',
                Icons.block,
                [
                  _buildText('To protect everyone, you agree NOT to:'),
                  _buildBullet('Reverse engineer the app to bypass security features'),
                  _buildBullet('Remove or obscure copyright and license notices'),
                  _buildBullet('Use the app for illegal activities of any kind'),
                  _buildBullet('Attempt to exploit security vulnerabilities'),
                  _buildBullet('Distribute modified versions without proper attribution'),
                  _buildBullet('Hold the developer liable for data loss or security issues'),
                ],
              ),

              const SizedBox(height: 20),

              // 4. Your Responsibilities
              _buildSectionCard(
                '4. Your Responsibilities',
                Icons.person,
                [
                  _buildText('To keep your data secure, you should:'),
                  _buildBullet('Choose a strong, unique master passphrase'),
                  _buildBullet('Never share your master passphrase with anyone'),
                  _buildBullet('Keep your passphrase in a secure location'),
                  _buildBullet('Regularly backup your data to safe locations'),
                  _buildBullet('Keep the app updated with security patches'),
                  _buildBullet('Use the emergency backup feature wisely'),
                  _buildText('Remember: If you forget your passphrase, your data cannot be recovered. This is by design for your security.'),
                ],
              ),

              const SizedBox(height: 20),

              // 5. Security Features
              _buildSectionCard(
                '5. Security Features',
                Icons.security,
                [
                  _buildText('Cred Manager includes these security features:'),
                  _buildBullet('All data encrypted with your passphrase'),
                  _buildBullet('Data stored locally on your device (no cloud servers)'),
                  _buildBullet('Automatic clipboard clearing after copying passwords'),
                  _buildBullet('Automatic lock after periods of inactivity'),
                  _buildBullet('Optional biometric authentication on supported devices'),
                  _buildBullet('Emergency backup code for account recovery'),
                  _buildText('However, no security system is perfect. You are responsible for keeping your passphrase safe and backing up your data.'),
                ],
              ),

              const SizedBox(height: 20),

              // 6. Emergency Backup Code
              _buildSectionCard(
                '6. Emergency Backup Code',
                Icons.vpn_key,
                [
                  _buildText('The emergency backup code allows you to recover your account if you forget your passphrase:'),
                  _buildBullet('It can only be used ONCE - after use, generate a new one'),
                  _buildBullet('Store it securely (safe, lockbox, or with trusted person)'),
                  _buildBullet('Never share it with untrusted individuals'),
                  _buildBullet('Don\'t store it unencrypted in cloud storage'),
                  _buildBullet('Regenerate it after each use for ongoing protection'),
                  _buildText('The developer cannot recover your account without this code.'),
                ],
              ),

              const SizedBox(height: 20),

              // 7. Data & Privacy
              _buildSectionCard(
                '7. Data & Privacy',
                Icons.privacy_tip,
                [
                  _buildText('Cred Manager is privacy-focused:'),
                  _buildBullet('All your data is stored locally on your device'),
                  _buildBullet('NO data is sent to external servers'),
                  _buildBullet('NO analytics, telemetry, or usage tracking'),
                  _buildBullet('NO user accounts or registration required'),
                  _buildBullet('NO internet connection required for core features'),
                  _buildText('Your credentials never leave your device unless you explicitly export them. You are always in control of your data.'),
                ],
              ),

              const SizedBox(height: 20),

              // 8. Password Vault
              _buildSectionCard(
                '8. Password Vault',
                Icons.password,
                [
                  _buildText('The Password Vault feature lets you store:'),
                  _buildBullet('Website and application passwords'),
                  _buildBullet('PIN codes and access codes'),
                  _buildBullet('Username and email combinations'),
                  _buildText('Usage notes:'),
                  _buildBullet('The app does NOT auto-fill credentials - you copy them manually'),
                  _buildBullet('Clipboard clears automatically for security'),
                  _buildBullet('Organize passwords into vaults (e.g., Banking, Shopping, Social)'),
                ],
              ),

              const SizedBox(height: 20),

              // 9. Backup & Restore
              _buildSectionCard(
                '9. Backup & Restore',
                Icons.backup,
                [
                  _buildText('You can backup your entire database:'),
                  _buildBullet('Go to Dashboard → Quick Actions → Backup Data'),
                  _buildBullet('Choose a secure location to save the encrypted backup'),
                  _buildBullet('Store multiple backup copies in different locations'),
                  _buildText('To restore:'),
                  _buildBullet('Import your backup file on any device'),
                  _buildBullet('Enter your master passphrase to decrypt'),
                  _buildText('Test your backups periodically to ensure they work!'),
                ],
              ),

              const SizedBox(height: 20),

              // 10. Third-Party Services
              _buildSectionCard(
                '10. Third-Party Services',
                Icons.extension,
                [
                  _buildText('Cred Manager uses open-source libraries:'),
                  _buildBullet('Flutter - UI Framework'),
                  _buildBullet('sqflite_sqlcipher - Encrypted database'),
                  _buildBullet('cryptography - Encryption algorithms'),
                  _buildBullet('provider - State management'),
                  _buildText('Each library has its own license. These are included in the application and documented on GitHub.'),
                ],
              ),

              const SizedBox(height: 20),

              // 11. No Warranty
              _buildSectionCard(
                '11. No Warranty',
                Icons.info_outline,
                [
                  _buildText('Cred Manager is provided "as is" without warranties of any kind.'),
                  _buildText('The developer is not responsible for:'),
                  _buildBullet('Lost or forgotten passphrases (cannot be recovered by design)'),
                  _buildBullet('Data loss from not backing up regularly'),
                  _buildBullet('Security breaches from weak or compromised passphrases'),
                  _buildBullet('Hardware failure, theft, or device damage'),
                  _buildText('For full copyright and license terms, including disclaimers, click the copyright notice in the app footer.'),
                ],
              ),

              const SizedBox(height: 20),

              // 12. Getting Help
              _buildSectionCard(
                '12. Getting Help',
                Icons.help,
                [
                  _buildText('Need help? Check out these resources:'),
                  _buildBullet('Support section - Click "Support" in the app sidebar'),
                  _buildBullet('GitHub repository - Report bugs and request features'),
                  _buildBullet('Documentation - Built into the Support screen'),
                  _buildText('For security issues, please report them responsibly through GitHub\'s private vulnerability reporting (if available) or contact the developer directly.'),
                ],
              ),

              const SizedBox(height: 30),

              // Contact
              _buildContactCard(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      color: AppConstants.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppConstants.primaryColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[800],
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Card(
      elevation: 2,
      color: AppConstants.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.contact_mail, color: AppConstants.primaryColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Questions?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'For questions, bug reports, or feedback, visit our GitHub repository.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _launchUrl('https://github.com/darrenedward/CredManager'),
              child: Text(
                'https://github.com/darrenedward/CredManager',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue[700],
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Interested in contributing to the project? Email to apply:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _launchEmail('mailto:darren-edward@hotmail.com'),
              child: Text(
                'darren-edward@hotmail.com',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue[700],
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse(email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
