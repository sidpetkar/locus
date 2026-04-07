import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'widgets/locus_header.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            LocusHeader(
              leftIcon: const Icon(Icons.arrow_back, size: 28),
              onLeftTap: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            Text(
              'Last updated: ${DateTime.now().toString().split(' ')[0]}',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                color: colors.labelSecondary,
              ),
            ),
            const SizedBox(height: 32),
            
            _buildSection(
              'Acceptance of Terms',
              'By accessing or using Locus, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our service.',
            ),
            
            _buildSection(
              'Description of Service',
              'Locus is a personal memory management application that allows you to:\n\n'
              '• Save photos, videos, audio recordings, and text notes\n'
              '• Organize memories by calendar dates\n'
              '• Access your memories across multiple devices\n'
              '• Create a personal timeline of your life',
            ),
            
            _buildSection(
              'User Accounts',
              'To use Locus, you must:\n\n'
              '• Create an account using Google Sign-In\n'
              '• Be at least 13 years of age\n'
              '• Provide accurate and complete information\n'
              '• Maintain the security of your account\n'
              '• Be responsible for all activities under your account',
            ),
            
            _buildSection(
              'User Content',
              'You retain ownership of all content you upload to Locus. By uploading content, you grant us:\n\n'
              '• A license to store, process, and display your content\n'
              '• The right to backup and cache your content\n'
              '• Permission to use necessary third-party services (Firebase) to provide our service\n\n'
              'You are responsible for:\n\n'
              '• Ensuring you have the right to upload all content\n'
              '• Not uploading illegal, harmful, or infringing content\n'
              '• Complying with all applicable laws',
            ),
            
            _buildSection(
              'Prohibited Uses',
              'You may not use Locus to:\n\n'
              '• Violate any laws or regulations\n'
              '• Infringe on intellectual property rights\n'
              '• Upload malicious code or viruses\n'
              '• Harass, abuse, or harm others\n'
              '• Attempt to gain unauthorized access to our systems\n'
              '• Use automated systems to access the service',
            ),
            
            _buildSection(
              'Service Availability',
              'We strive to provide reliable service, but we do not guarantee:\n\n'
              '• Uninterrupted or error-free service\n'
              '• That the service will meet your requirements\n'
              '• That defects will be corrected\n\n'
              'We reserve the right to modify or discontinue the service at any time.',
            ),
            
            _buildSection(
              'Data Backup and Loss',
              'While we implement backup systems, you are responsible for:\n\n'
              '• Maintaining your own backups of important content\n'
              '• Understanding that data loss may occur\n\n'
              'We are not liable for any data loss or corruption.',
            ),
            
            _buildSection(
              'Termination',
              'We may suspend or terminate your account if:\n\n'
              '• You violate these Terms of Service\n'
              '• Your account is inactive for an extended period\n'
              '• We believe your account poses a security risk\n\n'
              'You may delete your account at any time through the app settings.',
            ),
            
            _buildSection(
              'Limitation of Liability',
              'To the maximum extent permitted by law, Locus and its developers shall not be liable for:\n\n'
              '• Indirect, incidental, or consequential damages\n'
              '• Loss of data, profits, or business opportunities\n'
              '• Service interruptions or errors\n\n'
              'Our total liability shall not exceed the amount you paid us in the past 12 months (currently \$0, as the service is free).',
            ),
            
            _buildSection(
              'Indemnification',
              'You agree to indemnify and hold harmless Locus and its developers from any claims, damages, or expenses arising from:\n\n'
              '• Your use of the service\n'
              '• Your content\n'
              '• Your violation of these terms',
            ),
            
            _buildSection(
              'Changes to Terms',
              'We may modify these Terms of Service at any time. We will notify you of significant changes by posting a notice in the app or via email. Continued use of the service after changes constitutes acceptance of the new terms.',
            ),
            
            _buildSection(
              'Governing Law',
              'These Terms shall be governed by and construed in accordance with the laws of India, without regard to conflict of law principles.',
            ),
            
            _buildSection(
              'Contact Information',
              'For questions about these Terms of Service, contact us at:\n\n'
              'Email: siddhantpetkar@gmail.com\n'
              'Website: mylocus.life',
            ),
            
            const SizedBox(height: 40),
          ],
        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28.0),
      child: Builder(builder: (context) {
        final colors = context.appColors;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.labelPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                height: 1.6,
                color: colors.labelPrimary,
              ),
            ),
          ],
        );
      }),
    );
  }
}
