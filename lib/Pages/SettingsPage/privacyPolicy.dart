import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            '''
Privacy Policy for Running App

Your privacy is important to us. This Privacy Policy explains how we collect, use, and protect your information.

1. Data Collection
We collect information such as your name, email address, running statistics, and location (if enabled).

2. How We Use Data
Your data is used to:
- Provide personalized training features
- Enable social and safety features (like live location)
- Improve the app experience

3. Data Sharing
We do not sell your data. We may share data with third-party services like Google Fit or Strava for syncing purposes.

4. Security
We use Firebase Authentication and Firestore with secure access rules and encryption.

5. Your Rights
You can request to:
- View your data
- Delete your account and data
- Opt-out of certain features

6. Contact Us
If you have any concerns, email us at: privacy@yourapp.com

By using our app, you agree to this policy.

Last updated: April 2025
            ''',
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
      ),
    );
  }
}
