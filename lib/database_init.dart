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
          {
            'day': 2,
            'type': 'Rest',
            'notes': 'Stretch and hydrate'
          },
          {
            'day': 3,
            'type': 'Repeat',
            'repeatDay': 1
          }
        ]
      },
      '3': {
        'description': 'Building endurance',
        'workouts': [
          {
            'day': 1,
            'type': 'Interval',
            'totalTime': 32,
            'intervals': [
              {'action': 'Walk', 'duration': 5, 'unit': 'minutes'},
              {'action': 'Run', 'duration': 2, 'unit': 'minutes'},
              {'action': 'Walk', 'duration': 2, 'unit': 'minutes'},
              {'repeat': 5, 'of': 'Run/Walk'}
            ]
          },
          {
            'day': 2,
            'type': 'Rest',
            'notes': 'Focus on nutrition'
          },
          {
            'day': 3,
            'type': 'Repeat',
            'repeatDay': 1
          }
        ]
      },
      '4': {
        'description': 'Longer running intervals',
        'workouts': [
          {
            'day': 1,
            'type': 'Interval',
            'totalTime': 33,
            'intervals': [
              {'action': 'Walk', 'duration': 5, 'unit': 'minutes'},
              {'action': 'Run', 'duration': 3, 'unit': 'minutes'},
              {'action': 'Walk', 'duration': 2, 'unit': 'minutes'},
              {'repeat': 4, 'of': 'Run/Walk'}
            ]
          },
          {
            'day': 2,
            'type': 'Rest',
            'notes': 'Light yoga recommended'
          },
          {
            'day': 3,
            'type': 'Repeat',
            'repeatDay': 1
          }
        ]
      },
      '5': {
        'description': 'More running, less walking',
        'workouts': [
          {
            'day': 1,
            'type': 'Interval',
            'totalTime': 34,
            'intervals': [
              {'action': 'Walk', 'duration': 5, 'unit': 'minutes'},
              {'action': 'Run', 'duration': 5, 'unit': 'minutes'},
              {'action': 'Walk', 'duration': 2, 'unit': 'minutes'},
              {'repeat': 3, 'of': 'Run/Walk'}
            ]
          },
          {
            'day': 2,
            'type': 'Rest',
            'notes': 'Cross-training optional'
          },
          {
            'day': 3,
            'type': 'Repeat',
            'repeatDay': 1
          }
        ]
      },
      '6': {
        'description': 'Sustaining longer runs',
        'workouts': [
          {
            'day': 1,
            'type': 'Interval',
            'totalTime': 35,
            'intervals': [
              {'action': 'Walk', 'duration': 5, 'unit': 'minutes'},
              {'action': 'Run', 'duration': 8, 'unit': 'minutes'},
              {'action': 'Walk', 'duration': 2, 'unit': 'minutes'},
              {'repeat': 2, 'of': 'Run/Walk'}
            ]
          },
          {
            'day': 2,
            'type': 'Rest',
            'notes': 'Foam rolling suggested'
          },
          {
            'day': 3,
            'type': 'Repeat',
            'repeatDay': 1
          }
        ]
      },
      '7': {
        'description': 'Running dominance',
        'workouts': [
          {
            'day': 1,
            'type': 'Continuous',
            'action': 'Run',
            'duration': 20,
            'unit': 'minutes',
            'notes': 'No walking intervals'
          },
          {
            'day': 2,
            'type': 'Rest',
            'notes': 'Focus on sleep'
          },
          {
            'day': 3,
            'type': 'Continuous',
            'action': 'Run',
            'duration': 22,
            'unit': 'minutes'
          }
        ]
      },
      '8': {
        'description': 'Near 5K readiness',
        'workouts': [
          {
            'day': 1,
            'type': 'Continuous',
            'action': 'Run',
            'duration': 25,
            'unit': 'minutes'
          },
          {
            'day': 2,
            'type': 'Rest',
            'notes': 'Stay hydrated'
          },
          {
            'day': 3,
            'type': 'Continuous',
            'action': 'Run',
            'duration': 28,
            'unit': 'minutes'
          }
        ]
      },
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
          },
          {
            'day': 2,
            'type': 'Rest',
            'notes': 'Prepare mentally for the run'
          },
          {
            'day': 3,
            'type': 'Race',
            'action': '5K Run',
            'notes': 'Congratulations on completing Couch to 5K!'
          }
        ]
      }
    }
  });

  //print('Couch to 5K plan initialized successfully');


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
          {
            'day': 3,
            'type': 'Easy',
            'description': 'Recovery run',
            'duration': 20,
            'unit': 'minutes'
          }
        ]
      },
      '2': {
        'description': 'Increasing distance',
        'workouts': [
          {
            'day': 1,
            'type': 'Interval',
            'intervals': [
              {'action': 'Warmup', 'duration': 10, 'unit': 'minutes'},
              {'action': 'Run', 'duration': 1.5, 'unit': 'km'},
              {'action': 'Walk', 'duration': 1, 'unit': 'minute'},
              {'repeat': 3, 'of': 'Run/Walk'},
              {'action': 'Cooldown', 'duration': 5, 'unit': 'minutes'}
            ]
          },
          {
            'day': 2,
            'type': 'Tempo',
            'description': 'Tempo run',
            'duration': 30,
            'unit': 'minutes'
          },
          {
            'day': 3,
            'type': 'Long',
            'description': 'Long slow distance',
            'distance': 5,
            'unit': 'km'
          }
        ]
      },
      '3': {
        'description': 'Building aerobic base',
        'workouts': [
          {
            'day': 1,
            'type': 'Interval',
            'intervals': [
              {'action': 'Warmup', 'duration': 10, 'unit': 'minutes'},
              {'action': 'Run', 'duration': 2, 'unit': 'km'},
              {'action': 'Walk', 'duration': 1, 'unit': 'minute'},
              {'repeat': 2, 'of': 'Run/Walk'},
              {'action': 'Cooldown', 'duration': 5, 'unit': 'minutes'}
            ]
          },
          {
            'day': 2,
            'type': 'Tempo',
            'description': 'Pace practice',
            'duration': 35,
            'unit': 'minutes'
          },
          {
            'day': 3,
            'type': 'Long',
            'distance': 6,
            'unit': 'km'
          }
        ]
      },
      '4': {
        'description': 'Steady progress',
        'workouts': [
          {
            'day': 1,
            'type': 'Interval',
            'intervals': [
              {'action': 'Warmup', 'duration': 10, 'unit': 'minutes'},
              {'action': 'Run', 'duration': 2.5, 'unit': 'km'},
              {'action': 'Walk', 'duration': 1, 'unit': 'minute'},
              {'repeat': 2, 'of': 'Run/Walk'},
              {'action': 'Cooldown', 'duration': 5, 'unit': 'minutes'}
            ]
          },
          {
            'day': 2,
            'type': 'Tempo',
            'duration': 40,
            'unit': 'minutes'
          },
          {
            'day': 3,
            'type': 'Long',
            'distance': 7,
            'unit': 'km'
          }
        ]
      },
      '5': {
        'description': 'Midway push',
        'workouts': [
          {
            'day': 1,
            'type': 'Interval',
            'intervals': [
              {'action': 'Warmup', 'duration': 10, 'unit': 'minutes'},
              {'action': 'Run', 'duration': 3, 'unit': 'km'},
              {'action': 'Walk', 'duration': 1, 'unit': 'minute'},
              {'repeat': 2, 'of': 'Run/Walk'},
              {'action': 'Cooldown', 'duration': 5, 'unit': 'minutes'}
            ]
          },
          {
            'day': 2,
            'type': 'Tempo',
            'duration': 45,
            'unit': 'minutes'
          },
          {
            'day': 3,
            'type': 'Long',
            'distance': 8,
            'unit': 'km'
          }
        ]
      },
      '6': {
        'description': 'Consolidation week',
        'workouts': [
          {
            'day': 1,
            'type': 'Easy',
            'duration': 25,
            'unit': 'minutes'
          },
          {
            'day': 2,
            'type': 'Tempo',
            'duration': 50,
            'unit': 'minutes'
          },
          {
            'day': 3,
            'type': 'Long',
            'distance': 9,
            'unit': 'km'
          }
        ]
      },
      '7': {
        'description': 'Building strength',
        'workouts': [
          {
            'day': 1,
            'type': 'Hills',
            'description': 'Hill repeats',
            'repeats': 5,
            'hillLength': 200,
            'unit': 'meters'
          },
          {
            'day': 2,
            'type': 'Tempo',
            'duration': 55,
            'unit': 'minutes'
          },
          {
            'day': 3,
            'type': 'Long',
            'distance': 10,
            'unit': 'km'
          }
        ]
      },
      '8': {
        'description': 'Increasing stamina',
        'workouts': [
          {
            'day': 1,
            'type': 'Interval',
            'intervals': [
              {'action': 'Run', 'duration': 1, 'unit': 'km'},
              {'action': 'Recover', 'duration': 90, 'unit': 'seconds'},
              {'repeat': 6, 'of': 'Run/Recover'}
            ]
          },
          {
            'day': 2,
            'type': 'Tempo',
            'duration': 60,
            'unit': 'minutes'
          },
          {
            'day': 3,
            'type': 'Long',
            'distance': 11,
            'unit': 'km'
          }
        ]
      },
      '9': {
        'description': 'Peak training',
        'workouts': [
          {
            'day': 1,
            'type': 'Interval',
            'intervals': [
              {'action': 'Run', 'duration': 1.5, 'unit': 'km'},
              {'action': 'Recover', 'duration': 90, 'unit': 'seconds'},
              {'repeat': 5, 'of': 'Run/Recover'}
            ]
          },
          {
            'day': 2,
            'type': 'Tempo',
            'duration': 60,
            'unit': 'minutes'
          },
          {
            'day': 3,
            'type': 'Long',
            'distance': 12,
            'unit': 'km'
          }
        ]
      },
      '10': {
        'description': 'Taper begins',
        'workouts': [
          {
            'day': 1,
            'type': 'Easy',
            'duration': 30,
            'unit': 'minutes'
          },
          {
            'day': 2,
            'type': 'Tempo',
            'duration': 40,
            'unit': 'minutes'
          },
          {
            'day': 3,
            'type': 'Long',
            'distance': 8,
            'unit': 'km'
          }
        ]
      },
      '11': {
        'description': 'Race prep',
        'workouts': [
          {
            'day': 1,
            'type': 'Easy',
            'duration': 20,
            'unit': 'minutes'
          },
          {
            'day': 2,
            'type': 'Tempo',
            'duration': 30,
            'unit': 'minutes'
          },
          {
            'day': 3,
            'type': 'Long',
            'distance': 6,
            'unit': 'km'
          }
        ]
      },
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
            'day': 2,
            'type': 'Rest',
            'notes': 'Stay fresh for race day'
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

  //print('10K Challenge plan initialized successfully');

  // 3. Half Marathon Prep (16 weeks)
  await firestore.collection('training_plans').doc('half_marathon').set({
    'title': 'Half Marathon Challenge',
    'description': 'Train to complete a half marathon confidently',
    'level': 'Intermediate',
    'duration': '12 weeks',
    'totalWeeks': 12,
    'icon': 'roadRunning',
    'createdAt': FieldValue.serverTimestamp(),
    'weeks': {
      '1': {
        'description': 'Base endurance building',
        'workouts': [
          {
            'day': 1,
            'type': 'Easy',
            'duration': 30,
            'unit': 'minutes'
          },
          {
            'day': 2,
            'type': 'Tempo',
            'description': 'Comfortably hard pace',
            'duration': 20,
            'unit': 'minutes'
          },
          {
            'day': 3,
            'type': 'Long',
            'distance': 6,
            'unit': 'km'
          }
        ]
      },
      '2': {
        'description': 'Adding strength and stamina',
        'workouts': [
          {
            'day': 1,
            'type': 'Hills',
            'description': 'Hill sprints',
            'repeats': 6,
            'hillLength': 150,
            'unit': 'meters'
          },
          {
            'day': 2,
            'type': 'Tempo',
            'duration': 25,
            'unit': 'minutes'
          },
          {
            'day': 3,
            'type': 'Long',
            'distance': 8,
            'unit': 'km'
          }
        ]
      },
      '3': {
        'description': 'Progressive building',
        'workouts': [
          {
            'day': 1,
            'type': 'Interval',
            'intervals': [
              {'action': 'Warmup', 'duration': 10, 'unit': 'minutes'},
              {'action': 'Run', 'duration': 800, 'unit': 'meters'},
              {'action': 'Walk', 'duration': 90, 'unit': 'seconds'},
              {'repeat': 4, 'of': 'Run/Walk'},
              {'action': 'Cooldown', 'duration': 5, 'unit': 'minutes'}
            ]
          },
          {
            'day': 2,
            'type': 'Easy',
            'duration': 35,
            'unit': 'minutes'
          },
          {
            'day': 3,
            'type': 'Long',
            'distance': 10,
            'unit': 'km'
          }
        ]
      },
      '4': {
        'description': 'Pushing endurance',
        'workouts': [
          {
            'day': 1,
            'type': 'Interval',
            'intervals': [
              {'action': 'Warmup', 'duration': 10, 'unit': 'minutes'},
              {'action': 'Run', 'duration': 1, 'unit': 'km'},
              {'action': 'Walk', 'duration': 90, 'unit': 'seconds'},
              {'repeat': 5, 'of': 'Run/Walk'},
              {'action': 'Cooldown', 'duration': 5, 'unit': 'minutes'}
            ]
          },
          {
            'day': 2,
            'type': 'Tempo',
            'duration': 30,
            'unit': 'minutes'
          },
          {
            'day': 3,
            'type': 'Long',
            'distance': 12,
            'unit': 'km'
          }
        ]
      },
      '5': {
        'description': 'Mid-program strength',
        'workouts': [
          {
            'day': 1,
            'type': 'Hills',
            'description': 'Longer hill sprints',
            'repeats': 7,
            'hillLength': 200,
            'unit': 'meters'
          },
          {
            'day': 2,
            'type': 'Tempo',
            'duration': 35,
            'unit': 'minutes'
          },
          {
            'day': 3,
            'type': 'Long',
            'distance': 14,
            'unit': 'km'
          }
        ]
      },
      '6': {
        'description': 'Endurance building week',
        'workouts': [
          {
            'day': 1,
            'type': 'Interval',
            'intervals': [
              {'action': 'Run', 'duration': 1.2, 'unit': 'km'},
              {'action': 'Walk', 'duration': 90, 'unit': 'seconds'},
              {'repeat': 4, 'of': 'Run/Walk'}
            ]
          },
          {
            'day': 2,
            'type': 'Easy',
            'duration': 40,
            'unit': 'minutes'
          },
          {
            'day': 3,
            'type': 'Long',
            'distance': 16,
            'unit': 'km'
          }
        ]
      },
      '7': {
        'description': 'Sharpening speed',
        'workouts': [
          {
            'day': 1,
            'type': 'Interval',
            'intervals': [
              {'action': 'Run', 'duration': 400, 'unit': 'meters'},
              {'action': 'Recover', 'duration': 1, 'unit': 'minute'},
              {'repeat': 8, 'of': 'Run/Recover'}
            ]
          },
          {
            'day': 2,
            'type': 'Tempo',
            'duration': 40,
            'unit': 'minutes'
          },
          {
            'day': 3,
            'type': 'Long',
            'distance': 18,
            'unit': 'km'
          }
        ]
      },
      '8': {
        'description': 'Volume consolidation',
        'workouts': [
          {
            'day': 1,
            'type': 'Easy',
            'duration': 45,
            'unit': 'minutes'
          },
          {
            'day': 2,
            'type': 'Tempo',
            'duration': 45,
            'unit': 'minutes'
          },
          {
            'day': 3,
            'type': 'Long',
            'distance': 19,
            'unit': 'km'
          }
        ]
      },
      '9': {
        'description': 'Peak training',
        'workouts': [
          {
            'day': 1,
            'type': 'Interval',
            'intervals': [
              {'action': 'Run', 'duration': 1.5, 'unit': 'km'},
              {'action': 'Recover', 'duration': 90, 'unit': 'seconds'},
              {'repeat': 5, 'of': 'Run/Recover'}
            ]
          },
          {
            'day': 2,
            'type': 'Tempo',
            'duration': 50,
            'unit': 'minutes'
          },
          {
            'day': 3,
            'type': 'Long',
            'distance': 20,
            'unit': 'km'
          }
        ]
      },
      '10': {
        'description': 'Taper starts',
        'workouts': [
          {
            'day': 1,
            'type': 'Easy',
            'duration': 30,
            'unit': 'minutes'
          },
          {
            'day': 2,
            'type': 'Tempo',
            'duration': 30,
            'unit': 'minutes'
          },
          {
            'day': 3,
            'type': 'Long',
            'distance': 14,
            'unit': 'km'
          }
        ]
      },
      '11': {
        'description': 'Final sharpening',
        'workouts': [
          {
            'day': 1,
            'type': 'Easy',
            'duration': 20,
            'unit': 'minutes'
          },
          {
            'day': 2,
            'type': 'Tempo',
            'duration': 20,
            'unit': 'minutes'
          },
          {
            'day': 3,
            'type': 'Long',
            'distance': 8,
            'unit': 'km'
          }
        ]
      },
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
            'day': 2,
            'type': 'Rest',
            'notes': 'Stay fresh'
          },
          {
            'day': 3,
            'type': 'Race',
            'action': 'Half Marathon',
            'notes': 'Pace yourself and enjoy!'
          }
        ]
      }
    }
  });

  print('Half Marathon Prep (FULL 16 Weeks) initialized successfully!');
}