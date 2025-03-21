// import 'package:flutter/material.dart';
// import 'package:flutter_application_1/Login/Signup/forgotpassword.dart';
// import 'package:flutter_application_1/Login/Signup/signup.dart';
// import 'package:flutter_application_1/Profile/profile.dart';
// class SignInScreen extends StatelessWidget {
//   final _formKey = GlobalKey<FormState>();

//   SignInScreen({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             return SingleChildScrollView(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               child: Column(
//                 children: [
//                   SizedBox(height: constraints.maxHeight * 0.1),
//                   Image.network(
//                     "https://i.postimg.cc/nz0YBQcH/Logo-light.png",
//                     height: 100,
//                   ),
//                   SizedBox(height: constraints.maxHeight * 0.1),
//                   Text(
//                     "Sign In",
//                     style: Theme.of(context)
//                         .textTheme
//                         .headlineSmall!
//                         .copyWith(fontWeight: FontWeight.bold),
//                   ),
//                   SizedBox(height: constraints.maxHeight * 0.05),
//                   Form(
//                     key: _formKey,
//                     child: Column(
//                       children: [
//                         TextFormField(
//                           decoration: const InputDecoration(
//                             hintText: 'Phone',
//                             filled: true,
//                             fillColor: Color(0xFFF5FCF9),
//                             contentPadding: EdgeInsets.symmetric(
//                                 horizontal: 16.0 * 1.5, vertical: 16.0),
//                             border: OutlineInputBorder(
//                               borderSide: BorderSide.none,
//                               borderRadius:
//                                   BorderRadius.all(Radius.circular(50)),
//                             ),
//                           ),
//                           keyboardType: TextInputType.phone,
//                           onSaved: (phone) {
//                             // Save it
//                           },
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 16.0),
//                           child: TextFormField(
//                             obscureText: true,
//                             decoration: const InputDecoration(
//                               hintText: 'Password',
//                               filled: true,
//                               fillColor: Color(0xFFF5FCF9),
//                               contentPadding: EdgeInsets.symmetric(
//                                   horizontal: 16.0 * 1.5, vertical: 16.0),
//                               border: OutlineInputBorder(
//                                 borderSide: BorderSide.none,
//                                 borderRadius:
//                                     BorderRadius.all(Radius.circular(50)),
//                               ),
//                             ),
//                             onSaved: (passaword) {
//                               // Save it
//                             },
//                           ),
//                         ),
//                         ElevatedButton(
//                           onPressed: () {
//                             if (_formKey.currentState!.validate()) {
//                               _formKey.currentState!.save();
//                               // Navigate to the main screen
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => ProfileScreen()),
//                               );
//                             }
//                           },
//                           style: ElevatedButton.styleFrom(
//                             elevation: 0,
//                             backgroundColor: const Color(0xFF00BF6D),
//                             foregroundColor: Colors.white,
//                             minimumSize: const Size(double.infinity, 48),
//                             shape: const StadiumBorder(),
//                           ),
//                           child: const Text("Sign in"),
//                         ),
//                         const SizedBox(height: 16.0),
//                         TextButton(
//                           onPressed: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
//                             );
//                           },
//                           child: Text(
//                             'Forgot Password?',
//                             style: Theme.of(context)
//                                 .textTheme
//                                 .bodyMedium!
//                                 .copyWith(
//                                   color: Theme.of(context)
//                                       .textTheme
//                                       .bodyLarge!
//                                       .color!
//                                       .withOpacity(0.64),
//                                 ),
//                           ),
//                         ),
//                         TextButton(
//                           onPressed: () {
//                             Navigator.pushReplacement(
//                               context,
//                               MaterialPageRoute(builder: (context) => SignUpScreen()),
//                             );
//                           },
//                           child: Text.rich(
//                             const TextSpan(
//                               text: "Don’t have an account? ",
//                               children: [
//                                 TextSpan(
//                                   text: "Sign Up",
//                                   style: TextStyle(color: Color(0xFF00BF6D)),
//                                 ),
//                               ],
//                             ),
//                             style: Theme.of(context)
//                                 .textTheme
//                                 .bodyMedium!
//                                 .copyWith(
//                                   color: Theme.of(context)
//                                       .textTheme
//                                       .bodyLarge!
//                                       .color!
//                                       .withOpacity(0.64),
//                                 ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/Login/Signup/forgotpassword.dart';
import 'package:flutter_application_1/Login/Signup/signup.dart';
import 'package:flutter_application_1/Profile/profile.dart';
import 'package:flutter_application_1/services/auth_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      // Call Firebase Auth Service
      User? user = await _authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        // Navigate to Profile Screen on Success
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfileScreen()),
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid email or password')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  SizedBox(height: constraints.maxHeight * 0.1),
                  Image.network(
                    "https://i.postimg.cc/nz0YBQcH/Logo-light.png",
                    height: 100,
                  ),
                  SizedBox(height: constraints.maxHeight * 0.1),
                  Text(
                    "Sign In",
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall!
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: constraints.maxHeight * 0.05),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
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
                              return 'Please enter your email';
                            }
                            return null;
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              hintText: 'Password',
                              filled: true,
                              fillColor: Color(0xFFF5FCF9),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.0 * 1.5, vertical: 16.0),
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.all(Radius.circular(50)),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _signIn,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFF00BF6D),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text("Sign in"),
                        ),
                        const SizedBox(height: 16.0),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ForgotPasswordScreen()),
                            );
                          },
                          child: Text(
                            'Forgot Password?',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .color!
                                      .withOpacity(0.64),
                                ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => SignUpScreen()),
                            );
                          },
                          child: Text.rich(
                            const TextSpan(
                              text: "Don’t have an account? ",
                              children: [
                                TextSpan(
                                  text: "Sign Up",
                                  style: TextStyle(color: Color(0xFF00BF6D)),
                                ),
                              ],
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .color!
                                      .withOpacity(0.64),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
