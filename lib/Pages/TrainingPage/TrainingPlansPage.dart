import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TrainingPlansPage extends StatefulWidget {
  const TrainingPlansPage({super.key});

  @override
  State<TrainingPlansPage> createState() => _TrainingPlansPageState();
}

class _TrainingPlansPageState extends State<TrainingPlansPage> {
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('training_plans')
            .where('level', whereIn: selectedLevels)
            .snapshots(),
        builder: (context, snapshot) {
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
              final plan = snapshot.data!.docs[index];
              return TrainingPlanCard(
                id: plan.id,
                title: plan['title'] ?? 'Untitled Plan',
                description: plan['description'] ?? '',
                level: plan['level'] ?? 'Unknown',
                duration: plan['duration'] ?? '',
                totalWeeks: (plan['totalWeeks'] ?? 1).toInt(),
                icon: _getIconFromString(plan['icon']),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIconFromString(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'personwalking': return FontAwesomeIcons.personWalking;
      case 'personrunning': return FontAwesomeIcons.personRunning;
      case 'road': return FontAwesomeIcons.road;
      default: return FontAwesomeIcons.running;
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
                  onChanged: (v) => setState(() => v!
                      ? selectedLevels.add('Beginner')
                      : selectedLevels.remove('Beginner')
                  ),
                ),
                // Add Intermediate and Advanced checkboxes similarly
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
  final int totalWeeks;
  final IconData icon;

  const TrainingPlanCard({
    super.key,
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.duration,
    required this.totalWeeks,
    required this.icon,
  });

  @override
  State<TrainingPlanCard> createState() => _TrainingPlanCardState();
}

class _TrainingPlanCardState extends State<TrainingPlanCard> {
  int _currentWeek = 0;
  StreamSubscription? _progressSubscription;

  @override
  void initState() {
    super.initState();
    _listenToUserProgress();
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    super.dispose();
  }

  void _listenToUserProgress() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _progressSubscription = FirebaseFirestore.instance
        .collection('user_progress')
        .doc(user.uid)
        .collection('plans')
        .doc(widget.id)
        .snapshots()
        .listen((doc) {
      if (mounted) {
        setState(() {
          _currentWeek = doc.data()?['currentWeek'] ?? 0;
        });
      }
    });
  }

  Future<void> _startPlan() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('user_progress')
          .doc(user.uid)
          .collection('plans')
          .doc(widget.id)
          .set({
        'currentWeek': 1,
        'startedAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'planId': widget.id,
        'userId': user.uid,
      });
    } catch (e) {
      debugPrint('Error starting plan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _currentWeek / widget.totalWeeks;
    final isStarted = _currentWeek > 0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 8),
              Text(widget.description),
              const SizedBox(height: 16),
              Row(
                children: [
                  Chip(label: Text(widget.duration), avatar: Icon(Icons.timelapse)),
                  const SizedBox(width: 8),
                  Chip(label: Text(widget.level), avatar: Icon(Icons.star)),
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
                    Text('Week $_currentWeek/${widget.totalWeeks}'),
                    Text('${(progress * 100).toStringAsFixed(0)}% complete'),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => isStarted
                      ? _navigateToPlanDetails(context)
                      : _startPlan().then((_) => _navigateToPlanDetails(context)),
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

  void _navigateToPlanDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingPlanDetailsPage(
          planId: widget.id,
          title: widget.title,
          currentWeek: _currentWeek,
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

  Future<void> _updateProgress(int weekNumber) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || weekNumber > _currentWeek + 1) return;

    await FirebaseFirestore.instance
        .collection('user_progress')
        .doc(user.uid)
        .collection('plans')
        .doc(widget.planId)
        .update({
      'currentWeek': weekNumber,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    setState(() => _currentWeek = weekNumber);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _planData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final weeks = (snapshot.data?['weeks'] as Map<String, dynamic>?) ?? {};

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: widget.totalWeeks,
            itemBuilder: (context, index) {
              final weekNum = index + 1;
              final week = weeks[weekNum.toString()] ?? {};
              final isCurrent = weekNum == _currentWeek;
              final isCompleted = weekNum < _currentWeek;

              return Card(
                color: isCurrent ? Colors.orange[50] : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCurrent
                        ? Colors.orange
                        : isCompleted ? Colors.green : Colors.grey,
                    child: Text('$weekNum', style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text('Week $weekNum'),
                  subtitle: Text(week['description'] ?? _getDefaultWeekDesc(weekNum)),
                  trailing: isCompleted ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: () => _updateProgress(weekNum),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _getDefaultWeekDesc(int week) {
    if (widget.title.contains('5K')) {
      return week <= 3 ? 'Walk/Run intervals' :
      week <= 6 ? 'Increasing running' : 'Continuous running';
    } else if (widget.title.contains('10K')) {
      return week <= 4 ? 'Base building' :
      week <= 8 ? 'Endurance development' : 'Race preparation';
    } else {
      return week <= 6 ? 'Base mileage' :
      week <= 12 ? 'Long runs' : 'Tapering';
    }
  }
}