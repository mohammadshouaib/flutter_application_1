import 'package:flutter/material.dart';

class TrainingPlansPage extends StatelessWidget {
  const TrainingPlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Light grey background
      appBar: AppBar(
        title: const Text('Blank Page'),
      ),
      body: const Center(
        child: Text('This page is intentionally left blank'),
      ),
    );
  }
}