import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class GroupCompetitionPage extends StatelessWidget {
  const GroupCompetitionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
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
        floatingActionButton: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            final groups = (snapshot.data?.data() as Map<String, dynamic>?)?['groups'] as List<dynamic>? ?? [];
            return groups.isEmpty
                ? FloatingActionButton(
              onPressed: () => _showJoinGroupDialog(context),
              child: const Icon(Icons.group_add),
              backgroundColor: Colors.orange,
            )
                : Container();
          },
        ),
      ),
    );
  }

  static void _showCreateGroupDialog(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).get().then((doc) {
      final groups = (doc.data() as Map<String, dynamic>?)?['groups'] as List<dynamic>? ?? [];
      if (groups.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can only join one group at a time')),
        );
        return;
      }

      final TextEditingController groupNameController = TextEditingController();
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
    });
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
                  _buildParticipationSection(context, group),
                  const SizedBox(height: 20),
                  _buildMembersSection(context, group),
                ],
              ),
            );
          },
        );
      },
    );
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
  Future<Map<String, dynamic>> _fetchUserData(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return userDoc.data() ?? {};
    } catch (e) {
      print('Error fetching user data: $e');
      return {};
    }
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
            onPressed: () => GroupCompetitionPage._showJoinGroupDialog(context),
            child: const Text('Join a Group'),
          ),
        ],
      ),
    );
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



