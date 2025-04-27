import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';



class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RunTracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String userName = "Alex";
  final double weeklyDistance = 24.5; // km
  final String nextWorkout = "5K Tempo Run";
  final double workoutProgress = 0.65;
  final int clanMembersActive = 8;
  final List<RouteSuggestion> suggestedRoutes = [
    RouteSuggestion(
      name: "Lakeside Loop",
      distance: 5.2,
      rating: 4.8,
      reviewCount: 126,
      terrain: "Trail",
    ),
    RouteSuggestion(
      name: "Downtown Dash",
      distance: 3.8,
      rating: 4.3,
      reviewCount: 89,
      terrain: "Urban",
    ),
    RouteSuggestion(
      name: "Park Perimeter",
      distance: 7.5,
      rating: 4.9,
      reviewCount: 154,
      terrain: "Mixed",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with greeting and stats
              _buildHeader(context),
              
              // Main action button
              _buildStartRunButton(),
              
              // Training snapshot
              _buildTrainingSnapshot(),
              
              // Community activity
              _buildCommunitySection(),
              
              // Route suggestions
              _buildRouteSuggestions(),
              
              // Footer navigation
              // _buildFooterNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hi, $userName!",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "${weeklyDistance.toStringAsFixed(1)} km this week",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildStartRunButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: FilledButton.icon(
        icon: const Icon(Icons.directions_run, size: 24),
        label: const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            "START A RUN",
            style: TextStyle(fontSize: 18),
          ),
        ),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {},
      ),
    );
  }

  Widget _buildTrainingSnapshot() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {}, // Navigate to training program
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "TRAINING PLAN",
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "Next: $nextWorkout",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: workoutProgress,
                borderRadius: BorderRadius.circular(4),
                minHeight: 8,
                color: Colors.blue.shade600,
                backgroundColor: Colors.blue.shade100,
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "${(workoutProgress * 100).toInt()}% complete",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommunitySection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "YOUR CLAN ACTIVITY",
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.blue,
                    child: Text(
                      "CR",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "City Runners",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "$clanMembersActive members ran today",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {}, // Navigate to clan page
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteSuggestions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "SUGGESTED ROUTES",
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: suggestedRoutes.length,
              itemBuilder: (context, index) {
                return _buildRouteCard(suggestedRoutes[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(RouteSuggestion route) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {}, // Navigate to route details
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.map,
                      size: 40,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  route.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "${route.distance} km • ${route.terrain}",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    RatingBarIndicator(
                      rating: route.rating,
                      itemBuilder: (context, _) => const Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      itemCount: 5,
                      itemSize: 16,
                      unratedColor: Colors.amber.withAlpha(50),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "(${route.reviewCount})",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RouteSuggestion {
  final String name;
  final double distance;
  final double rating;
  final int reviewCount;
  final String terrain;

  RouteSuggestion({
    required this.name,
    required this.distance,
    required this.rating,
    required this.reviewCount,
    required this.terrain,
  });
}