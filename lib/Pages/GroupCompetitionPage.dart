import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';

class GroupCompetitionPage extends StatelessWidget {
  const GroupCompetitionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Now 3 tabs with Public Groups
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Group Competition'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showCreateGroupDialog(context),
              tooltip: 'Create New Group',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.leaderboard), text: 'Leaderboard'),
              Tab(icon: Icon(Icons.emoji_events), text: 'Challenges'),
              Tab(icon: Icon(Icons.public), text: 'Public Groups'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            LeaderboardTab(),
            ChallengesTab(),
            PublicGroupsTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showJoinGroupDialog(context),
          child: const Icon(Icons.group_add),
          backgroundColor: Colors.orange,
        ),
      ),
    );
  }

  static void _showCreateGroupDialog(BuildContext context) {
    final TextEditingController groupNameController = TextEditingController();
    final currentUser = FirebaseAuth.instance.currentUser;
    bool isPublic = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Create New Group'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: groupNameController,
                  decoration: const InputDecoration(
                    labelText: 'Group Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Public Group'),
                  value: isPublic,
                  onChanged: (value) => setState(() => isPublic = value),
                ),
                const SizedBox(height: 16),
                const CircleAvatar(
                  radius: 40,
                  child: Icon(Icons.camera_alt),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Upload Logo'),
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
                  if (groupNameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a group name')),
                    );
                    return;
                  }

                  try {
                    final groupDoc = await FirebaseFirestore.instance
                        .collection('groups')
                        .add({
                      'name': groupNameController.text,
                      'createdAt': FieldValue.serverTimestamp(),
                      'createdBy': currentUser?.uid,
                      'members': [currentUser?.uid],
                      'totalDistance': 0,
                      'isPublic': isPublic,
                    });

                    await groupDoc.update({
                      'members': FieldValue.arrayUnion([currentUser?.uid])
                    });

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser?.uid)
                        .update({
                      'groups': FieldValue.arrayUnion([groupDoc.id])
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Group created successfully!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error creating group: $e')),
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

  static void _showJoinGroupDialog(BuildContext context) {
    final TextEditingController groupCodeController = TextEditingController();
    final currentUser = FirebaseAuth.instance.currentUser;

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
                          await group.reference.update({
                            'members': FieldValue.arrayUnion([currentUser?.uid])
                          });

                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(currentUser?.uid)
                              .update({
                            'groups': FieldValue.arrayUnion([group.id])
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
}

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
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final groups = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
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
        );
      },
    );
  }

  Future<void> _joinGroup(BuildContext context, String groupId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    try {
      await FirebaseFirestore.instance.collection('groups').doc(groupId).update({
        'members': FieldValue.arrayUnion([currentUser?.uid])
      });

      await FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).update({
        'groups': FieldValue.arrayUnion([groupId])
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully joined group!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining group: $e')),
      );
    }
  }
}

