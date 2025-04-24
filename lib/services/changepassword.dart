// import 'package:flutter/material.dart';
// import 'package:flutter_application_1/services/forgot_password_service.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// class ChangePasswordScreen extends StatefulWidget {
//   final String email;

//   ChangePasswordScreen({super.key, required this.email});

//   @override
//   _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
// }

// class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _passwordController = TextEditingController();
//   final TextEditingController _confirmPasswordController = TextEditingController();
//   final ForgotPasswordService forgotPasswordService = ForgotPasswordService();
//   bool _isLoading = false;

//   Future<void> _changePassword() async {
//     forgotPasswordService.sendPasswordResetEmail(widget.email);
//   }
  

//   Future<bool> verifyUserPassword(String password) async {
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null || user.email == null) return false;
      
//       final credential = EmailAuthProvider.credential(
//         email: user.email!,
//         password: password,
//       );
      
//       await user.reauthenticateWithCredential(credential);
//       return true; // Password is correct
//     } on FirebaseAuthException catch (e) {
//       if (e.code == 'wrong-password') {
//         return false; // Password is incorrect
//       }
//       rethrow; // Other errors like network issues
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//       centerTitle: false,
//       elevation: 0,
//       backgroundColor: const Color(0xFF00BF6D),
//       foregroundColor: Colors.white,
//       title: const Text("Profile"),
//     ),
//       body: LogoWithTitle(
//         title: "Change Password",
//         children: [
//           Form(
//             key: _formKey,
//             child: Column(
//               children: [
//                 TextFormField(
//                   controller: _passwordController,
//                   obscureText: true,
//                   decoration: const InputDecoration(
//                     hintText: 'Current Password',
//                     filled: true,
//                     fillColor: Color(0xFFF5FCF9),
//                     contentPadding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
//                     border: OutlineInputBorder(
//                       borderSide: BorderSide.none,
//                       borderRadius: BorderRadius.all(Radius.circular(50)),
//                     ),
//                   ),
//                   validator: (value) {
//                     if (value==null) {
//                       return "Incorrect Password";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16.0),
//                 TextFormField(
//                   controller: _passwordController,
//                   obscureText: true,
//                   decoration: const InputDecoration(
//                     hintText: 'New Password',
//                     filled: true,
//                     fillColor: Color(0xFFF5FCF9),
//                     contentPadding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
//                     border: OutlineInputBorder(
//                       borderSide: BorderSide.none,
//                       borderRadius: BorderRadius.all(Radius.circular(50)),
//                     ),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.length < 6) {
//                       return "Password must be at least 6 characters.";
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16.0),
//                 TextFormField(
//                   controller: _confirmPasswordController,
//                   obscureText: true,
//                   decoration: const InputDecoration(
//                     hintText: 'Confirm Password',
//                     filled: true,
//                     fillColor: Color(0xFFF5FCF9),
//                     contentPadding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
//                     border: OutlineInputBorder(
//                       borderSide: BorderSide.none,
//                       borderRadius: BorderRadius.all(Radius.circular(50)),
//                     ),
//                   ),
//                   validator: (value) {
//                     if (value != _passwordController.text) {
//                       return "Passwords do not match.";
//                     }
//                     return null;
//                   },
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 16.0),
//           _isLoading
//               ? const CircularProgressIndicator()
//               : ElevatedButton(
//                   onPressed: _changePassword,
//                   style: ElevatedButton.styleFrom(
//                     elevation: 0,
//                     backgroundColor: const Color(0xFF00BF6D),
//                     foregroundColor: Colors.white,
//                     minimumSize: const Size(double.infinity, 48),
//                     shape: const StadiumBorder(),
//                   ),
//                   child: const Text("Change Password"),
//                 ),
//         ],
//       ),
//     );
//   }
// }


// class LogoWithTitle extends StatelessWidget {
//   final String title, subText;
//   final List<Widget> children;

//   const LogoWithTitle(
//       {super.key,
//       required this.title,
//       this.subText = '',
//       required this.children});
//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: LayoutBuilder(builder: (context, constraints) {
//         return SingleChildScrollView(
//           padding: const EdgeInsets.symmetric(horizontal: 16.0),
//           child: Column(
//             children: [
//               // Image.network(
//               //   "https://i.postimg.cc/nz0YBQcH/Logo-light.png",
//               //   height: 100,
//               // ),
//               SizedBox(height: constraints.maxHeight * 0.1),
//               SizedBox(
//                 height: constraints.maxHeight * 0.1,
//                 width: double.infinity,
//               ),
//               Text(
//                 title,
//                 style: Theme.of(context)
//                     .textTheme
//                     .headlineSmall!
//                     .copyWith(fontWeight: FontWeight.bold),
//               ),
              
//               Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 16.0),
//                 child: Text(
//                   subText,
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     height: 1.5,
//                     color: Theme.of(context)
//                         .textTheme
//                         .bodyLarge!
//                         .color!
//                         .withOpacity(0.64),
//                   ),
//                 ),
//               ),
//               ...children,
//             ],
//           ),
//         );
//       }),
//     );
//   }
// }


// Future<void> sendPasswordResetEmail(String email) async {
//     try {
//       await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
//       print("Password reset email sent.");
//     } on FirebaseAuthException catch (e) {
//       print("Error: ${e.message}");
//     }
//   }