import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Login/Signup/signinorsignup.dart';
import 'database_init.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  WeeklyReset.scheduleReset();
  //await initializeTrainingPlans();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Running App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SigninOrSignupScreen(),
    );
  }
}
class WeeklyReset {
  static void scheduleReset() {
    final now = DateTime.now();
    final nextMonday = now.add(Duration(days: (DateTime.monday - now.weekday + 7) % 7));
    final durationUntilReset = nextMonday.difference(now);

    Timer(durationUntilReset, () async {
      await _resetWeeklyStats();
      scheduleReset(); // Repeat
    });
  }

  static Future<void> _resetWeeklyStats() async {
    final batch = _firestore.batch();

    // Reset users
    final users = await _firestore.collection('users').get();
    for (final user in users.docs) {
      batch.update(user.reference, {'weeklyDistance': 0});
    }

    // Reset groups
    final groups = await _firestore.collection('groups').get();
    for (final group in groups.docs) {
      batch.update(group.reference, {
        'weeklyDistance': 0,
        'activeMembersThisWeek': [],
      });
    }

    await batch.commit();
  }
}
