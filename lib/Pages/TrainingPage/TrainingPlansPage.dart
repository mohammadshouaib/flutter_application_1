import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TrainingPlansPage extends StatefulWidget {
  const TrainingPlansPage({super.key});

  @override
  State<TrainingPlansPage> createState() => _TrainingPlansPageState();
}

class _TrainingPlansPageState extends State<TrainingPlansPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> selectedLevels = ['Beginner', 'Intermediate', 'Advanced'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Plans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: _buildPlansList(),
    );
  }

  Widget _buildPlansList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('training_plans')
          .where('level', whereIn: selectedLevels)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No plans available'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return TrainingPlanCard(
              id: doc.id,
              title: data['title']?.toString() ?? 'Untitled Plan',
              description: data['description']?.toString() ?? '',
              level: data['level']?.toString() ?? 'Unknown',
              duration: data['duration']?.toString() ?? '',
              currentWeek: (data['currentWeek'] as int?) ?? 0,
              totalWeeks: (data['totalWeeks'] as int?) ?? 1,
              icon: _getIconFromString(data['icon']?.toString()),
            );
          },
        );
      },
    );
  }

  IconData _getIconFromString(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'personwalking':
        return FontAwesomeIcons.personWalking;
      case 'personrunning':
        return FontAwesomeIcons.personRunning;
      case 'road':
        return FontAwesomeIcons.road;
      default:
        return FontAwesomeIcons.running;
    }
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Filter Plans'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: const Text('Beginner'),
                  value: selectedLevels.contains('Beginner'),
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      selectedLevels.add('Beginner');
                    } else {
                      selectedLevels.remove('Beginner');
                    }
                  }),
                ),
                CheckboxListTile(
                  title: const Text('Intermediate'),
                  value: selectedLevels.contains('Intermediate'),
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      selectedLevels.add('Intermediate');
                    } else {
                      selectedLevels.remove('Intermediate');
                    }
                  }),
                ),
                CheckboxListTile(
                  title: const Text('Advanced'),
                  value: selectedLevels.contains('Advanced'),
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      selectedLevels.add('Advanced');
                    } else {
                      selectedLevels.remove('Advanced');
                    }
                  }),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {});
                  Navigator.pop(context);
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }
}
class TrainingPlanCard extends StatefulWidget {
  final String id;
  final String title;
  final String description;
  final String level;
  final String duration;
  final int currentWeek;
  final int totalWeeks;
  final IconData icon;

  const TrainingPlanCard({
    super.key,
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.duration,
    required this.currentWeek,
    required this.totalWeeks,
    required this.icon,
  });

  @override
  State<TrainingPlanCard> createState() => _TrainingPlanCardState();
}

class _TrainingPlanCardState extends State<TrainingPlanCard> {
  @override
  Widget build(BuildContext context) {
    final double progress = widget.currentWeek / widget.totalWeeks;
    final bool isStarted = widget.currentWeek > 0;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToPlanDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FaIcon(widget.icon, size: 24, color: Colors.orange),
                  const SizedBox(width: 12),
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(widget.description),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoChip(Icons.timelapse, widget.duration),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.star, widget.level),
                ],
              ),
              if (isStarted) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation(Colors.orange),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Week ${widget.currentWeek}/${widget.totalWeeks}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}% complete',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handlePlanAction(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isStarted ? Colors.orange : Colors.grey[300],
                    foregroundColor: isStarted ? Colors.white : Colors.black,
                  ),
                  child: Text(isStarted ? 'Continue Plan' : 'Start Plan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(text),
      backgroundColor: Colors.grey[100],
      visualDensity: VisualDensity.compact,
    );
  }

  Future<void> _handlePlanAction(BuildContext context) async {
    if (widget.currentWeek == 0) {
      await _startPlan(context);
    }
    _navigateToPlanDetails(context);
  }

  Future<void> _startPlan(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to start a plan')),
        );
        return;
      }

      final progressRef = FirebaseFirestore.instance
          .collection('user_progress')
          .doc(user.uid)
          .collection('plans')
          .doc(widget.id);

      // Check if progress already exists
      final doc = await progressRef.get();

      if (!doc.exists) {
        await progressRef.set({
          'currentWeek': 1,
          'startedAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
          'planId': widget.id,
          'userId': user.uid,
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start plan: ${e.toString()}')),
      );
    }
  }

  void _navigateToPlanDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingPlanDetailsPage(
          planId: widget.id,
          title: widget.title,
          currentWeek: widget.currentWeek,
          totalWeeks: widget.totalWeeks,
        ),
      ),
    );
  }
}

class TrainingPlanDetailsPage extends StatefulWidget {
  final String planId;
  final String title;
  final int currentWeek;
  final int totalWeeks;

  const TrainingPlanDetailsPage({
    super.key,
    required this.planId,
    required this.title,
    required this.currentWeek,
    required this.totalWeeks,
  });

  @override
  State<TrainingPlanDetailsPage> createState() => _TrainingPlanDetailsPageState();
}

class _TrainingPlanDetailsPageState extends State<TrainingPlanDetailsPage> {
  late int _currentWeek;
  late Future<Map<String, dynamic>?> _planData;

  @override
  void initState() {
    super.initState();
    _currentWeek = widget.currentWeek;
    _planData = _loadPlanData();
  }

  Future<Map<String, dynamic>?> _loadPlanData() async {
    final doc = await FirebaseFirestore.instance
        .collection('training_plans')
        .doc(widget.planId)
        .get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _planData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Plan data not found'));
          }

          final weeksData = snapshot.data!['weeks'] as Map<String, dynamic>? ?? {};

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: widget.totalWeeks,
            itemBuilder: (context, index) {
              final weekNumber = index + 1;
              final isCurrentWeek = weekNumber == _currentWeek;
              final isCompleted = weekNumber < _currentWeek;
              final weekData = weeksData[weekNumber.toString()] as Map<String, dynamic>? ?? {};
              final weekDescription = weekData['description']?.toString() ??
                  _generateDefaultWeekDescription(weekNumber);

              return Card(
                color: isCurrentWeek ? Colors.orange[50] : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCurrentWeek
                        ? Colors.orange
                        : isCompleted
                        ? Colors.green
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    child: Text('$weekNumber'),
                  ),
                  title: Text('Week $weekNumber'),
                  subtitle: Text(weekDescription),
                  trailing: isCompleted
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () => _handleWeekSelection(context, weekNumber),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleWeekSelection(BuildContext context, int weekNumber) async {
    if (weekNumber > _currentWeek + 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete previous weeks first')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('user_progress')
            .doc(user.uid)
            .collection('plans')
            .doc(widget.planId)
            .update({
          'currentWeek': weekNumber,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        setState(() {
          _currentWeek = weekNumber;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update progress: ${e.toString()}')),
      );
    }
  }

  String _generateDefaultWeekDescription(int week) {
    if (widget.title.contains('5K')) {
      if (week <= 3) return 'Walk/Run intervals - Building foundation';
      if (week <= 6) return 'Increasing running intervals';
      return 'Continuous running - Preparing for 5K';
    } else if (widget.title.contains('10K')) {
      if (week <= 4) return 'Base building - 3-5K runs';
      if (week <= 8) return 'Endurance development - 5-7K runs';
      return 'Race preparation - 8-10K long runs';
    } else {
      if (week <= 6) return 'Base mileage - 5-10K runs';
      if (week <= 12) return 'Long runs - 10-18K distances';
      return 'Tapering - Race preparation';
    }
  }
}