import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/locus_header.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            LocusHeader(
              leftIcon: const Icon(Icons.arrow_back, size: 28, color: Colors.black87),
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
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 32),
            
            _buildSection(
              'Introduction',
              'Locus ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and web service.',
            ),
            
            _buildSection(
              'Information We Collect',
              'We collect information that you provide directly to us when you:\n\n'
              '• Create an account using Google Sign-In\n'
              '• Upload photos, videos, audio recordings, or text notes\n'
              '• Use and interact with our services\n\n'
              'This information may include:\n\n'
              '• Your name and email address (from Google)\n'
              '• Profile picture (from Google)\n'
              '• Media files and memories you upload\n'
              '• Usage data and device information',
            ),
            
            _buildSection(
              'How We Use Your Information',
              'We use the information we collect to:\n\n'
              '• Provide, maintain, and improve our services\n'
              '• Create and manage your account\n'
              '• Store and display your memories\n'
              '• Communicate with you about our services\n'
              '• Protect against fraud and abuse',
            ),
            
            _buildSection(
              'Data Storage and Security',
              'Your data is stored securely using Firebase services:\n\n'
              '• Firebase Authentication for account security\n'
              '• Cloud Firestore for calendar and memory data\n'
              '• Firebase Storage for media files\n\n'
              'We implement appropriate security measures to protect your information from unauthorized access, alteration, disclosure, or destruction.',
            ),
            
            _buildSection(
              'Third-Party Services',
              'We use the following third-party services:\n\n'
              '• Google Sign-In for authentication\n'
              '• Firebase (Google Cloud) for data storage\n'
              '• Vercel for web hosting\n\n'
              'These services have their own privacy policies regarding the handling of your data.',
            ),
            
            _buildSection(
              'Your Data Rights',
              'You have the right to:\n\n'
              '• Access your personal data\n'
              '• Correct inaccurate data\n'
              '• Delete your account and data\n'
              '• Export your data\n\n'
              'To exercise these rights, please contact us at siddhantpetkar@gmail.com',
            ),
            
            _buildSection(
              'Children\'s Privacy',
              'Locus is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13.',
            ),
            
            _buildSection(
              'Changes to This Policy',
              'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last updated" date.',
            ),
            
            _buildSection(
              'Contact Us',
              'If you have questions about this Privacy Policy, please contact us at:\n\n'
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
