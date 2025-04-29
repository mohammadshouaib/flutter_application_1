import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import 'GroupCompetitionPage.dart';

class PublicGroupsTab extends StatelessWidget {
  const PublicGroupsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .where('isPublic', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No public groups available'));
        }

        return RefreshIndicator(
          onRefresh: () async {
            await FirebaseFirestore.instance
                .collection('groups')
                .where('isPublic', isEqualTo: true)
                .get();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final group = snapshot.data!.docs[index];
              final data = group.data() as Map<String, dynamic>;
              final currentUser = FirebaseAuth.instance.currentUser;
              final isMember = (data['members'] as List<dynamic>).contains(currentUser?.uid);

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.group)),
                  title: Text(data['name']),
                  subtitle: Text('${data['members']?.length ?? 0} members • ${data['totalDistance'] ?? 0} km'),
                  trailing: isMember
                      ? const Text('Joined', style: TextStyle(color: Colors.green))
                      : ElevatedButton(
                    onPressed: () => _joinGroup(context, group.id),
                    child: const Text('Join'),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _joinGroup(BuildContext context, String groupId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    try {
      // First check if user is already in a group
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid)
          .get();

      final userGroups = (userDoc.data() as Map<String, dynamic>?)?['groups'] as List<dynamic>? ?? [];

      if (userGroups.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can only join one group at a time')),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayUnion([currentUser?.uid])
      });

      await FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).update({
        'groups': FieldValue.arrayUnion([groupId])
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joined group successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining group: $e')),
      );
    }
  }
}

class ChallengeCard extends StatelessWidget {
  final Map<String, dynamic> challenge;
  final bool completed;

  const ChallengeCard({
    super.key,
    required this.challenge,
    this.completed = false,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser?.uid;
    final progress = (challenge['participantProgress'] as Map<String, dynamic>?)?[currentUser] ?? 0.0;
    final goal = (challenge['goal'] as num?)?.toDouble() ?? 1.0;
    final percentage = goal > 0 ? progress / goal : 0.0;
    final isOverAchieved = percentage > 1.0;
    final endDate = (challenge['endDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    final participants = (challenge['participants'] as List<dynamic>?)?.length ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  challenge['name'] ?? 'Unnamed Challenge',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: completed ? Colors.grey : null,
                  ),
                ),
                if (completed)
                  const Chip(
                    label: Text('Completed'),
                    backgroundColor: Colors.green,
                    labelStyle: TextStyle(color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: isOverAchieved ? 1.0 : percentage,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(
                completed ? Colors.green : Colors.orange,
              ),
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${progress.toStringAsFixed(1)}/${goal.toStringAsFixed(0)} km',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${(percentage * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.people_outline, size: 16),
                const SizedBox(width: 4),
                Text('$participants participants'),
                const Spacer(),
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 4),
                Text('Ends ${DateFormat('MMM d, y').format(endDate)}'),
              ],
            ),
            if (isOverAchieved && !completed) ...[
              const SizedBox(height: 8),
              const Text(
                'Challenge completed! Waiting for others to finish...',
                style: TextStyle(color: Colors.green),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
class GroupDetailsPage extends StatelessWidget {
  final String groupId;

  const GroupDetailsPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Group Details')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('groups').doc(groupId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final group = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(group['name'], style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _shareGroupInvite(context, groupId),
                  child: const Text('Invite Members'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  void _shareGroupInvite(BuildContext context, String groupId) {
    final inviteLink = 'https://yourapp.com/join?groupId=$groupId';
    Share.share('Join my running group! Use this code: $groupId or click: $inviteLink');
  }
}
