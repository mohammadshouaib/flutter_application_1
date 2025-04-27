import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Map<String, dynamic>>> getTrainingPlans() {
    return _firestore.collection('training_plans').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'],
          'description': data['description'],
          'level': data['level'],
          'duration': data['duration'],
          'totalWeeks': data['totalWeeks'],
          'icon': data['icon'],
        };
      }).toList();
    });
  }

  Future<int> getUserProgress(String planId) async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    final doc = await _firestore
        .collection('user_progress')
        .doc(user.uid)
        .collection('plans')
        .doc(planId)
        .get();

    return doc.exists ? (doc.data()?['currentWeek'] ?? 0) : 0;
  }

  Future<void> updateUserProgress(String planId, int currentWeek) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('user_progress')
        .doc(user.uid)
        .collection('plans')
        .doc(planId)
        .set({
      'currentWeek': currentWeek,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}