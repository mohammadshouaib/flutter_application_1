import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';



class RouteRecommendationsPage extends StatelessWidget {
  const RouteRecommendationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RunRoute',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const RouteFeedPage(),
    );
  }
}

class RouteFeedPage extends StatefulWidget {
  const RouteFeedPage({super.key});

  @override
  State<RouteFeedPage> createState() => _RouteFeedPageState();
}

class _RouteFeedPageState extends State<RouteFeedPage> {
  String _selectedTerrain = 'All';
  String _selectedDistance = 'All';
  String _selectedDifficulty = 'All';
  String _selectedSort = 'Popular';

  final List<Route> _routes = [
    Route(
      name: "Central Park Loop",
      creator: "Jane Runner",
      distance: 5.2,
      difficulty: "Moderate",
      terrain: "Trail",
      rating: 4.7,
      reviewCount: 128,
      safetyRating: 4.5,
      isWellLit: true,
      hasLowTraffic: true,
      imageUrl: "https://example.com/central-park.jpg",
    ),
    Route(
      name: "Downtown Dash",
      creator: "Mike Jogger",
      distance: 3.8,
      difficulty: "Easy",
      terrain: "Urban",
      rating: 4.2,
      reviewCount: 87,
      safetyRating: 3.8,
      isWellLit: true,
      hasLowTraffic: false,
      imageUrl: "https://example.com/downtown.jpg",
    ),
    Route(
      name: "River Trail",
      creator: "Sarah Marathon",
      distance: 8.5,
      difficulty: "Hard",
      terrain: "Trail",
      rating: 4.9,
      reviewCount: 56,
      safetyRating: 4.7,
      isWellLit: false,
      hasLowTraffic: true,
      imageUrl: "https://example.com/river-trail.jpg",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Routes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Location and filter section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      "New York, NY",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text("Terrain"),
                        selected: _selectedTerrain != 'All',
                        onSelected: (selected) => _showTerrainFilter(),
                      ),
                      const SizedBox(width: 4),
                      FilterChip(
                        label: const Text("Distance"),
                        selected: _selectedDistance != 'All',
                        onSelected: (selected) => _showDistanceFilter(),
                      ),
                      const SizedBox(width: 4),
                      FilterChip(
                        label: const Text("Difficulty"),
                        selected: _selectedDifficulty != 'All',
                        onSelected: (selected) => _showDifficultyFilter(),
                      ),
                      const SizedBox(width: 4),
                      FilterChip(
                        label: const Text("Sort"),
                        selected: _selectedSort != 'Popular',
                        onSelected: (selected) => _showSortFilter(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Routes list
          Expanded(
            child: ListView.builder(
              itemCount: _routes.length,
              itemBuilder: (context, index) {
                return _buildRouteCard(_routes[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(Route route) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route image placeholder
          Container(
            height: 150,
            color: Colors.grey[300],
            child: Center(child: Text(route.name)),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      route.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.favorite_border),
                      onPressed: () {
                        // Implement like functionality
                      },
                    ),
                  ],
                ),
                Text(
                  "By ${route.creator}",
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChip(Icons.directions_run, "${route.distance} km"),
                    const SizedBox(width: 8),
                    _buildInfoChip(Icons.terrain, route.terrain),
                    const SizedBox(width: 8),
                    _buildInfoChip(Icons.speed, route.difficulty),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    RatingBarIndicator(
                      rating: route.rating,
                      itemBuilder: (context, index) => const Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      itemCount: 5,
                      itemSize: 20.0,
                      direction: Axis.horizontal,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${route.rating} (${route.reviewCount})",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    if (route.isWellLit)
                      _buildSafetyChip(Icons.lightbulb_outline, "Well-lit"),
                    if (route.hasLowTraffic)
                      _buildSafetyChip(Icons.traffic, "Low traffic"),
                    _buildSafetyChip(Icons.security, "Safety: ${route.safetyRating}"),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Navigate to route details
                    },
                    child: const Text("VIEW DETAILS"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(text),
      backgroundColor: Colors.grey[200],
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildSafetyChip(IconData icon, String text) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.green),
      label: Text(text),
      backgroundColor: Colors.green[50],
      visualDensity: VisualDensity.compact,
    );
  }

  void _showTerrainFilter() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Filter by Terrain"),
            ),
            Column(
              children: [
                _buildFilterOption("All", _selectedTerrain, (value) {
                  setState(() => _selectedTerrain = value);
                  Navigator.pop(context);
                }),
                _buildFilterOption("Urban", _selectedTerrain, (value) {
                  setState(() => _selectedTerrain = value);
                  Navigator.pop(context);
                }),
                _buildFilterOption("Trail", _selectedTerrain, (value) {
                  setState(() => _selectedTerrain = value);
                  Navigator.pop(context);
                }),
                _buildFilterOption("Track", _selectedTerrain, (value) {
                  setState(() => _selectedTerrain = value);
                  Navigator.pop(context);
                }),
              ],
            ),
          ],
        );
      },
    );
  }

  // Similar methods for other filters
  void _showDistanceFilter() {
    // Implement distance filter
  }

  void _showDifficultyFilter() {
    // Implement difficulty filter
  }

  void _showSortFilter() {
    // Implement sort filter
  }

  Widget _buildFilterOption(String value, String selectedValue, Function(String) onSelected) {
    return ListTile(
      title: Text(value),
      trailing: value == selectedValue ? const Icon(Icons.check) : null,
      onTap: () => onSelected(value),
    );
  }
}

class Route {
  final String name;
  final String creator;
  final double distance;
  final String difficulty;
  final String terrain;
  final double rating;
  final int reviewCount;
  final double safetyRating;
  final bool isWellLit;
  final bool hasLowTraffic;
  final String imageUrl;

  Route({
    required this.name,
    required this.creator,
    required this.distance,
    required this.difficulty,
    required this.terrain,
    required this.rating,
    required this.reviewCount,
    required this.safetyRating,
    required this.isWellLit,
    required this.hasLowTraffic,
    required this.imageUrl,
  });
}