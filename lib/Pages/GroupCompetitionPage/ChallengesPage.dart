import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import 'GroupCompetitionPage.dart';
import 'PublicGroupsTab.dart';


class ChallengesTab extends StatefulWidget {
  const ChallengesTab({super.key});

  @override
  State<ChallengesTab> createState() => _ChallengesTabState();
}

class _ChallengesTabState extends State<ChallengesTab> {
  List<QueryDocumentSnapshot> _activeChallenges = [];
  List<QueryDocumentSnapshot> _completedChallenges = [];
  bool _isInitialLoad = true;

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting && _isInitialLoad) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!userSnapshot.hasData || userSnapshot.data?.data() == null) {
          return _buildNoGroupUI(context);
        }

        final userGroups = (userSnapshot.data!.data() as Map<String, dynamic>)['groups'] as List<dynamic>? ?? [];

        if (userGroups.isEmpty) {
          return _buildNoGroupUI(context);
        }

        final groupId = userGroups.first as String;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('challenges')
              .where('groupId', isEqualTo: groupId)
              .orderBy('endDate', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && _isInitialLoad) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (snapshot.hasData) {
              final now = DateTime.now();
              _activeChallenges = snapshot.data!.docs.where((doc) {
                final endDate = (doc['endDate'] as Timestamp).toDate();
                return endDate.isAfter(now);
              }).toList();

              _completedChallenges = snapshot.data!.docs.where((doc) {
                final endDate = (doc['endDate'] as Timestamp).toDate();
                return !endDate.isAfter(now);
              }).toList();

              _isInitialLoad = false;
            }

            return _buildChallengesList(context, groupId);
          },
        );
      },
    );
  }

  Widget _buildChallengesList(BuildContext context, String groupId) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _isInitialLoad = true);
        await FirebaseFirestore.instance
            .collection('challenges')
            .where('groupId', isEqualTo: groupId)
            .get();
        setState(() => _isInitialLoad = false);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () => _showCreateChallengeDialog(context, groupId),
                icon: const Icon(Icons.add),
                label: const Text('Create New Challenge'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
          ),
          if (_activeChallenges.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 8),
                        child: Text(
                          'Active Challenges',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      );
                    }
                    final challenge = _activeChallenges[index - 1];
                    return ChallengeCard(
                      challenge: challenge.data() as Map<String, dynamic>,
                    );
                  },
                  childCount: _activeChallenges.length + 1,
                ),
              ),
            ),
          if (_completedChallenges.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 24, bottom: 8),
                        child: Row(
                          children: [
                            Text(
                              'Completed Challenges',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _deleteAllCompleted(context),
                              tooltip: 'Delete all completed',
                            ),
                          ],
                        ),
                      );
                    }
                    final challenge = _completedChallenges[index - 1];
                    return Dismissible(
                      key: Key(challenge.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) => _deleteChallenge(context, challenge.reference),
                      child: ChallengeCard(
                        challenge: challenge.data() as Map<String, dynamic>,
                        completed: true,
                      ),
                    );
                  },
                  childCount: _completedChallenges.length + 1,
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
        ],
      ),
    );
  }

  Future<void> _deleteChallenge(BuildContext context, DocumentReference challengeRef) async {
    try {
      await challengeRef.delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Challenge deleted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting challenge: $e')),
        );
      }
    }
  }

  Future<void> _deleteAllCompleted(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Delete All Completed?'),
            content: const Text(
                'This will permanently remove all completed challenges'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete All'),
              ),
            ],
          ),
    ) ?? false;

    if (confirm && _completedChallenges.isNotEmpty) {
      final batch = FirebaseFirestore.instance.batch();
      for (final challenge in _completedChallenges) {
        batch.delete(challenge.reference);
      }

      try {
        await batch.commit();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(
                'Deleted ${_completedChallenges.length} challenges')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting challenges: $e')),
          );
        }
      }
    }
  }

  Widget _buildNoGroupUI(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Join a group to participate in challenges'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showJoinGroupDialog(context),
            child: const Text('Join a Group'),
          ),
        ],
      ),
    );
  }
  static void _showJoinGroupDialog(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).get().then((doc) {
      final groups = (doc.data() as Map<String, dynamic>?)?['groups'] as List<dynamic>? ?? [];
      if (groups.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can only join one group at a time')),
        );
        return;
      }

      final TextEditingController groupCodeController = TextEditingController();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Join a Group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: groupCodeController,
                decoration: const InputDecoration(
                  labelText: 'Group Code',
                  hintText: 'Enter invitation code',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('OR'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showBrowseGroupsDialog(context),
                  icon: const Icon(Icons.search),
                  label: const Text('Browse Public Groups'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (groupCodeController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a group code')),
                  );
                  return;
                }

                try {
                  final groupDoc = FirebaseFirestore.instance
                      .collection('groups')
                      .doc(groupCodeController.text);

                  final groupSnapshot = await groupDoc.get();
                  if (!groupSnapshot.exists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Group not found')),
                    );
                    return;
                  }

                  await groupDoc.update({
                    'members': FieldValue.arrayUnion([currentUser?.uid])
                  });

                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser?.uid)
                      .update({
                    'groups': FieldValue.arrayUnion([groupCodeController.text])
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Joined group successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error joining group: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Join'),
            ),
          ],
        ),
      );
    });
  }


  Widget _buildNoChallengesUI(BuildContext context, String groupId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('No challenges yet'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showCreateChallengeDialog(context, groupId),
            child: const Text('Create Challenge'),
          ),
        ],
      ),
    );
  }

  static void _showBrowseGroupsDialog(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Public Groups'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<QuerySnapshot>(
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

              return ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final group = snapshot.data!.docs[index];
                  final data = group.data() as Map<String, dynamic>;

                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.group),
                    ),
                    title: Text(data['name'] ?? 'Unnamed Group'),
                    subtitle: Text(
                        '${data['members']?.length ?? 0} members • ${data['totalDistance'] ?? 0} km'),
                    trailing: data['members']?.contains(currentUser?.uid) ?? false
                        ? const Text('Joined')
                        : ElevatedButton(
                      onPressed: () async {
                        try {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(currentUser?.uid)
                              .get()
                              .then((doc) {
                            final groups = (doc.data() as Map<String, dynamic>?)?['groups'] as List<dynamic>? ?? [];
                            if (groups.isNotEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('You can only join one group at a time')),
                              );
                              return;
                            }

                            group.reference.update({
                              'members': FieldValue.arrayUnion([currentUser?.uid])
                            });

                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(currentUser?.uid)
                                .update({
                              'groups': FieldValue.arrayUnion([group.id])
                            });

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Joined group successfully!')),
                            );
                          });
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error joining group: $e')),
                          );
                        }
                      },
                      child: const Text('Join'),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }


  void _showCreateChallengeDialog(BuildContext context, String groupId) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController goalController = TextEditingController();
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Create New Challenge'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Challenge Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: goalController,
                  decoration: const InputDecoration(
                    labelText: 'Goal (km)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('End Date'),
                  subtitle: Text(
                      endDate != null
                          ? DateFormat('MMM d, y').format(endDate!)
                          : 'Select date'
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (selectedDate != null) {
                      setState(() => endDate = selectedDate);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a challenge name')),
                    );
                    return;
                  }

                  final goal = double.tryParse(goalController.text);
                  if (goal == null || goal <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid goal distance')),
                    );
                    return;
                  }

                  if (endDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select an end date')),
                    );
                    return;
                  }

                  try {
                    await FirebaseFirestore.instance.collection('challenges').add({
                      'name': nameController.text,
                      'goal': goal,
                      'endDate': Timestamp.fromDate(endDate!),
                      'groupId': groupId,
                      'createdAt': FieldValue.serverTimestamp(),
                      'participants': {
                        FirebaseAuth.instance.currentUser?.uid: {
                          'progress': 0.0,
                          'completed': false
                        }
                      }
                    });

                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error creating challenge: $e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
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
    final participants = challenge['participants'] as Map<String, dynamic>? ?? {};
    final userProgress = participants[currentUser] as Map<String, dynamic>? ?? {};
    final progress = (userProgress['progress'] ?? 0.0).toDouble();
    final goal = (challenge['goal'] ?? 1.0).toDouble();
    final percentage = progress / goal;
    final endDate = (challenge['endDate'] as Timestamp).toDate();

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
                  challenge['name'] ?? 'Challenge',
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
              value: percentage > 1 ? 1 : percentage,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(
                completed ? Colors.green : Colors.orange,
              ),
              minHeight: 10,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${progress.toStringAsFixed(1)}/${goal.toStringAsFixed(0)} km',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${(percentage * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 4),
                Text(completed
                    ? 'Completed on ${DateFormat('MMM d, y').format(endDate)}'
                    : 'Ends ${DateFormat('MMM d, y').format(endDate)}'
                ),
                const Spacer(),
                const Icon(Icons.people_outline, size: 16),
                const SizedBox(width: 4),
                Text('${participants.length} participants'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}