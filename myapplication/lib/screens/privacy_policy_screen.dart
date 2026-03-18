import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F3A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text(
              'Last Updated: Januari 2026',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Introduction',
              'Welcome to Rely App. We are committed to protecting your privacy and ensuring the security of your personal information. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '2. Information We Collect',
              'We collect information that you provide directly to us, including:\n\n'
                  '• Personal Information: Name, email address, age, gender\n'
                  '• Health Data: Heart rate, steps, calories, sleep patterns, blood oxygen levels\n'
                  '• Activity Data: Workout sessions, exercise routines, fitness goals\n'
                  '• Device Information: Device type, operating system, unique device identifiers\n'
                  '• Usage Data: How you interact with the app, features used, time spent',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '3. How We Use Your Information',
              'We use the collected information to:\n\n'
                  '• Provide and improve our services\n'
                  '• Track and analyze your health and fitness progress\n'
                  '• Generate personalized insights and recommendations\n'
                  '• Send you notifications and updates\n'
                  '• Respond to your inquiries and provide customer support\n'
                  '• Ensure app security and prevent fraud',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '4. Data Storage and Security',
              'Your data is stored securely using industry-standard encryption methods. We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '5. Data Sharing',
              'We do not sell your personal information. We may share your data only in the following circumstances:\n\n'
                  '• With your explicit consent\n'
                  '• To comply with legal obligations\n'
                  '• To protect our rights and safety\n'
                  '• With service providers who assist in app operations (under strict confidentiality agreements)',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '6. Your Rights',
              'You have the right to:\n\n'
                  '• Access your personal data\n'
                  '• Correct inaccurate information\n'
                  '• Request deletion of your data\n'
                  '• Export your data\n'
                  '• Opt-out of data processing\n'
                  '• Withdraw consent at any time',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '7. Children\'s Privacy',
              'Our app is not intended for children under the age of 13. We do not knowingly collect personal information from children under 13. If you believe we have collected information from a child under 13, please contact us immediately.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '8. Changes to This Policy',
              'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '9. Contact Us',
              'If you have any questions about this Privacy Policy, please contact us at:\n\n'
                  'Email: privacy@relyapp.com\n'
                  'Address: Malang, East Java, Indonesia',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}