class LeaderboardTab extends StatelessWidget {
  const LeaderboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
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
                  onPressed: () => GroupCompetitionPage._showJoinGroupDialog(context),
                  child: const Text('Join a Group'),
                ),
              ],
            ),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('groups')
              .where(FieldPath.documentId, whereIn: userGroups)
              .snapshots(),
          builder: (context, groupsSnapshot) {
            if (!groupsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final groups = groupsSnapshot.data!.docs;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildGroupCard(context, groups.first),
                  const SizedBox(height: 20),
                  _buildLeaderboardSection(context, groups.first),
                  const SizedBox(height: 20),
                  _buildParticipationSection(context, groups.first),
                  const SizedBox(height: 20),
                  _buildMembersSection(context, groups.first),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGroupCard(BuildContext context, QueryDocumentSnapshot group) {
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
                await FirebaseFirestore.instance.collection('groups').doc(groupId).update({
                  'members': FieldValue.arrayRemove([currentUser?.uid])
                });

                await FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).update({
                  'groups': FieldValue.arrayRemove([groupId])
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Successfully left the group')),
                );
              } catch (e) {
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

  Widget _buildLeaderboardSection(BuildContext context, QueryDocumentSnapshot group) {
    final data = group.data() as Map<String, dynamic>;
    final members = data['members'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weekly Leaderboard',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const LinearProgressIndicator(
              value: 0.7,
              backgroundColor: Colors.grey,
              valueColor: AlwaysStoppedAnimation(Colors.orange),
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Your position: #5 (42.5 km)'),
                Text('7 days remaining'),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where(FieldPath.documentId, whereIn: members)
                  .orderBy('weeklyDistance', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (context, index) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final user = snapshot.data!.docs[index];
                    final userData = user.data() as Map<String, dynamic>;
                    final isCurrentUser = user.id == FirebaseAuth.instance.currentUser?.uid;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isCurrentUser ? Colors.orange[100] : null,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isCurrentUser ? Colors.orange : null,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        userData['displayName'] ?? 'User ${index + 1}',
                        style: isCurrentUser
                            ? const TextStyle(fontWeight: FontWeight.bold)
                            : null,
                      ),
                      subtitle: Text('${userData['weeklyDistance'] ?? 0} km'),
                      trailing: index < 3
                          ? Icon(
                        Icons.emoji_events,
                        color: [Colors.yellow[700], Colors.grey, Colors.brown[300]][index],
                      )
                          : null,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipationSection(BuildContext context, QueryDocumentSnapshot group) {
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

  Widget _buildMembersSection(BuildContext context, QueryDocumentSnapshot group) {
    final data = group.data() as Map<String, dynamic>;
    final members = data['members'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Group Members',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
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

                      return Column(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(
                              userData['photoURL'] ?? 'https://i.pravatar.cc/150?img=$index',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userData['displayName'] ?? 'User ${index + 1}',
                            style: const TextStyle(fontSize: 12),
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

class ChallengesTab extends StatelessWidget {
  const ChallengesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
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
                const Text('Join a group to participate in challenges'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => GroupCompetitionPage._showJoinGroupDialog(context),
                  child: const Text('Join a Group'),
                ),
              ],
            ),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('challenges')
              .where('groupId', whereIn: userGroups)
              .orderBy('endDate', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final activeChallenges = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['endDate'].toDate().isAfter(DateTime.now());
            }).toList();

            final completedChallenges = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return !data['endDate'].toDate().isAfter(DateTime.now());
            }).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showCreateChallengeDialog(context, userGroups.first),
                      icon: const Icon(Icons.add),
                      label: const Text('Create New Challenge'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (activeChallenges.isNotEmpty) ...[
                    Text(
                      'Active Challenges',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ...activeChallenges.map((doc) => ChallengeCard(
                      challenge: doc.data() as Map<String, dynamic>,
                    )),
                  ],

                  if (completedChallenges.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Completed Challenges',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ...completedChallenges.map((doc) => ChallengeCard(
                      challenge: doc.data() as Map<String, dynamic>,
                      completed: true,
                    )),
                  ],

                  if (activeChallenges.isEmpty && completedChallenges.isEmpty)
                    const Center(child: Text('No challenges yet')),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateChallengeDialog(BuildContext context, String groupId) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController goalController = TextEditingController();
    final TextEditingController durationController = TextEditingController();
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: durationController,
                    decoration: const InputDecoration(
                      labelText: 'Duration (days)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final selectedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (selectedDate != null) {
                        endDate = selectedDate;
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'End Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(endDate?.toString().substring(0, 10) ?? 'Select date'),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
              if (nameController.text.isEmpty ||
                  goalController.text.isEmpty ||
                  durationController.text.isEmpty ||
                  endDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              try {
                await FirebaseFirestore.instance.collection('challenges').add({
                  'name': nameController.text,
                  'goal': double.parse(goalController.text),
                  'duration': int.parse(durationController.text),
                  'endDate': endDate,
                  'groupId': groupId,
                  'createdAt': FieldValue.serverTimestamp(),
                  'participants': [FirebaseAuth.instance.currentUser?.uid],
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Challenge created!')),
                );
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
    final progress = 42.5; // You'd get this from user's progress
    final goal = challenge['goal'] as double;
    final percentage = progress / goal;
    final isOverAchieved = percentage > 1.0;
    final endDate = (challenge['endDate'] as Timestamp).toDate();
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
                  challenge['name'],
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
                Text('Ends ${endDate.toString().substring(0, 10)}'),
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