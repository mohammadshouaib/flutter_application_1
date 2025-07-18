import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/Login/Signup/signin.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final emailTextStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  Future<void> _sendResetEmail() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: widget.email);
      if (!mounted) return;
      setState(() {
        _emailSent = true;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDF6EC),
      appBar: AppBar(
        automaticallyImplyLeading: true, // This enables the back button
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        title: const Text('Reset Password'),
      ),
      body: LogoWithTitle(
        title: "Reset Password",
        children: [
          if (!_emailSent) ...[
            Text(
              'We will send a password reset link to:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              widget.email,
              style: Theme.of(context).textTheme.bodyLarge?.merge(emailTextStyle) ?? emailTextStyle,
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 16),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _sendResetEmail,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text("Send Reset Link"),
                  ),
          ],
          if (_emailSent) ...[
            const Icon(Icons.check_circle, color: Colors.green, size: 50),
            const SizedBox(height: 20),
            const Text(
              'Password reset email sent!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Check your email and follow the link to reset your password.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.popUntil(
                context,
                (route) => route is MaterialPageRoute && 
                       route.builder(context) is SignInScreen
              ),
              child: const Text(
                'Return to login',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ]
        ],
      ),
    );
  }
}

class LogoWithTitle extends StatelessWidget {
  final String title, subText;
  final List<Widget> children;

  const LogoWithTitle({
    super.key,
    required this.title,
    this.subText = '',
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              SizedBox(height: constraints.maxHeight * 0.05), // Reduced space
              Image.asset(
                "assets/Logo.png",
                width: 140,
                height: 140,
              ),
              SizedBox(height: constraints.maxHeight * 0.05), // Reduced space
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  subText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    height: 1.5,
                    color: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .color!
                        .withOpacity(0.64),
                  ),
                ),
              ),
              ...children,
            ],
          ),
        );
      }),
    );
  }
}