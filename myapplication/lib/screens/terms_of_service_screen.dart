import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
          'Terms of Service',
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
              '1. Acceptance of Terms',
              'By accessing and using Rely App, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '2. Use License',
              'Permission is granted to temporarily download one copy of Rely App for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title, and under this license you may not:\n\n'
                  '• Modify or copy the materials\n'
                  '• Use the materials for any commercial purpose\n'
                  '• Attempt to decompile or reverse engineer any software\n'
                  '• Remove any copyright or other proprietary notations',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '3. User Account',
              'You are responsible for:\n\n'
                  '• Maintaining the confidentiality of your account credentials\n'
                  '• All activities that occur under your account\n'
                  '• Providing accurate and complete information\n'
                  '• Notifying us immediately of any unauthorized use',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '4. Health and Medical Disclaimer',
              'IMPORTANT: Rely App is not a medical device and should not be used for medical diagnosis, treatment, or prevention of any disease or condition. The information provided by this app is for general informational purposes only and is not intended as a substitute for professional medical advice, diagnosis, or treatment.\n\n'
                  'Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '5. Accuracy of Information',
              'While we strive to provide accurate health and fitness data, we do not warrant or guarantee the accuracy, completeness, or usefulness of any information provided. The app relies on sensor data and algorithms that may have limitations.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '6. Prohibited Uses',
              'You agree not to use the app:\n\n'
                  '• For any unlawful purpose\n'
                  '• To violate any international, federal, provincial, or state regulations, rules, or laws\n'
                  '• To transmit any viruses or malicious code\n'
                  '• To interfere with or disrupt the app\'s functionality\n'
                  '• To impersonate any person or entity',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '7. Limitation of Liability',
              'In no event shall Rely App or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use the app, even if we have been notified of the possibility of such damage.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '8. Modifications',
              'We reserve the right to modify or discontinue, temporarily or permanently, the app (or any part thereof) with or without notice. We shall not be liable to you or any third party for any modification, suspension, or discontinuance of the app.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '9. Termination',
              'We may terminate or suspend your account and access to the app immediately, without prior notice or liability, for any reason, including if you breach the Terms of Service.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '10. Governing Law',
              'These Terms shall be governed by and construed in accordance with applicable laws, without regard to its conflict of law provisions.',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '11. Contact Information',
              'If you have any questions about these Terms of Service, please contact us at:\n\n'
                  'Email: support@relyapp.com\n'
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






