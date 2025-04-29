import 'dart:math';

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
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final batch = FirebaseFirestore.instance.batch();
    final runRef = FirebaseFirestore.instance
        .collection('user_runs')
        .doc(userId)
        .collection('runs')
        .doc();

    // 1. Save the run (unchanged)
    batch.set(runRef, {
      'distance': distance,
      'duration': duration,
      'pace': duration / distance,
      'date': DateTime.now().toIso8601String(),
      'timestamp': FieldValue.serverTimestamp(),
      'notes': notes ?? '',
    });

    // 2. Update user stats (unchanged)
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    batch.update(userRef, {
      'totalDistance': FieldValue.increment(distance),
      'weeklyDistance': FieldValue.increment(distance),
      'lastRunDate': FieldValue.serverTimestamp(),
    });

    // 3. Get user's groups (unchanged)
    final userDoc = await userRef.get();
    final groups = (userDoc.data()?['groups'] as List<dynamic>?) ?? [];

    // List to store completed challenges to delete
    final List<DocumentReference> challengesToDelete = [];

    for (final groupId in groups) {
      final groupRef = FirebaseFirestore.instance.collection('groups').doc(groupId);

      // 4. Update group stats (unchanged)
      batch.update(groupRef, {
        'totalDistance': FieldValue.increment(distance),
        'weeklyDistance': FieldValue.increment(distance),
        'activeMembersThisWeek': FieldValue.arrayUnion([userId]),
      });

      // 5. Update challenges with progress capping
      final challenges = await FirebaseFirestore.instance
          .collection('challenges')
          .where('groupId', isEqualTo: groupId)
          .where('endDate', isGreaterThan: Timestamp.now())
          .get();

      for (final challenge in challenges.docs) {
        final challengeData = challenge.data();
        final goal = (challengeData['goal'] ?? 0).toDouble();

        // Get current progress
        final participants = challengeData['participants'] as Map<String, dynamic>? ?? {};
        final userProgress = participants[userId] as Map<String, dynamic>? ?? {};
        final currentProgress = (userProgress['progress'] ?? 0.0).toDouble();

        // Calculate new progress (capped at goal)
        final remainingToGoal = max(0, goal - currentProgress);
        final progressToAdd = min(distance, remainingToGoal);
        final newProgress = currentProgress + progressToAdd;
        final isCompleted = newProgress >= goal;

        // Update challenge
        batch.update(
          challenge.reference,
          {
            'participants.$userId.progress': newProgress,
            'participants.$userId.completed': isCompleted,
          },
        );

        // Mark for deletion if completed
        if (isCompleted) {
          challengesToDelete.add(challenge.reference);
        }
      }
    }

    // Commit all updates first
    await batch.commit();

    // Then delete completed challenges
    if (challengesToDelete.isNotEmpty) {
      final deleteBatch = FirebaseFirestore.instance.batch();
      for (final ref in challengesToDelete) {
        deleteBatch.delete(ref);
      }
      await deleteBatch.commit();
    }
  }
}