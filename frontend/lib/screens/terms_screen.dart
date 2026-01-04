import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'package:url_launcher/url_launcher.dart';

/// Terms & Conditions Screen
///
/// This screen displays the terms of use, privacy policy, and legal
/// disclaimers for Cred Manager.
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
              const SizedBox(height: 30),

              // Disclaimer
              _buildWarningCard(),

              const SizedBox(height: 30),

              // 1. Acceptance of Terms
              _buildSectionCard(
                '1. Acceptance of Terms',
                Icons.gavel,
                [
                  _buildText('By accessing, downloading, installing, or using Cred Manager ("the Application"), you agree to be bound by these Terms & Conditions. If you do not agree to these terms, please do not use the Application.'),
                  _buildText('Cred Manager is provided "as is" without any warranties, express or implied. By using this Application, you assume full responsibility for its use and any consequences resulting from such use.'),
                ],
              ),

              const SizedBox(height: 20),

              // 2. Disclaimer of Warranties
              _buildSectionCard(
                '2. Disclaimer of Warranties',
                Icons.warning_amber_rounded,
                [
                  _buildText('Cred Manager is provided on an "AS IS" and "AS AVAILABLE" basis without warranties of any kind, either express or implied.'),
                  _buildText('The developers, contributors, and distributors of Cred Manager expressly disclaim all warranties, including but not limited to:'),
                  _buildBullet('Merchantability and fitness for a particular purpose'),
                  _buildBullet('Non-infringement of third-party rights'),
                  _buildBullet('Accuracy, reliability, or availability of the Application'),
                  _buildBullet('Security or uninterrupted operation of the Application'),
                  _buildText('No oral or written information or advice given by the developers shall create a warranty.'),
                ],
              ),

              const SizedBox(height: 20),

              // 3. Limitation of Liability
              _buildSectionCard(
                '3. Limitation of Liability',
                Icons.shield,
                [
                  _buildText('To the maximum extent permitted by applicable law, the developers, contributors, and distributors of Cred Manager shall not be liable for:'),
                  _buildBullet('Any indirect, incidental, special, consequential, or punitive damages'),
                  _buildBullet('Loss of data, revenue, profits, or business opportunities'),
                  _buildBullet('Unauthorized access to or alteration of your data or device'),
                  _buildBullet('Damages arising from security breaches, data loss, or credential exposure'),
                  _buildBullet('Damages exceeding the amount you paid (if any) for the Application'),
                  _buildText('In no event shall the total liability exceed USD \$100.00.'),
                ],
              ),

              const SizedBox(height: 20),

              // 4. Security & Data Protection
              _buildSectionCard(
                '4. Security & Data Protection',
                Icons.security,
                [
                  _buildText('While Cred Manager implements industry-standard security measures, including:'),
                  _buildBullet('End-to-end encryption using military-grade algorithms'),
                  _buildBullet('Local-only storage (no data transmission to external servers)'),
                  _buildBullet('Secure passphrase protection with Argon2 key derivation'),
                  _buildBullet('Secure memory handling and automatic clipboard clearing'),
                  _buildText('You acknowledge that:'),
                  _buildBullet('No security system is completely impenetrable'),
                  _buildBullet('You are solely responsible for maintaining the confidentiality of your passphrase'),
                  _buildBullet('Weak or compromised passphrases can compromise your data'),
                  _buildBullet('You are responsible for backing up your data regularly'),
                  _buildBullet('The developers cannot recover your data if your passphrase is lost or forgotten'),
                ],
              ),

              const SizedBox(height: 20),

              // 5. User Responsibilities
              _buildSectionCard(
                '5. User Responsibilities',
                Icons.person,
                [
                  _buildText('You agree to:'),
                  _buildBullet('Keep your master passphrase secure and confidential'),
                  _buildBullet('Use strong, unique passphrases that meet the security requirements'),
                  _buildBullet('Not share your passphrase with anyone'),
                  _buildBullet('Back up your data regularly to secure locations'),
                  _buildBullet('Update the Application when security updates are released'),
                  _buildBullet('Report security vulnerabilities responsibly through appropriate channels'),
                  _buildText('You acknowledge that failure to follow these security practices may result in unauthorized access to your credentials and data.'),
                ],
              ),

              const SizedBox(height: 20),

              // 6. No Recovery Mechanism
              _buildSectionCard(
                '6. No Recovery Mechanism',
                Icons.lock_reset,
                [
                  _buildText('Due to the security architecture of Cred Manager:'),
                  _buildBullet('There is NO "forgot password" or recovery mechanism'),
                  _buildBullet('If you forget your master passphrase, your data CANNOT be recovered'),
                  _buildBullet('Lost passphrases result in permanent loss of access to stored data'),
                  _buildText('This is by design for security - the developers cannot access your data even if they wanted to.'),
                ],
              ),

              const SizedBox(height: 20),

              // 7. Emergency Backup Code
              _buildSectionCard(
                '7. Emergency Backup Code',
                Icons.vpn_key,
                [
                  _buildText('The emergency backup code feature:'),
                  _buildBullet('Can only be used ONCE to recover access'),
                  _buildBullet('Must be stored securely and never shared with untrusted parties'),
                  _buildBullet('Should be regenerated after each use'),
                  _buildText('The developers are not responsible for lost or compromised backup codes.'),
                ],
              ),

              const SizedBox(height: 20),

              // 8. Password Vault Feature
              _buildSectionCard(
                '8. Password Vault Feature',
                Icons.password,
                [
                  _buildText('The Password Vault feature allows you to store:'),
                  _buildBullet('Website passwords and login credentials'),
                  _buildBullet('Application passwords'),
                  _buildBullet('PIN codes and access codes'),
                  _buildBullet('Any other sensitive text-based credentials'),
                  _buildText('You acknowledge that:'),
                  _buildBullet('The Password Vault does not auto-fill credentials into websites or applications'),
                  _buildBullet('You must manually copy and paste credentials'),
                  _buildBullet('Clipboard auto-clear is a security feature, not a guarantee'),
                  _buildBullet('You are responsible for ensuring clipboard is cleared'),
                ],
              ),

              const SizedBox(height: 20),

              // 9. Privacy & Data Collection
              _buildSectionCard(
                '9. Privacy & Data Collection',
                Icons.privacy_tip,
                [
                  _buildText('Cred Manager is designed as a privacy-focused application:'),
                  _buildBullet('All data is stored locally on your device'),
                  _buildBullet('NO data is transmitted to external servers'),
                  _buildBullet('NO analytics, telemetry, or usage data is collected'),
                  _buildBullet('NO user registration or account creation is required'),
                  _buildBullet('NO internet connection is required for core functionality'),
                  _buildText('However, third-party services (if enabled) may have their own policies:'),
                  _buildBullet('Biometric authentication uses your device\'s secure hardware'),
                  _buildBullet('File operations (backup/restore) are handled by your operating system'),
                ],
              ),

              const SizedBox(height: 20),

              // 10. Open Source License
              _buildSectionCard(
                '10. Open Source License',
                Icons.code,
                [
                  _buildText('Cred Manager is copyrighted software owned by its developer. It is made available under the following terms:'),
                  _buildText('You are free to:'),
                  _buildBullet('Use the software for any purpose (personal or commercial)'),
                  _buildBullet('View and study the source code'),
                  _buildBullet('Modify the source code for your needs'),
                  _buildBullet('Distribute the original or modified software'),
                  _buildText('Subject to the following conditions:'),
                  _buildBullet('Include the original copyright notice in all copies'),
                  _buildBullet('The software is provided "as is" without any warranty'),
                  _buildBullet('The developer is not liable for any damages arising from use'),
                  _buildText('This is permissive open source software - you can do almost anything with it, as long as you include the copyright notice and understand that the software comes without warranties of any kind.'),
                ],
              ),

              const SizedBox(height: 20),

              // 11. Third-Party Libraries
              _buildSectionCard(
                '11. Third-Party Libraries',
                Icons.apps,
                [
                  _buildText('Cred Manager uses the following open-source libraries:'),
                  _buildBullet('Flutter - UI Framework (BSD 3-Clause)'),
                  _buildBullet('sqflite_sqlcipher - Encrypted database (BSD)'),
                  _buildBullet('cryptography - Encryption algorithms (Apache 2.0)'),
                  _buildBullet('provider - State management (MIT)'),
                  _buildText('Each library has its own license terms which are included in the application.'),
                ],
              ),

              const SizedBox(height: 20),

              // 12. Export Controls
              _buildSectionCard(
                '12. Export Controls',
                Icons.public,
                [
                  _buildText('You acknowledge that:'),
                  _buildBullet('Encryption software may be subject to export and import regulations'),
                  _buildBullet('You are responsible for complying with local laws'),
                  _buildBullet('Developers are not responsible for unauthorized use in restricted jurisdictions'),
                ],
              ),

              const SizedBox(height: 20),

              // 13. Modifications to Terms
              _buildSectionCard(
                '13. Modifications to Terms',
                Icons.update,
                [
                  _buildText('The developers reserve the right to modify these terms at any time. Continued use of the Application after changes constitutes acceptance of the new terms.'),
                ],
              ),

              const SizedBox(height: 20),

              // 14. Severability
              _buildSectionCard(
                '14. Severability',
                Icons.content_cut,
                [
                  _buildText('If any provision of these terms is found to be unenforceable, the remaining provisions shall remain in full force and effect.'),
                ],
              ),

              const SizedBox(height: 20),

              // 15. Governing Law
              _buildSectionCard(
                '15. Governing Law',
                Icons.gavel,
                [
                  _buildText('These terms shall be governed by the laws of the jurisdiction in which you reside. Any disputes shall be resolved in accordance with applicable local laws.'),
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

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[300]!, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'IMPORTANT DISCLAIMER',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Cred Manager is provided FREE OF CHARGE and WITHOUT ANY WARRANTY. '
            'USE THIS APPLICATION AT YOUR OWN RISK. THE DEVELOPERS ARE NOT '
            'RESPONSIBLE FOR ANY DATA LOSS, SECURITY BREACHES, OR DAMAGES '
            'RESULTING FROM ITS USE.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.red[900],
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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

  Widget _buildLink(String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _launchUrl(url),
        child: Text(
          url,
          style: TextStyle(
            fontSize: 14,
            color: Colors.blue[700],
            decoration: TextDecoration.underline,
          ),
        ),
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
                  'Questions or Concerns?',
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
              'Cred Manager is an open source project. For questions, bug reports, '
              'or contributions, please visit our GitHub repository or review '
              'the source code.',
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

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
