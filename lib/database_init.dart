import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> initializeTrainingPlans() async {
  final firestore = FirebaseFirestore.instance;

  // 1. Couch to 5K Plan (9 weeks)
  await firestore.collection('training_plans').doc('couch_to_5k').set({
    'title': 'Couch to 5K',
    'description': 'Beginner-friendly 9-week program',
    'level': 'Beginner',
    'duration': '9 weeks',
    'totalWeeks': 9,
    'icon': 'personWalking',
    'createdAt': FieldValue.serverTimestamp(),
    'weeks': {
      '1': {
        'description': 'Walk/Run intervals - Building foundation',
        'workouts': [
          {
            'day': 1,
            'type': 'Interval',
            'totalTime': 30,
            'intervals': [
              {'action': 'Walk', 'duration': 5, 'unit': 'minutes'},
              {'action': 'Run', 'duration': 1, 'unit': 'minute'},
              {'action': 'Walk', 'duration': 1.5, 'unit': 'minutes'},
              {'repeat': 8, 'of': 'Run/Walk'}
            ]
          },
          {
            'day': 2,
            'type': 'Rest',
            'notes': 'Active recovery or complete rest'
          },
          {
            'day': 3,
            'type': 'Repeat',
            'repeatDay': 1
          }
        ]
      },
      '2': {
        'description': 'Increasing running intervals',
        'workouts': [
          {
            'day': 1,
            'type': 'Interval',
            'totalTime': 31,
            'intervals': [
              {'action': 'Walk', 'duration': 5, 'unit': 'minutes'},
              {'action': 'Run', 'duration': 1.5, 'unit': 'minutes'},
              {'action': 'Walk', 'duration': 2, 'unit': 'minutes'},
              {'repeat': 6, 'of': 'Run/Walk'}
            ]
          },
          // Continue with days 2-3...
        ]
      },
      // Weeks 3-8 would follow similar pattern...
      '9': {
        'description': 'Final week - 5K ready!',
        'workouts': [
          {
            'day': 1,
            'type': 'Continuous',
            'action': 'Run',
            'duration': 30,
            'unit': 'minutes',
            'target': '5K distance'
          }
        ]
      }
    }
  });

  // 2. 10K Challenge Plan (12 weeks)
  await firestore.collection('training_plans').doc('10k_challenge').set({
    'title': '10K Challenge',
    'description': 'Build endurance for 10K races',
    'level': 'Intermediate',
    'duration': '12 weeks',
    'totalWeeks': 12,
    'icon': 'personRunning',
    'createdAt': FieldValue.serverTimestamp(),
    'weeks': {
      '1': {
        'description': 'Base building',
        'workouts': [
          {
            'day': 1,
            'type': 'Interval',
            'totalDistance': 5,
            'unit': 'km',
            'intervals': [
              {'action': 'Warmup', 'duration': 10, 'unit': 'minutes'},
              {'action': 'Run', 'duration': 1, 'unit': 'km'},
              {'action': 'Walk', 'duration': 1, 'unit': 'minute'},
              {'repeat': 3, 'of': 'Run/Walk'},
              {'action': 'Cooldown', 'duration': 5, 'unit': 'minutes'}
            ]
          },
          {
            'day': 2,
            'type': 'Tempo',
            'description': 'Steady pace run',
            'duration': 25,
            'unit': 'minutes'
          },
          // Continue with other days...
        ]
      },
      // Weeks 2-11...
      '12': {
        'description': 'Race week!',
        'workouts': [
          {
            'day': 1,
            'type': 'Taper',
            'action': 'Easy run',
            'duration': 20,
            'unit': 'minutes'
          },
          {
            'day': 3,
            'type': 'Race',
            'action': '10K Run',
            'notes': 'Race day! Aim for consistent pace'
          }
        ]
      }
    }
  });

  // 3. Half Marathon Prep (16 weeks)
  await firestore.collection('training_plans').doc('half_marathon').set({
    'title': 'Half Marathon Prep',
    'description': 'Complete your first 21K',
    'level': 'Advanced',
    'duration': '16 weeks',
    'totalWeeks': 16,
    'icon': 'road',
    'createdAt': FieldValue.serverTimestamp(),
    'weeks': {
      '1': {
        'description': 'Base mileage',
        'totalDistance': 25,
        'unit': 'km',
        'workouts': [
          {
            'day': 1,
            'type': 'Easy',
            'distance': 5,
            'unit': 'km',
            'pace': 'Conversational'
          },
          {
            'day': 3,
            'type': 'Speed',
            'intervals': [
              {'action': 'Warmup', 'duration': 15, 'unit': 'minutes'},
              {'action': 'Run', 'distance': 400, 'unit': 'meters', 'pace': '5K race pace'},
              {'action': 'Recover', 'duration': 90, 'unit': 'seconds'},
              {'repeat': 6, 'of': 'Run/Recover'}
            ]
          },
          {
            'day': 5,
            'type': 'Long',
            'distance': 8,
            'unit': 'km',
            'pace': 'Slow and steady'
          }
        ]
      },
      // Weeks 2-15...
      '16': {
        'description': 'Race week - Taper time',
        'workouts': [
          {
            'day': 1,
            'type': 'Easy',
            'distance': 5,
            'unit': 'km',
            'notes': 'Keep it light'
          },
          {
            'day': 3,
            'type': 'Short Tempo',
            'distance': 3,
            'unit': 'km',
            'pace': 'Goal race pace'
          },
          {
            'day': 6,
            'type': 'Race',
            'action': 'Half Marathon',
            'notes': 'Trust your training!'
          }
        ]
      }
    }
  });

  print('All training plans initialized successfully');
}