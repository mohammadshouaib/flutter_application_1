import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';


// Edit Profile Screen
class EditProfileScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String userBio;
  final String? profileImageUrl;
  final Function(String, String, String, String?) onSave;

  const EditProfileScreen({
    required this.userName,
    required this.userEmail,
    required this.userBio,
    required this.profileImageUrl,
    required this.onSave,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _bioController;
  File? _selectedImage;
  String? _newImageUrl;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userName);
    _emailController = TextEditingController(text: widget.userEmail);
    _bioController = TextEditingController(text: widget.userBio);
    _newImageUrl = widget.profileImageUrl;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _newImageUrl = null; // Clear URL when new local image is selected
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error selecting image: ${e.toString()}")),
      );
    }
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;
    
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Upload new image first if selected
      if (_selectedImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_images/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        
        await ref.putFile(_selectedImage!);
        _newImageUrl = await ref.getDownloadURL();
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'fullName': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'bio': _bioController.text.trim(),
            if (_newImageUrl != null) 'profileImageUrl': _newImageUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Update Auth if needed
      if (_emailController.text.trim() != user.email) {
        await user.updateEmail(_emailController.text.trim());
      }
      if (_nameController.text.trim() != user.displayName) {
        await user.updateDisplayName(_nameController.text.trim());
      }

      // Notify parent and close
      widget.onSave(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _bioController.text.trim(),
        _newImageUrl,
      );
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveChanges,
            child: _isSaving 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("Save"),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _getProfileImage(),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Name",
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter your name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
            controller: _emailController,
            enabled: false, // Makes the field completely uneditable and grayed out
            decoration: const InputDecoration(
              labelText: "Email",
              prefixIcon: Icon(Icons.email),
            ),
          ),

            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Bio",
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.info),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _saveChanges,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider? _getProfileImage() {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    } else if (_newImageUrl != null) {
      return NetworkImage(_newImageUrl!);
    } else if (widget.profileImageUrl != null) {
      return NetworkImage(widget.profileImageUrl!);
    }
    return const NetworkImage(
      "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200",
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}