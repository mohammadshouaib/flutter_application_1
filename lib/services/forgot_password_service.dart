import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class ForgotPasswordService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendOtpToEmail(String email) async {
    try {
      String otp = _generateOtp();
      await _firestore.collection('password_reset_otps').doc(email).set({
        'otp': otp,
        'expiresAt': DateTime.now().add(Duration(minutes: 5)),
      });

      // Send OTP via email (Using an email service)
      await _sendEmail(email, otp);
    } catch (e) {
      print("Error sending OTP: $e");
    }
  }


  Future<bool> verifyOtp(String email, String otp) async {
    try {
      var doc = await _firestore.collection('password_reset_otps').doc(email).get();
      if (!doc.exists) return false;

      var data = doc.data();
      if (data!['otp'] == otp && DateTime.now().isBefore(data['expiresAt'].toDate())) {
        return true;
      }
      return false;
    } catch (e) {
      print("Error verifying OTP: $e");
      return false;
    }
  }



  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      print("Password reset email sent.");
    } on FirebaseAuthException catch (e) {
      print("Error: ${e.message}");
    }
  }


  String _generateOtp() {
    var rng = Random();
    return (100000 + rng.nextInt(900000)).toString();
  }

  Future<void> _sendEmail(String email, String otp) async {
    // Implement your email sending logic here
    print("Sending OTP: $otp to $email");
  }
}
