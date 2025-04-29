import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  void _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@yourapp.com',
      query: 'subject=Help & Support',
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              "Frequently Asked Questions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ExpansionTile(
              title: const Text("How do I reset my password?"),
              children: const [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Go to Sign In > Forgot Password and follow the instructions."),
                ),
              ],
            ),
            ExpansionTile(
              title: const Text("How can I delete my account?"),
              children: const [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Please email us at support@yourapp.com to request account deletion."),
                ),
              ],
            ),
            ExpansionTile(
              title: const Text("Why can't I track my runs?"),
              children: const [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Make sure GPS is enabled and the app has location permissions."),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _launchEmail,
              icon: const Icon(Icons.email),
              label: const Text("Contact Support"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
