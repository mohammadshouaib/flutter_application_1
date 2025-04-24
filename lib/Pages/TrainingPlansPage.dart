import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class TrainingPlansPage extends StatelessWidget {
  const TrainingPlansPage({super.key});

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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          TrainingPlanCard(
            title: 'Couch to 5K',
            description: 'Beginner-friendly 9-week program',
            level: 'Beginner',
            duration: '9 weeks',
            currentWeek: 3,
            totalWeeks: 9,
            icon: FontAwesomeIcons.personWalking,
          ),
          SizedBox(height: 16),
          TrainingPlanCard(
            title: '10K Challenge',
            description: 'Build endurance for 10K races',
            level: 'Intermediate',
            duration: '12 weeks',
            currentWeek: 0,
            totalWeeks: 12,
            icon: FontAwesomeIcons.personRunning,
          ),
          SizedBox(height: 16),
          TrainingPlanCard(
            title: 'Half Marathon Prep',
            description: 'Complete your first 21K',
            level: 'Advanced',
            duration: '16 weeks',
            currentWeek: 5,
            totalWeeks: 16,
            icon: FontAwesomeIcons.road,
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Plans'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('Beginner'),
              value: true,
              onChanged: (v) {},
            ),
            CheckboxListTile(
              title: const Text('Intermediate'),
              value: true,
              onChanged: (v) {},
            ),
            CheckboxListTile(
              title: const Text('Advanced'),
              value: true,
              onChanged: (v) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

class TrainingPlanCard extends StatelessWidget {
  final String title;
  final String description;
  final String level;
  final String duration;
  final int currentWeek;
  final int totalWeeks;
  final IconData icon;

  const TrainingPlanCard({
    super.key,
    required this.title,
    required this.description,
    required this.level,
    required this.duration,
    required this.currentWeek,
    required this.totalWeeks,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = currentWeek / totalWeeks;
    final bool isStarted = currentWeek > 0;

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
                  FaIcon(icon, size: 24, color: Colors.orange),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(description),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoChip(Icons.timelapse, duration),
                  const SizedBox(width: 8),
                  _buildInfoChip(Icons.star, level),
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
                      'Week $currentWeek/$totalWeeks',
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
                  onPressed: () => _navigateToPlanDetails(context),
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

  void _navigateToPlanDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingPlanDetailsPage(
          title: title,
          currentWeek: currentWeek,
          totalWeeks: totalWeeks,
        ),
      ),
    );
  }
}

class TrainingPlanDetailsPage extends StatelessWidget {
  final String title;
  final int currentWeek;
  final int totalWeeks;

  const TrainingPlanDetailsPage({
    super.key,
    required this.title,
    required this.currentWeek,
    required this.totalWeeks,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: totalWeeks,
        itemBuilder: (context, index) {
          final weekNumber = index + 1;
          final isCurrentWeek = weekNumber == currentWeek;
          final isCompleted = weekNumber < currentWeek;

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
              subtitle: Text(_generateWeekDescription(weekNumber)),
              trailing: isCompleted
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () {
                // Navigate to week details
              },
            ),
          );
        },
      ),
    );
  }

  String _generateWeekDescription(int week) {
    if (title.contains('5K')) {
      return _getCouchTo5KDescription(week);
    } else if (title.contains('10K')) {
      return _get10KDescription(week);
    } else {
      return _getHalfMarathonDescription(week);
    }
  }

  String _getCouchTo5KDescription(int week) {
    if (week <= 3) return 'Walk/Run intervals - Building foundation';
    if (week <= 6) return 'Increasing running intervals';
    return 'Continuous running - Preparing for 5K';
  }

  String _get10KDescription(int week) {
    if (week <= 4) return 'Base building - 3-5K runs';
    if (week <= 8) return 'Endurance development - 5-7K runs';
    return 'Race preparation - 8-10K long runs';
  }

  String _getHalfMarathonDescription(int week) {
    if (week <= 6) return 'Base mileage - 5-10K runs';
    if (week <= 12) return 'Long runs - 10-18K distances';
    return 'Tapering - Race preparation';
  }
}