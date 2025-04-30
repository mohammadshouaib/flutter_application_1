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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Plans'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  centerTitle: true,

      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('training_plans')
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
                  Chip(label: Text(widget.duration)),
                  const SizedBox(width: 8),
                  Chip(label: Text(widget.level)),
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
    Key? key,
    required this.planId,
    required this.title,
    required this.currentWeek,
    required this.totalWeeks,
  }) : super(key: key);

  @override
  State<TrainingPlanDetailsPage> createState() => _TrainingPlanDetailsPageState();
}

class _TrainingPlanDetailsPageState extends State<TrainingPlanDetailsPage> {
  late int _currentWeek;
  late Future<Map<String, dynamic>> _planData;
  Map<String, List<bool>> _weekCompletion = {};

  @override
  void initState() {
    super.initState();
    _currentWeek = widget.currentWeek;
    _planData = _loadPlanData();
    _loadCompletionData();
  }

  Future<Map<String, dynamic>> _loadPlanData() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('training_plans')
        .doc(widget.planId)
        .get();
    return doc.data() as Map<String, dynamic>;
  }

  Future<void> _loadCompletionData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('user_progress')
        .doc(user.uid)
        .collection('plans')
        .doc(widget.planId)
        .get();

    if (doc.exists) {
      setState(() {
        _weekCompletion = Map<String, List<bool>>.from(
          (doc.data() as Map<String, dynamic>)['weekCompletion'] ?? {},
        );
      });
    }
  }

  Future<void> _updateDayCompletion(int weekNum, int dayIndex, bool completed) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Initialize week if not exists
    _weekCompletion.putIfAbsent(weekNum.toString(), () => List.filled(3, false));

    // Update completion status
    setState(() {
      _weekCompletion[weekNum.toString()]![dayIndex] = completed;
    });

    // Calculate if week is completed
    final allDaysCompleted = _weekCompletion[weekNum.toString()]!.every((day) => day);
    final newCurrentWeek = allDaysCompleted ? weekNum + 1 : _currentWeek;

    await FirebaseFirestore.instance
        .collection('user_progress')
        .doc(user.uid)
        .collection('plans')
        .doc(widget.planId)
        .update({
      'weekCompletion': _weekCompletion,
      'currentWeek': newCurrentWeek,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    if (allDaysCompleted && weekNum == _currentWeek) {
      setState(() {
        _currentWeek = newCurrentWeek;
      });
    }
  }

  void _showWeekDetails(int weekNum, Map<String, dynamic> planData) {
    final weekData = planData['weeks'][weekNum.toString()];
    if (weekData == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text('Week $weekNum Details'),
          centerTitle: true,
        backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,),
          body: WeekWorkoutsView(
            weekNum: weekNum,
            weekData: weekData,
            dayCompletion: _weekCompletion[weekNum.toString()] ?? List.filled(3, false),
            onDayTapped: (dayIndex, completed) =>
                _updateDayCompletion(weekNum, dayIndex, completed),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title),
      centerTitle: true,
        backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
      ),
      
      body: FutureBuilder<Map<String, dynamic>>(
        future: _planData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Failed to load plan data'));
          }

          final planData = snapshot.data!;
          final weeks = planData['weeks'] as Map<String, dynamic>;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: widget.totalWeeks,
            itemBuilder: (context, index) {
              final weekNum = index + 1;
              final week = weeks[weekNum.toString()] ?? {};
              final isCurrent = weekNum == _currentWeek;
              final isCompleted = weekNum < _currentWeek;
              final isLocked = weekNum > _currentWeek;
              final weekProgress = _weekCompletion[weekNum.toString()]?.where((d) => d).length ?? 0;

              return Card(
                color: isCurrent ? Colors.orange[50] : null,
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: isLocked ? null : () => _showWeekDetails(weekNum, planData),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isCurrent
                                  ? Colors.orange
                                  : isCompleted ? Colors.green : Colors.grey,
                              child: Text(
                                '$weekNum',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Week $weekNum',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Text(
                                    week['description'] ?? 'Training week',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            if (isCompleted)
                              const Icon(Icons.check, color: Colors.green),
                            if (isLocked)
                              const Icon(Icons.lock, color: Colors.grey),
                          ],
                        ),
                        if (isCurrent) ...[
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: weekProgress / 3,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation(Colors.green),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$weekProgress of 3 days completed',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class WeekWorkoutsView extends StatefulWidget {
  final int weekNum;
  final Map<String, dynamic> weekData;
  final List<bool> dayCompletion;
  final Function(int dayIndex, bool completed) onDayTapped;

  const WeekWorkoutsView({
    Key? key,
    required this.weekNum,
    required this.weekData,
    required this.dayCompletion,
    required this.onDayTapped,
  }) : super(key: key);

  @override
  State<WeekWorkoutsView> createState() => _WeekWorkoutsViewState();
}

class _WeekWorkoutsViewState extends State<WeekWorkoutsView> {
  late List<bool> _dayCompletion;

  @override
  void initState() {
    super.initState();
    _dayCompletion = List.from(widget.dayCompletion);
  }

  void _handleDayTapped(int index, bool completed) {
    setState(() {
      _dayCompletion[index] = completed;
    });
    widget.onDayTapped(index, completed);
  }

  @override
  Widget build(BuildContext context) {
    final workouts = (widget.weekData['workouts'] as List?) ?? [];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      
      itemCount: workouts.length,
      itemBuilder: (context, index) {
        final workout = workouts[index];
        final isCompleted = index < _dayCompletion.length ? _dayCompletion[index] : false;

        return GestureDetector(
          onTap: () => _handleDayTapped(index, !isCompleted),
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            color: isCompleted ? Colors.green[50] : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: isCompleted,
                        onChanged: (bool? value) {
                          if (value != null) {
                            _handleDayTapped(index, value);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Day ${workout['day']} - ${(workout['type'] ?? '').toUpperCase()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (workout['type'] == 'Interval') _buildIntervalWorkout(workout),
                  if (workout['type'] == 'Tempo') _buildTempoWorkout(workout),
                  if (workout['type'] == 'Easy') _buildEasyWorkout(workout),
                  if (workout['type'] == 'Long') _buildLongWorkout(workout),
                  if (workout['type'] == 'Hills') _buildHillsWorkout(workout),
                  if (workout['type'] == 'Rest') _buildRestWorkout(workout),
                  if (workout['type'] == 'Race') _buildRaceWorkout(workout),
                  if (workout['type'] == 'Taper') _buildTaperWorkout(workout),

                  if (workout['notes'] != null && (workout['notes'] as String).isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Notes: ${workout['notes']}',
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildIntervalWorkout(Map<String, dynamic> workout) {
    final intervals = (workout['intervals'] as List?) ?? [];
    final totalDistance = workout['totalDistance'];
    final totalTime = workout['totalTime'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (totalDistance != null)
          Text('Total Distance: $totalDistance ${workout['unit']}'),
        if (totalTime != null)
          Text('Total Time: $totalTime ${workout['unit']}'),
        const SizedBox(height: 8),
        ...intervals.map((interval) {
          if (interval.containsKey('repeat')) {
            return Text('• Repeat ${interval['repeat']}x: ${interval['of']}');
          }
          return Text(
              '• ${interval['action']}: ${interval['duration']} ${interval['unit']}');
        }).toList(),
      ],
    );
  }

  Widget _buildTempoWorkout(Map<String, dynamic> workout) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (workout['description'] != null)
          Text(workout['description']),
        if (workout['duration'] != null)
          Text('Duration: ${workout['duration']} ${workout['unit']}'),
        if (workout['distance'] != null)
          Text('Distance: ${workout['distance']} ${workout['unit']}'),
      ],
    );
  }

  Widget _buildEasyWorkout(Map<String, dynamic> workout) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (workout['description'] != null)
          Text(workout['description']),
        Text('Easy pace: ${workout['duration']} ${workout['unit']}'),
      ],
    );
  }

  Widget _buildLongWorkout(Map<String, dynamic> workout) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (workout['description'] != null)
          Text(workout['description']),
        Text('Distance: ${workout['distance']} ${workout['unit']}'),
      ],
    );
  }

  Widget _buildHillsWorkout(Map<String, dynamic> workout) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (workout['description'] != null)
          Text(workout['description']),
        Text('Repeats: ${workout['repeats']}'),
        Text('Hill length: ${workout['hillLength']} ${workout['unit']}'),
      ],
    );
  }

  Widget _buildRestWorkout(Map<String, dynamic> workout) {
    return const Text('Rest day - recovery is important!');
  }

  Widget _buildRaceWorkout(Map<String, dynamic> workout) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Race: ${workout['action']}'),
        if (workout['notes'] != null)
          Text(workout['notes']),
      ],
    );
  }

  Widget _buildTaperWorkout(Map<String, dynamic> workout) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Taper: ${workout['action']}'),
        Text('Duration: ${workout['duration']} ${workout['unit']}'),
      ],
    );
  }



  Widget _buildStandardWorkout(Map<String, dynamic> workout) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (workout['distance'] != null)
          Text('Distance: ${workout['distance']} ${workout['unit']}'),
        if (workout['duration'] != null)
          Text('Duration: ${workout['duration']} ${workout['unit']}'),
        if (workout['pace'] != null)
          Text('Pace: ${workout['pace']}'),
        if (workout['notes'] != null)
          Text('Notes: ${workout['notes']}'),
      ],
    );
  }




}
