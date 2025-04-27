import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/Pages/UploadRoute.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class RouteFeedPage extends StatefulWidget {
  const RouteFeedPage({super.key});

  @override
  State<RouteFeedPage> createState() => _RouteFeedPageState();
}

class _RouteFeedPageState extends State<RouteFeedPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final  _auth = FirebaseAuth.instance;
  String _selectedTerrain = 'All';
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Running Routes'),
      ),
      body: Column(
        children: [
          // Terrain filter chips
          _buildTerrainFilter(),
          
          // StreamBuilder to fetch and display routes
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _selectedTerrain == 'All'
                  ? _firestore.collection('routes').snapshots()
                  : _firestore.collection('routes')
                      .where('terrain', isEqualTo: _selectedTerrain)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No routes found'));
                }

                // Convert Firestore docs to Route objects
                final routes = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Route(
                    id: doc.id,
                    likeCount: data["likeCount"],
                    likedBy: data["likedBy"],
                    name: data['name'] ?? 'Unnamed Route',
                    creator: data['creator'] ?? 'Unknown',
                    distance: (data['distance'] ?? 0).toDouble(),
                    difficulty: data['difficulty'] ?? 'Medium',
                    terrain: data['terrain'] ?? 'Mixed',
                    rating: (data['rating'] ?? 0).toDouble(),
                    reviewCount: data['reviewCount'] ?? 0,
                    safetyRating: (data['safetyRating'] ?? 0).toDouble(),
                    isWellLit: data['isWellLit'] ?? false,
                    hasLowTraffic: data['hasLowTraffic'] ?? false,
                    imageUrl: data['imageUrl'] ?? '',
                  );
                }).toList();

                return ListView.builder(
                  itemCount: routes.length,
                  itemBuilder: (context, index) {
                    return _buildRouteCard(routes[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.directions_run),
        onPressed: () {
          Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UploadRoutePage(),
                        ),
          );
        },
        backgroundColor: Colors.orange,
      ),

    );
  }

  Widget _buildTerrainFilter() {
    const terrains = ['All', 'Urban', 'Trail', 'Track'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: terrains.map((terrain) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(terrain),
              selected: _selectedTerrain == terrain,
              onSelected: (selected) {
                setState(() {
                  _selectedTerrain = selected ? terrain : 'All';
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRouteCard(Route route) {
    final isLiked = _currentUserId != null && route.likedBy.contains(_currentUserId);
    
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route image (keep existing implementation)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              route.imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 180,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.terrain, size: 50, color: Colors.grey),
                ),
              ),
              loadingBuilder: (_, child, progress) {
                return progress == null 
                    ? child 
                    : Container(
                        height: 180,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
              },
            ),
          ),
          
          // Route details
           Padding(
            padding: const EdgeInsets.all(12),
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
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : null,
                          ),
                          onPressed: () => _toggleLike(route),
                        ),
                        Text(route.likeCount.toString()),
                      ],
                    ),
                  ],
                ),
                
                // Creator and distance
                Text(
                  'By ${route.creator} • ${route.distance} km',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                
                const SizedBox(height: 8),
                
                // Tags (difficulty, terrain, features)
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      label: Text(route.difficulty),
                      backgroundColor: _getDifficultyColor(route.difficulty),
                    ),
                    Chip(
                      label: Text(route.terrain),
                      backgroundColor: Colors.blue[50],
                    ),
                    if (route.isWellLit)
                      const Chip(
                        label: Text('Well-lit'),
                        avatar: Icon(Icons.light_mode, size: 16),
                      ),
                    if (route.hasLowTraffic)
                      const Chip(
                        label: Text('Low traffic'),
                        avatar: Icon(Icons.traffic, size: 16),
                      ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Rating and safety
                Row(
                  children: [
                    RatingBarIndicator(
                      rating: route.rating,
                      itemBuilder: (context, _) => const Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      itemCount: 5,
                      itemSize: 20,
                    ),
                    const SizedBox(width: 4),
                    Text('(${route.reviewCount})'),
                    const Spacer(),
                    const Icon(Icons.security, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text('${route.safetyRating.toStringAsFixed(1)}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color? _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green[50];
      case 'moderate':
        return Colors.orange[50];
      case 'hard':
        return Colors.red[50];
      default:
        return Colors.grey[200];
    }
  }

  Future<void> _toggleLike(Route route) async {
    if (_currentUserId == null) {
      // Show login prompt if user isn't authenticated
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to like routes')),
      );
      return;
    }

    try {
      final routeRef = _firestore.collection('routes').doc(route.id);
      final isLiked = route.likedBy.contains(_currentUserId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(routeRef);
        if (!doc.exists) return;

        final currentLikedBy = List<String>.from(doc['likedBy'] ?? []);
        final newLikedBy = [...currentLikedBy];
        final newLikeCount = doc['likeCount'] ?? 0;

        if (isLiked) {
          newLikedBy.remove(_currentUserId);
        } else {
          newLikedBy.add(_currentUserId!);
        }

        transaction.update(routeRef, {
          'likedBy': newLikedBy,
          'likeCount': isLiked ? newLikeCount - 1 : newLikeCount + 1,
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _toggleFavorite(String routeId) async {
    // Implement favorite functionality
    // Example: await _firestore.collection('users').doc(userId).update({
    //   'favorites': FieldValue.arrayUnion([routeId])
    // });
  }
}

class Route {
  final String id;
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
  final int likeCount;
  final List<dynamic> likedBy;

  Route({
    required this.id,
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
    required this.likeCount,
    required this.likedBy,
  });

  factory Route.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Route(
      id: doc.id,
      name: data['name'] ?? 'Unnamed Route',
      creator: data['creator'] ?? 'Unknown',
      distance: (data['distance'] ?? 0).toDouble(),
      difficulty: data['difficulty'] ?? 'Medium',
      terrain: data['terrain'] ?? 'Mixed',
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      safetyRating: (data['safetyRating'] ?? 0).toDouble(),
      isWellLit: data['isWellLit'] ?? false,
      hasLowTraffic: data['hasLowTraffic'] ?? false,
      imageUrl: data['imageUrl'] ?? '',
      likeCount: data['likeCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }
}