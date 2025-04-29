import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart'; // Only if you need image picking
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';




class UploadRoutePage extends StatefulWidget {
  const UploadRoutePage({super.key});

  @override
  State<UploadRoutePage> createState() => _UploadRoutePageState();
}

class _UploadRoutePageState extends State<UploadRoutePage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;
  GeoPoint? _selectedLocation;
  String? _selectedAddress;

  // Form fields
  final _nameController = TextEditingController();
  final _distanceController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _difficulty = 'Moderate';
  String _terrain = 'Urban';
  bool _isWellLit = false;
  bool _hasLowTraffic = false;
  List<File> _selectedImages = [];
  bool _isUploading = false;
  double? _uploadProgress;

  final List<String> _difficultyOptions = ['Easy', 'Moderate', 'Hard'];
  final List<String> _terrainOptions = ['Urban', 'Trail', 'Track', 'Mixed'];

  @override
  void dispose() {
    _nameController.dispose();
    _distanceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final pickedFiles = await _picker.pickMultiImage(
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
      );

      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(pickedFiles.map((file) => File(file.path)));
        });
      }
    } catch (e) {
      _showError('Failed to pick images: ${e.toString()}');
    }
  }

  Future<void> _uploadRoute() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      _showError('Please add at least one image');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Upload images first
      final imageUrls = await _uploadImages();

      // Save route data to Firestore
      await _firestore.collection('routes').add({
  'name': _nameController.text,
  'creator': user.displayName ?? 'Anonymous',
  'creatorId': user.uid,
  'distance': double.parse(_distanceController.text),
  'difficulty': _difficulty,
  'terrain': _terrain,
  'description': _descriptionController.text,
  'isWellLit': _isWellLit,
  'hasLowTraffic': _hasLowTraffic,
  'imageUrls': imageUrls,
  'likeCount': 0,
  'likedBy': [],
  'createdAt': FieldValue.serverTimestamp(),
  'rating': 0,
  'reviewCount': 0,
  'safetyRating': 0,
  // Location-related fields
  'location': _selectedLocation != null 
      ? GeoPoint(
          _selectedLocation!.latitude,
          _selectedLocation!.longitude,
        )
      : null,
  'address': _selectedAddress,
  // 'pathCoordinates': _pathCoordinates?.map((point) => {
  //       'latitude': point.latitude,
  //       'longitude': point.longitude,
  //     }).toList(),
  // 'mapImageUrl': _mapImageUrl, // If you're generating static map images
});

      Navigator.pop(context, true); // Return success
    } catch (e) {
      _showError('Failed to upload route: ${e.toString()}');
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = null;
      });
    }
  }

  Future<List<String>> _uploadImages() async {
    final imageUrls = <String>[];
    final totalImages = _selectedImages.length;
    int completed = 0;

    for (final imageFile in _selectedImages) {
      try {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = _storage.ref().child('routes/$fileName');
        
        final uploadTask = ref.putFile(imageFile);
        uploadTask.snapshotEvents.listen((taskSnapshot) {
          setState(() {
            _uploadProgress = (completed + taskSnapshot.bytesTransferred / taskSnapshot.totalBytes) / totalImages;
          });
        });

        await uploadTask;
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
        completed++;
      } catch (e) {
        debugPrint('Failed to upload image: ${e.toString()}');
      }
    }

    return imageUrls;
  }

  Future<void> _pickLocationOnMap() async {
  final LocationResult? result = await showDialog(
    context: context,
    builder: (context) => const LocationPickerDialog(),
  );

  if (result != null) {
    setState(() {
      _selectedLocation = GeoPoint(result.latLng.latitude, result.latLng.longitude);
      _selectedAddress = result.address;
    });
  }
}

