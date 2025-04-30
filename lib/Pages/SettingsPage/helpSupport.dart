import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
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
              'Frequently Asked Questions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildFAQItem(
              question: 'How do I create a new route?',
              answer: 'Tap the "+" button on the main screen and fill in the route details.',
            ),
            _buildFAQItem(
              question: 'How can I share my routes?',
              answer: 'Go to your profile, select the route, and use the share button.',
            ),
            _buildFAQItem(
              question: 'Why can\'t I see my location on the map?',
              answer: 'Make sure location services are enabled for this app in your device settings.',
            ),
            const SizedBox(height: 30),
            const Text(
              'Contact Us',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _buildContactOption(
              icon: Icons.email,
              label: 'Email Support: capstonefinalyearproject@gmail.com',
              onTap: () => _launchEmail(),
            ),
            _buildContactOption(
              icon: Icons.phone,
              label: 'Call Support: +961 - 70292872',
              onTap: () => _launchPhone('+96170292872'),
            ),
            // _buildContactOption(
            //   icon: Icons.chat,
            //   label: 'Live Chat',
            //   onTap: () => _showChatDialog(context),
            // ),
            // const SizedBox(height: 20),
            // const Text(
            //   'App Version: 1.0.0',
            //   style: TextStyle(color: Colors.grey),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 5),
          Text(answer),
          const SizedBox(height: 10),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'capstonefinalyearproject@gmail.com',
      queryParameters: {'subject': 'Route App Support'},
    );
    
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }

  Future<void> _launchPhone(String number) async {
    final Uri phoneLaunchUri = Uri(scheme: 'tel', path: number);
    
    if (await canLaunchUrl(phoneLaunchUri)) {
      await launchUrl(phoneLaunchUri);
    }
  }

  void _showChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Live Chat'),
        content: const Text('Our support team will connect with you shortly.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}