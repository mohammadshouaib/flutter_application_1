import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import 'GroupCompetitionPage.dart';
import 'PublicGroupsTab.dart';

class LeaderboardTab extends StatelessWidget {
  const LeaderboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRunDialog(context),
        child: const Icon(Icons.add),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser?.uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userGroups = (userSnapshot.data?.data() as Map<String, dynamic>?)?['groups'] as List<dynamic>? ?? [];

          if (userGroups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('You are not in any groups yet'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showJoinGroupDialog(context),
                    child: const Text('Join a Group'),
                  ),
                ],
              ),
            );
          }

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('groups')
                .doc(userGroups.first)
                .snapshots(),
            builder: (context, groupSnapshot) {
              if (!groupSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final group = groupSnapshot.data!;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildGroupCard(context, group),
                    const SizedBox(height: 20),
                    _buildLeaderboardSection(context, group),
                    const SizedBox(height: 20),
                    if (currentUser != null) _buildRecentRuns(currentUser.uid),
                    const SizedBox(height: 20),
                    _buildParticipationSection(context, group),
                    const SizedBox(height: 20),
                    _buildMembersSection(context, group),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRecentRuns(String userId) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Recent Runs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('user_runs')
                  .doc(userId)
                  .collection('runs')
                  .orderBy('timestamp', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final runs = snapshot.data!.docs;

                if (runs.isEmpty) {
                  return const ListTile(
                    title: Text('No runs recorded yet'),
                    subtitle: Text('Tap the + button to add your first run'),
                  );
                }

                return Column(
                  children: runs.map((run) {
                    final data = run.data() as Map<String, dynamic>;
                    return ListTile(
                      leading: const Icon(Icons.directions_run, color: Colors.orange),
                      title: Text('${data['distance']?.toStringAsFixed(1) ?? '0'} km'),
                      subtitle: Text('${data['duration']} minutes • ${data['date']}'),
                      trailing: Text(
                        '${(data['pace'] as double?)?.toStringAsFixed(1) ?? '0'} min/km',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
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



void _showAddRunDialog(BuildContext context) {
    final distanceController = TextEditingController();
    final durationController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add New Run'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: distanceController,
                    decoration: const InputDecoration(
                      labelText: 'Distance (km)',
                      hintText: '5.2',
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration (minutes)',
                      hintText: '32',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => selectedDate = date);
                      }
                    },
                  ),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      hintText: 'Morning run in the park',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final distance = double.tryParse(distanceController.text);
                  final duration = int.tryParse(durationController.text);

                  if (distance == null || duration == null || distance <= 0 || duration <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter valid distance and duration')),
                    );
                    return;
                  }

                  await _saveRunData(
                    context: context,
                    distance: distance,
                    duration: duration,
                    date: selectedDate,
                    notes: notesController.text,
                  );
                  Navigator.pop(context);
                },
                child: const Text('Save Run'),
              ),
            ],
          );
        },
      ),
    );
  }
  Future<void> _saveRunData({
    required BuildContext context,
    required double distance,
    required int duration,
    required DateTime date,
    String notes = '',
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    if (distance <= 0 || duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Distance and duration must be greater than zero.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('user_runs')
          .doc(userId)
          .collection('runs')
          .add({
        'distance': distance,
        'duration': duration,
        'pace': distance > 0 ? duration / distance : 0,
        'timestamp': Timestamp.fromDate(date),
        'notes': notes,
      });

      await _updateUserStats(userId, distance);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Run saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving run: $e')),
      );
    }
  }



  Future<void> _updateUserStats(String userId, double distance) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({
      'totalDistance': FieldValue.increment(distance),
      'weeklyDistance': FieldValue.increment(distance),
    });

    // Update weekly stats document
    await FirebaseFirestore.instance
        .collection('user_stats')
        .doc(userId)
        .collection('weekly')
        .doc(DateFormat('yyyy-ww').format(now))
        .set({
      'weekStart': weekStart,
      'totalDistance': FieldValue.increment(distance),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
  Widget _buildGroupCard(BuildContext context, DocumentSnapshot group) {
    final data = group.data() as Map<String, dynamic>;
    final membersCount = (data['members'] as List<dynamic>?)?.length ?? 0;
    final totalDistance = data['totalDistance'] ?? 0;
    final groupId = group.id;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('groups').snapshots(),
      builder: (context, allGroupsSnapshot) {
        if (!allGroupsSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        int rank = 1;
        final allGroups = allGroupsSnapshot.data!.docs;
        allGroups.sort((a, b) {
          final aDistance = (a.data() as Map<String, dynamic>)['totalDistance'] ?? 0;
          final bDistance = (b.data() as Map<String, dynamic>)['totalDistance'] ?? 0;
          return bDistance.compareTo(aDistance);
        });
        for (int i = 0; i < allGroups.length; i++) {
          if (allGroups[i].id == group.id) {
            rank = i + 1;
            break;
          }
        }

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  child: Icon(Icons.group, size: 40),
                  backgroundImage: NetworkImage(
                    'https://via.placeholder.com/150/FF6B35/FFFFFF?text=GR',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  data['name'] ?? 'Group',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(context, 'Members', membersCount.toString()),
                    _buildStatItem(context, 'Rank', '#$rank'),
                    _buildStatItem(context, 'KM', totalDistance.toString()),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GroupDetailsPage(groupId: groupId),
                          ),
                        );
                      },
                      child: const Text('View Group'),
                    ),
                    ElevatedButton(
                      onPressed: () => _shareGroupInvite(context, groupId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text('Invite'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _showLeaveGroupDialog(context, group.id),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Leave Group'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLeaveGroupDialog(BuildContext context, String groupId) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // First get the current group data
                final groupDoc = FirebaseFirestore.instance.collection('groups').doc(groupId);
                final groupSnapshot = await groupDoc.get();

                if (!groupSnapshot.exists) {
                  Navigator.pop(context);
                  return;
                }

                final groupData = groupSnapshot.data() as Map<String, dynamic>? ?? {};
                final members = (groupData['members'] as List<dynamic>? ?? []).whereType<String>().toList();

                // Remove user from group
                await groupDoc.update({
                  'members': FieldValue.arrayRemove([currentUser?.uid])
                });

                // Remove group from user's groups
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser?.uid)
                    .update({
                  'groups': FieldValue.arrayRemove([groupId])
                });

                // Check if this was the last member
                if (members.length == 1 && members.contains(currentUser?.uid)) {
                  // Delete the group if it's empty
                  await groupDoc.delete();

                  // Delete all challenges for this group
                  final challenges = await FirebaseFirestore.instance
                      .collection('challenges')
                      .where('groupId', isEqualTo: groupId)
                      .get();

                  for (final doc in challenges.docs) {
                    await doc.reference.delete();
                  }
                }

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Successfully left the group')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error leaving group: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildLeaderboardSection(BuildContext context, DocumentSnapshot group) {
    final data = group.data() as Map<String, dynamic>;
    final members = data['members'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Leaderboard',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where(FieldPath.documentId, whereIn: members)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Sort users by weeklyDistance
                final users = snapshot.data!.docs;
                users.sort((a, b) {
                  final aDistance = (a.data() as Map<String, dynamic>)['weeklyDistance'] ?? 0.0;
                  final bDistance = (b.data() as Map<String, dynamic>)['weeklyDistance'] ?? 0.0;
                  return (bDistance as num).compareTo(aDistance as num);
                });

                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final userData = user.data() as Map<String, dynamic>;
                      final isCurrentUser = user.id == FirebaseAuth.instance.currentUser?.uid;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isCurrentUser ? Colors.orange[100] : null,
                          backgroundImage: NetworkImage(
                            userData['profileImageUrl'] ?? 'https://via.placeholder.com/150',
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isCurrentUser ? Colors.orange : null,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          userData['fullName'] ?? 'No name',
                          style: isCurrentUser
                              ? const TextStyle(fontWeight: FontWeight.bold)
                              : null,
                        ),
                        subtitle: Text('${(userData['weeklyDistance'] ?? 0).toStringAsFixed(1)} km'),
                        trailing: index < 3
                            ? Icon(
                          Icons.emoji_events,
                          color: [Colors.yellow[700], Colors.grey, Colors.brown[300]][index],
                        )
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  Future<List<Map<String, dynamic>>> _fetchAllMembersData(List<dynamic> memberIds) async {
    final users = <Map<String, dynamic>>[];
    for (final id in memberIds) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(id).get();
        users.add({'uid': id, ...?doc.data()});
      } catch (e) {
        print('Error fetching user $id: $e');
      }
    }
    return users;
  }
  Widget _buildParticipationSection(BuildContext context, DocumentSnapshot group) {
    final data = group.data() as Map<String, dynamic>;
    final members = data['members'] as List<dynamic>? ?? [];

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('runs')
          .where('groupId', isEqualTo: group.id)
          .where('date', isGreaterThan: DateTime.now().subtract(const Duration(days: 7)))
          .snapshots(),
      builder: (context, runsSnapshot) {
        final activeMembers = runsSnapshot.hasData
            ? runsSnapshot.data!.docs.map((doc) => doc['userId']).toSet().length
            : 0;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Participation Rate',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bar_chart, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        '${members.isEmpty ? 0 : ((activeMembers / members.length) * 100).toStringAsFixed(0)}% Participation',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text('$activeMembers of ${members.length} members active this week'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: members.isEmpty ? 0 : activeMembers / members.length,
                  backgroundColor: Colors.grey,
                  valueColor: const AlwaysStoppedAnimation(Colors.green),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMembersSection(BuildContext context, DocumentSnapshot group) {
    final data = group.data() as Map<String, dynamic>;
    final members = data['members'] as List<dynamic>? ?? [];
    final currentUser = FirebaseAuth.instance.currentUser;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Group Members (${members.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where(FieldPath.documentId, whereIn: members)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: snapshot.data!.docs.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final user = snapshot.data!.docs[index];
                      final userData = user.data() as Map<String, dynamic>;
                      final isCurrentUser = user.id == currentUser?.uid;

                      return Column(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: isCurrentUser ? Colors.orange[100] : null,
                            backgroundImage: NetworkImage(
                              userData['profileImageUrl'] ?? 'https://via.placeholder.com/150',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userData['fullName'] ?? 'No name',
                            style: TextStyle(
                              fontWeight: isCurrentUser ? FontWeight.bold : null,
                              color: isCurrentUser ? Colors.orange : null,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareGroupInvite(BuildContext context, String groupId) {
    final inviteLink = 'https://yourapp.com/join?groupId=$groupId';
    Share.share('Join my running group! Use this code: $groupId or click: $inviteLink');
  }
}
