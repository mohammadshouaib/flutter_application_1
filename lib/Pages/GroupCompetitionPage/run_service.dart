import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RunService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<void> logRun({
    required double distance,
    required int duration,
    String? notes,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final batch = _firestore.batch();
    final runRef = _firestore.collection('user_runs').doc(userId).collection('runs').doc();

    // 1. Save the run
    batch.set(runRef, {
      'distance': distance,
      'duration': duration,
      'pace': duration / distance,
      'date': DateTime.now().toIso8601String(),
      'timestamp': FieldValue.serverTimestamp(),
      'notes': notes ?? '',
    });

    // 2. Update user stats
    final userRef = _firestore.collection('users').doc(userId);
    batch.update(userRef, {
      'totalDistance': FieldValue.increment(distance),
      'weeklyDistance': FieldValue.increment(distance),
      'lastRunDate': FieldValue.serverTimestamp(),
    });

    // 3. Get user's groups
    final userDoc = await userRef.get();
    final groups = (userDoc.data()?['groups'] as List<dynamic>?) ?? [];

    for (final groupId in groups) {
      final groupRef = _firestore.collection('groups').doc(groupId);

      // 4. Update group stats
      batch.update(groupRef, {
        'totalDistance': FieldValue.increment(distance),
        'weeklyDistance': FieldValue.increment(distance),
        'activeMembersThisWeek': FieldValue.arrayUnion([userId]),
      });

      // 5. Update challenges
      final challenges = await _firestore
          .collection('challenges')
          .where('groupId', isEqualTo: groupId)
          .where('endDate', isGreaterThan: Timestamp.now())
          .get();

      for (final challenge in challenges.docs) {
        final challengeData = challenge.data() as Map<String, dynamic>;
        final goal = (challengeData['goal'] ?? 0).toDouble();

        // Get current progress (handle null cases)
        final participants = challengeData['participants'] as Map<String, dynamic>? ?? {};
        final userProgress = participants[userId] as Map<String, dynamic>? ?? {};
        final currentProgress = (userProgress['progress'] ?? 0.0).toDouble();
        final newProgress = currentProgress + distance;

        // Update the challenge
        batch.update(
          challenge.reference,
          {
            'participants.$userId.progress': FieldValue.increment(distance),
            'participants.$userId.completed': newProgress >= goal,
          },
        );
      }
    }

    await batch.commit();
  }
}