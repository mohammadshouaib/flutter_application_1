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
  List<QueryDocumentSnapshot> _challenges = [];
  bool _isInitialLoad = true;

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting && _isInitialLoad) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!userSnapshot.hasData || userSnapshot.data?.data() == null) {
          return _buildNoGroupUI(context);
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final userGroups = userData['groups'] as List<dynamic>? ?? [];

        if (userGroups.isEmpty) {
          return _buildNoGroupUI(context);
        }

        final groupId = userGroups.first as String;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('challenges')
              .where('groupId', isEqualTo: groupId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && _isInitialLoad) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (snapshot.hasData) {
              _challenges = snapshot.data!.docs;
              _isInitialLoad = false;
            }

            if (_challenges.isEmpty) {
              return _buildNoChallengesUI(context, groupId);
            }

            return _buildChallengesList(context, groupId);
          },
        );
      },
    );
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

  Widget _buildChallengesList(BuildContext context, String groupId) {
    final now = DateTime.now();
    final activeChallenges = _challenges.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final endDate = (data['endDate'] as Timestamp).toDate();
      return endDate.isAfter(now);
    }).toList();

    final completedChallenges = _challenges.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final endDate = (data['endDate'] as Timestamp).toDate();
      return !endDate.isAfter(now);
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _isInitialLoad = true;
        });
        await FirebaseFirestore.instance
            .collection('challenges')
            .where('groupId', isEqualTo: groupId)
            .get();
        setState(() {
          _isInitialLoad = false;
        });
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
          if (activeChallenges.isNotEmpty)
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
                    final challenge = activeChallenges[index - 1];
                    return ChallengeCard(
                      challenge: challenge.data() as Map<String, dynamic>,
                    );
                  },
                  childCount: activeChallenges.length + 1,
                ),
              ),
            ),
          if (completedChallenges.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 24, bottom: 8),
                        child: Text(
                          'Completed Challenges',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      );
                    }
                    final challenge = completedChallenges[index - 1];
                    return ChallengeCard(
                      challenge: challenge.data() as Map<String, dynamic>,
                      completed: true,
                    );
                  },
                  childCount: completedChallenges.length + 1,
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
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
                      'participants': [FirebaseAuth.instance.currentUser?.uid],
                      'participantProgress': {
                        FirebaseAuth.instance.currentUser?.uid: 0.0
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