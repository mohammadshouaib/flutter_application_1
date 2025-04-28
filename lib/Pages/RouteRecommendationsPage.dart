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
        automaticallyImplyLeading: false,
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
                    name: data['name'] ?? 'Unnamed Route',
                    creator: data['creator'] ?? 'Unknown',
                    distance: (data['distance'] ?? 0).toDouble(),
                    difficulty: data['difficulty'] ?? 'Medium',
                    terrain: data['terrain'] ?? 'Mixed',
                    rating: (data['rating'] ?? 0).toDouble(),
                    reviewCount: data['reviewCount'] ?? 0,
                    description: data['description']??"",
                    safetyRating: (data['safetyRating'] ?? 0).toDouble(),
                    isWellLit: data['isWellLit'] ?? false,
                    hasLowTraffic: data['hasLowTraffic'] ?? false,
                    imageUrls: List<String>.from(data['imageUrls'] ?? []), // Changed to imageUrls
                    likeCount: data['likeCount'] ?? 0,
                    likedBy: List<String>.from(data['likedBy'] ?? []),
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
        child: Icon(Icons.add),
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
  final pageController = PageController(viewportFraction: 1); // Shows 100% of next image

  return Card(
    margin: const EdgeInsets.all(8),
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image carousel with controlled scrolling
        SizedBox(
          height: 180,
          child: route.imageUrls.isNotEmpty
              ? Stack(
                  children: [
                    PageView.builder(
                      controller: pageController,
                      itemCount: route.imageUrls.length,
                      physics: const PageScrollPhysics(parent: BouncingScrollPhysics()),
                      onPageChanged: (index) {
                        // Optional: Track current page index if needed
                      },
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              route.imageUrls[index],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(Icons.terrain, size: 50, color: Colors.grey),
                                ),
                              ),
                              loadingBuilder: (_, child, progress) {
                                return progress == null 
                                    ? child 
                                    : Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    // Position indicators
                    if (route.imageUrls.length > 1)
                      Positioned(
                        bottom: 8,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            route.imageUrls.length,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              : Container(
                  height: 180,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.terrain, size: 50, color: Colors.grey),
                  ),
                ),
        ),
        
        // Rest of your existing card content
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
              
              // Description section - NEW
              if (route.description?.isNotEmpty ?? false)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        height: 1.4,
                      ),
                      maxLines: 3, // Show 3 lines initially
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (route.description!.length > 150) // Show "Read more" if long
                      GestureDetector(
                        onTap: () => _showFullDescription(route.description!),
                        child: Text(
                          'Read more',
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
                
              
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
              // Rating only (moved to right)
              Row(
                children: [
                  const Spacer(), // Pushes content to the right
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
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}


void _showFullDescription(String description) {
  showModalBottomSheet(
    context: context,
    builder: (context) => Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
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
  final String? creatorId; // Added for security rules
  final double distance;
  final String difficulty;
  final String terrain;
  final String? description; // Added if needed
  final double rating;
  final int reviewCount;
  final double safetyRating;
  final bool isWellLit;
  final bool hasLowTraffic;
  final List<String> imageUrls; // Changed from String imageUrl to List<String>
  final int likeCount;
  final List<String> likedBy; // Explicitly typed as List<String>

  Route({
    required this.id,
    required this.name,
    required this.creator,
    this.creatorId,
    required this.distance,
    required this.difficulty,
    required this.terrain,
    this.description,
    required this.rating,
    required this.reviewCount,
    required this.safetyRating,
    required this.isWellLit,
    required this.hasLowTraffic,
    required this.imageUrls, // Now accepts a list
    required this.likeCount,
    required this.likedBy,
  });

  factory Route.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Route(
      id: doc.id,
      name: data['name'] ?? 'Unnamed Route',
      creator: data['creator'] ?? 'Unknown',
      creatorId: data['creatorId'], // Optional
      distance: (data['distance'] ?? 0).toDouble(),
      difficulty: data['difficulty'] ?? 'Medium',
      terrain: data['terrain'] ?? 'Mixed',
      description: data['description'], // Optional
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      safetyRating: (data['safetyRating'] ?? 0).toDouble(),
      isWellLit: data['isWellLit'] ?? false,
      hasLowTraffic: data['hasLowTraffic'] ?? false,
      imageUrls: List<String>.from(data['imageUrls'] ?? []), // Convert to List<String>
      likeCount: data['likeCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []), // Ensures List<String>
    );
  }

  // Helper to get the first image (for thumbnails)
  String get firstImageUrl => imageUrls.isNotEmpty ? imageUrls[0] : '';

  // Convert to Map (useful for updates)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'creator': creator,
      'creatorId': creatorId,
      'distance': distance,
      'difficulty': difficulty,
      'terrain': terrain,
      'description': description,
      'isWellLit': isWellLit,
      'hasLowTraffic': hasLowTraffic,
      'imageUrls': imageUrls,
      'likeCount': likeCount,
      'likedBy': likedBy,
      // Note: rating/reviewCount/safetyRating are likely updated separately
    };
  }
}