Future<void> _getCurrentLocation() async {
  try {
    final position = await Geolocator.getCurrentPosition();
    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    
    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      setState(() {
        _selectedLocation = GeoPoint(position.latitude, position.longitude);
        _selectedAddress = [
          place.street,
          place.locality,
          place.country
        ].where((part) => part?.isNotEmpty ?? false).join(', ');
      });
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error getting location: ${e.toString()}')),
    );
  }
}

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload New Route'),
        actions: [
          if (_isUploading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    value: _uploadProgress,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Route Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Route Name',
                  prefixIcon: Icon(Icons.flag),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a route name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Distance
              TextFormField(
                controller: _distanceController,
                decoration: const InputDecoration(
                  labelText: 'Distance (km)',
                  prefixIcon: Icon(Icons.directions_run),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter distance';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Difficulty Dropdown
              DropdownButtonFormField<String>(
                value: _difficulty,
                decoration: const InputDecoration(
                  labelText: 'Difficulty',
                  prefixIcon: Icon(Icons.terrain),
                ),
                items: _difficultyOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _difficulty = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Terrain Dropdown
              DropdownButtonFormField<String>(
                value: _terrain,
                decoration: const InputDecoration(
                  labelText: 'Terrain',
                  prefixIcon: Icon(Icons.landscape),
                ),
                items: _terrainOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _terrain = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Safety Features
              const Text('Safety Features:', style: TextStyle(fontWeight: FontWeight.bold)),
              CheckboxListTile(
                title: const Text('Well-lit path'),
                value: _isWellLit,
                onChanged: (value) {
                  setState(() {
                    _isWellLit = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                title: const Text('Low traffic'),
                value: _hasLowTraffic,
                onChanged: (value) {
                  setState(() {
                    _hasLowTraffic = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please add a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
      'Route Location',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
    const SizedBox(height: 10),
    
    // Current location display
    if (_selectedLocation != null)
      Column(
        children: [
          Text(
            _selectedAddress ?? 'Selected Location',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  _selectedLocation!.latitude,
                  _selectedLocation!.longitude,
                ),
                zoom: 14,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('selectedLocation'),
                  position: LatLng(
                    _selectedLocation!.latitude,
                    _selectedLocation!.longitude,
                  ),
                ),
              },
            ),
          ),
        ],
      ),
    
    // Location selection buttons
    Row(
  children: [
    Expanded( // Each button takes equal space
      child: ElevatedButton.icon(
        icon: const Icon(Icons.map),
        label: const Text('Pick on Map'),
        onPressed: _pickLocationOnMap,
      ),
    ),
    const SizedBox(width: 10), // Add some spacing
    Expanded( // Each button takes equal space
      child: ElevatedButton.icon(
        icon: const Icon(Icons.my_location),
        label: const Text('Use Current Location'),
        onPressed: _getCurrentLocation,
      ),
    ),
  ],
),
    
              const SizedBox(height: 20),

              // // Image Upload Section
              const Text('Route Images:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Add at least one image (max 5)',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),

              // Selected Images Grid
              if (_selectedImages.isNotEmpty)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Image.file(
                          _selectedImages[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImages.removeAt(index);
                              });
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black54,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 16),
               // Add Images Button
              OutlinedButton.icon(
                onPressed: _selectedImages.length >= 5 ? null : _pickImages,
                icon: const Icon(Icons.add_photo_alternate),
                label: Text(_selectedImages.isEmpty
                    ? 'Add Photos'
                    : 'Add More Photos (${_selectedImages.length}/5)'),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isUploading ? null : _uploadRoute,
                  child: _isUploading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('Uploading...'),
                          ],
                        )
                      : const Text('Upload Route'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LocationResult {
  final LatLng latLng;
  final String? address;

  const LocationResult({
    required this.latLng,
    this.address,
  });
}

class LocationPickerDialog extends StatefulWidget {
  const LocationPickerDialog({super.key});

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  late CameraPosition _initialCameraPosition;
  LatLng? _selectedLocation;
  String? _selectedAddress;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initialCameraPosition = const CameraPosition(
      target: LatLng(0, 0), // Will be updated immediately
      zoom: 14,
    );
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _initialCameraPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 14,
        );
      });
      await _reverseGeocode(LatLng(position.latitude, position.longitude));
    } catch (e) {
      // Fallback to default location if current location fails
      _initialCameraPosition = const CameraPosition(
        target: LatLng(51.5074, -0.1278), // London as fallback
        zoom: 14,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _reverseGeocode(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _selectedAddress = [
            place.street,
            place.locality,
            place.country
          ].where((part) => part?.isNotEmpty ?? false).join(', ');
        });
      }
    } catch (e) {
      debugPrint('Reverse geocoding failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Location'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: GoogleMap(
                      initialCameraPosition: _initialCameraPosition,
                      onTap: (latLng) async {
                        setState(() {
                          _selectedLocation = latLng;
                        });
                        await _reverseGeocode(latLng);
                      },
                      markers: _selectedLocation != null
                          ? {
                              Marker(
                                markerId: const MarkerId('selectedLocation'),
                                position: _selectedLocation!,
                              ),
                            }
                          : {},
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_selectedAddress != null)
                    Text(
                      _selectedAddress!,
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _selectedLocation != null
              ? () => Navigator.pop(
                    context,
                    LocationResult(
                      latLng: _selectedLocation!,
                      address: _selectedAddress,
                    ),
                  )
              : null,
          child: const Text('Select'),
        ),
      ],
    );
  }
}