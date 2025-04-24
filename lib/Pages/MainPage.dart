import 'package:flutter/material.dart';

import 'GroupCompetitionPage.dart';
import 'HomeDashboard.dart';
import 'RouteRecommendationsPage.dart';
import 'TrainingPlansPage.dart';
import 'package:flutter_application_1/Profile/profile.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RunTogether',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainNavigationPage(),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  @override
  _MainNavigationPageState createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomeDashboard(),
    RouteRecommendationsPage(),
    GroupCompetitionPage(),
    TrainingPlansPage(),
    ProfileScreen()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Routes'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Groups'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_run), label: 'Training'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
        child: Icon(Icons.directions_run),
        onPressed: () {
          // Start a new run
        },
        backgroundColor: Colors.orange,
      )
          : null,
    );
  }
}