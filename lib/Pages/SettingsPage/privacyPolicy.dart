import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        centerTitle: true,
        backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last Updated: Wednesday 30, 2025',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),
            const Text(
              '1. Information We Collect',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            const Text(
              'We collect information you provide directly, including:'
              '\n- Account information (name, email)'
              '\n- Route data you create'
              '\n- Location information when you use our mapping features',
            ),
            const SizedBox(height: 20),
            const Text(
              '2. How We Use Your Information',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your information is used to:'
              '\n- Provide and improve our services'
              '\n- Personalize your experience'
              '\n- Communicate with you about your account'
              '\n- Ensure the security of our services',
            ),
            const SizedBox(height: 20),
            const Text(
              '3. Data Sharing',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            const Text(
              'We do not sell your personal data. We may share information with:'
              '\n- Service providers who assist our operations'
              '\n- Law enforcement when required by law'
              '\n- Other users only with your explicit consent',
            ),
            const SizedBox(height: 20),
            const Text(
              '4. Your Choices',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            const Text(
              'You can:'
              '\n- Review and update your account information'
              '\n- Opt-out of promotional communications'
              '\n- Delete your account at any time',
            ),
            const SizedBox(height: 20),
            const Text(
              '5. Security',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            const Text(
              'We implement appropriate security measures to protect your data,'
              ' but no system is completely secure. Please use strong passwords'
              ' and keep your login information confidential.',
            ),
            const SizedBox(height: 30),
            const Text(
              'For any questions about this policy, please contact us at privacy@routeapp.com',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}