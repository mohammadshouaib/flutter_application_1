import 'package:flutter/material.dart';
import 'package:flutter_application_1/Login/Signup/otp.dart';
import 'package:flutter_application_1/Services/forgot_password_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class ForgotPasswordScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  final ForgotPasswordService forgotPasswordService = ForgotPasswordService();

  
Future<bool> isEmailRegisteredInFirestore(String email) async {
  final normalizedEmail = email.toLowerCase().trim();
  print(' Searching for exact email: "$normalizedEmail"');

  try {
    final query = FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: normalizedEmail)
        .limit(1);

    
    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      print('Found matching document:');
      print('   Document ID: ${doc.id}');
      print('   Stored email: "${doc.data()['email']}"');
      print('   Type: ${doc.data()['email'].runtimeType}');
    } else {
      print('No matching documents found');
      // Check for hidden characters
      print('🔠 Email character codes:');
      normalizedEmail.runes.forEach((c) => print('   ${String.fromCharCode(c)} (U+${c.toRadixString(16).padLeft(4, '0')})'));
    }

    return snapshot.docs.isNotEmpty;
  } catch (e) {
    print(' Error: $e');
    return false;
  }
}

  Future<bool> isEmailRegistered(String email) async {
  // Check Auth first
  // final authResult = await isEmailRegisteredInAuth(email);
  // if (authResult) return true;
  
  // If not in Auth, check Firestore
  return await isEmailRegisteredInFirestore(email);
}

  ForgotPasswordScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFDF6EC),
      body: LogoWithTitle(
        title: 'Forgot Password',
        subText:
            "Enter the email address associated with your account.",
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Form(
              key: _formKey,
              child: TextFormField(
                controller: emailController,  // Use the controller
                decoration: const InputDecoration(
                  hintText: 'Email',
                  filled: true,
                  fillColor: Color(0xFFF5FCF9),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.0 * 1.5, vertical: 16.0),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(50)),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                // Form is valid, now do async check
                final email = emailController.text.trim();
                final exists = await isEmailRegistered(email);
                
                if (exists) {
                  forgotPasswordService.sendOtpToEmail(emailController.text);
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => VerificationScreen(emailController: emailController,)),
                                );
                    }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No account found with this email')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: const StadiumBorder(),
            ),
            child: const Text("Next"),
          ),
        ],
      ),
    );
  }
}

class LogoWithTitle extends StatelessWidget {
  final String title, subText;
  final List<Widget> children;

  const LogoWithTitle(
      {super.key,
      required this.title,
      this.subText = '',
      required this.children});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              SizedBox(height: constraints.maxHeight * 0.1),
              Image.asset(
                        "assets/Logo.png",
                        width: 140,
                        height: 140,
                      ),
              SizedBox(
                height: constraints.maxHeight * 0.1,
                width: double.infinity,
              ),
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
