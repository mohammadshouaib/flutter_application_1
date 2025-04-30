import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import 'ChallengesPage.dart';
import 'LeaderBoardPage.dart';
import 'PublicGroupsTab.dart';

class GroupCompetitionPage extends StatelessWidget {
  const GroupCompetitionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Group Competition'),
          backgroundColor: Colors.orange,
          centerTitle: true,
                  foregroundColor: Colors.white,
                  automaticallyImplyLeading: false,

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



