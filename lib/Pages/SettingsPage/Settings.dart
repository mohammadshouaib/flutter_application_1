import 'package:flutter/material.dart';
import 'package:flutter_application_1/Login/Signup/signinorsignup.dart';
import 'package:flutter_application_1/Pages/SettingsPage/EditSettings.dart';
import 'package:flutter_application_1/Pages/SettingsPage/helpSupport.dart';
import 'package:flutter_application_1/Pages/SettingsPage/privacyPolicy.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // User Profile Data
  String userName = "";
  String userEmail = "";
  String userBio = "";
  File? profileImage;
  String? profileImageUrl;

  // App Settings
  bool isDarkMode = false;
  bool voiceGuidance = true;
  bool autoPause = true;
  bool safetyAlerts = true;
  String distanceUnit = "km";
  String temperatureUnit = "°C";

  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final userData = await _fetchUserData();
      final authUser = FirebaseAuth.instance.currentUser;
      
      if (userData != null && authUser != null) {
        setState(() {
          userName = userData['fullName'] ?? authUser.displayName ?? 'No Name';
          userEmail = authUser.email ?? userData['email'] ?? 'No Email';
          userBio = userData['bio'] ?? 'No bio yet';
          profileImageUrl = userData['profileImageUrl'];
          
          // Load settings
          isDarkMode = userData['settings']?['darkMode'] ?? false;
          voiceGuidance = userData['settings']?['voiceGuidance'] ?? true;
          distanceUnit = userData['settings']?['distanceUnit'] ?? 'km';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading data: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>?> _fetchUserData() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      return docSnapshot.data();
    }
    return null;
  } catch (e) {
    print("Error fetching user data: $e");
    return null;
  }
}

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() => profileImage = File(image.path));
        await _uploadProfileImage(File(image.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error selecting image: ${e.toString()}")),
      );
    }
  }

  Future<void> _uploadProfileImage(File image) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images/${user.uid}.jpg');
      
      await ref.putFile(image);
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'profileImageUrl': url});

      setState(() => profileImageUrl = url);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
        backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  automaticallyImplyLeading: false,

      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          _buildProfileSection(),
          const SizedBox(height: 24),

          // App Preferences
          _buildSectionHeader("Preferences"),
          
          _buildUnitSelector("Distance Unit", ["km", "mi"], distanceUnit, (value) {
            _updateSetting('distanceUnit', value);
          }),
          const SizedBox(height: 24),

          // Safety Features
          _buildSectionHeader("Safety Features"),
          _buildSettingTile(
            "Emergency Contacts",
            Icons.emergency,
            () => _navigateToEmergencyContacts(),
          ),
          const SizedBox(height: 24),

          // App Information
          _buildSectionHeader("About"),
          _buildSettingTile(
            "Help & Support",
            Icons.help_outline,
            () => _openHelpCenter(),
          ),
          _buildSettingTile(
            "Privacy Policy",
            Icons.privacy_tip_outlined,
            () => _openPrivacyPolicy(),
          ),
          _buildSettingTile(
            "App Version",
            Icons.info_outline,
            () => _showVersionInfo(),
            trailing: const Text("1.2.0"),
          ),
          const SizedBox(height: 32),

          // Logout Button
          Center(
            child: TextButton(
              onPressed: () => _showLogoutConfirmation(context),
              child: const Text(
                "Log Out",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoutConfirmation(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirm Logout'),
      content: const Text('Are you sure you want to log out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            'Log Out',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    _performLogout();
  }
}

Future<void> _performLogout() async {
  // Show loading indicator
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  try {
    // 1. Clear any local authentication state
    // Example: await LocalStorage.clearAll();
    
    // 2. Sign out from Firebase Authentication
    await FirebaseAuth.instance.signOut();

    // 3. Clear any cached data if needed
    // Example: await CacheManager.instance.clearAll();

    // 4. Close all open streams/subscriptions
    // Example: _userSubscription?.cancel();

    // 5. Navigate to login screen and clear stack
    if (mounted) {
      Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (context) => SigninOrSignupScreen()),
  (Route<dynamic> route) => false,
);

    }

    // Optional: Show logout success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }

  } catch (e, stackTrace) {
    // Log the error for debugging
    debugPrint('Logout error: $e');
    debugPrint('Stack trace: $stackTrace');

    // Close loading indicator if still mounted
    if (mounted) Navigator.pop(context);

    // Show user-friendly error message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Logout failed. Please try again.'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _performLogout,
          ),
        ),
      );
    }
  } finally {
    // Ensure loading dialog is dismissed
    if (mounted) {
      Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
    }
  }
}

  Widget _buildProfileSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _navigateToEditProfile,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: profileImage != null
                        ? FileImage(profileImage!)
                        : (profileImageUrl != null
                            ? NetworkImage(profileImageUrl!)
                            : const NetworkImage(
                                "https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg",
                              )) as ImageProvider,
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                userName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                userEmail,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                userBio,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: _navigateToEditProfile,
                child: const Text("Edit Profile"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'settings.$key': value,
          });

      setState(() {
        switch (key) {
          case 'darkMode':
            isDarkMode = value;
            break;
          case 'voiceGuidance':
            voiceGuidance = value;
            break;
          // Add other cases as needed
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update setting: ${e.toString()}")),
      );
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingSwitch(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      secondary: Icon(_getIconForSetting(title)),
    );
  }

  Widget _buildSettingTile(String title, IconData icon, VoidCallback onTap, {Widget? trailing}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildUnitSelector(String title, List<String> options, String currentValue, Function(String?) onChanged) {
    return ListTile(
      leading: Icon(_getIconForSetting(title)),
      title: Text(title),
      trailing: DropdownButton<String>(
        value: currentValue,
        underline: Container(),
        items: options.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  IconData _getIconForSetting(String title) {
    switch (title) {
      case "Dark Mode":
        return Icons.dark_mode_outlined;
      case "Voice Guidance":
        return Icons.volume_up_outlined;
      case "Auto Pause":
        return Icons.pause_circle_outline;
      case "Distance Unit":
        return Icons.straighten_outlined;
      case "Temperature Unit":
        return Icons.thermostat_outlined;
      default:
        return Icons.settings_outlined;
    }
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
  userName: userName,
  userEmail: userEmail,
  userBio: userBio,
  profileImageUrl: profileImageUrl,  // Changed from profileImage to profileImageUrl
  onSave: (name, email, bio, imageUrl) {  // Changed image to imageUrl
    setState(() {
      userName = name;
      userEmail = email;
      userBio = bio;
      profileImageUrl = imageUrl;  // Now storing the URL instead of File
    });
  },
),
      ),
    );
  }

  // Placeholder navigation methods
  void _navigateToEmergencyContacts() {}
  void _toggleLiveLocation() {}
  void _openHelpCenter() {
    Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HelpSupportPage()),
        );
  }
  void _openPrivacyPolicy() {
    Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PrivacyPolicyPage()),
        );
  }
  void _showVersionInfo() {}
  void _confirmLogout() {}
}
