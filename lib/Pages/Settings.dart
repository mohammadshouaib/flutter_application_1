import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // User Profile Data
  String userName = "Alex Runner";
  String userEmail = "runner@example.com";
  String userBio = "Marathon enthusiast | 5K PB: 18:30";
  File? profileImage;

  // App Settings
  bool isDarkMode = false;
  bool voiceGuidance = true;
  bool autoPause = true;
  bool safetyAlerts = true;
  String distanceUnit = "km";
  String temperatureUnit = "°C";

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          profileImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error selecting image: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          _buildProfileSection(),
          const SizedBox(height: 24),

          // App Preferences
          _buildSectionHeader("Preferences"),
          _buildSettingSwitch("Dark Mode", isDarkMode, (value) {
            setState(() => isDarkMode = value);
          }),
          _buildSettingSwitch("Voice Guidance", voiceGuidance, (value) {
            setState(() => voiceGuidance = value);
          }),
          _buildSettingSwitch("Auto Pause", autoPause, (value) {
            setState(() => autoPause = value);
          }),
          _buildUnitSelector("Distance Unit", ["km", "mi"], distanceUnit, (value) {
            setState(() => distanceUnit = value!);
          }),
          _buildUnitSelector("Temperature Unit", ["°C", "°F"], temperatureUnit, (value) {
            setState(() => temperatureUnit = value!);
          }),
          const SizedBox(height: 24),

          // Safety Features
          _buildSectionHeader("Safety Features"),
          _buildSettingSwitch("Safety Alerts", safetyAlerts, (value) {
            setState(() => safetyAlerts = value);
          }),
          _buildSettingTile(
            "Emergency Contacts",
            Icons.emergency,
            () => _navigateToEmergencyContacts(),
          ),
          _buildSettingTile(
            "Live Location Sharing",
            Icons.location_on,
            () => _toggleLiveLocation(),
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
              onPressed: _confirmLogout,
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
                        : const NetworkImage(
                            "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200",
                          ) as ImageProvider,
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue,
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
        builder: (context) => _EditProfileScreen(
          userName: userName,
          userEmail: userEmail,
          userBio: userBio,
          profileImage: profileImage,
          onSave: (name, email, bio, image) {
            setState(() {
              userName = name;
              userEmail = email;
              userBio = bio;
              profileImage = image;
            });
          },
        ),
      ),
    );
  }

  // Placeholder navigation methods
  void _navigateToEmergencyContacts() {}
  void _toggleLiveLocation() {}
  void _openHelpCenter() {}
  void _openPrivacyPolicy() {}
  void _showVersionInfo() {}
  void _confirmLogout() {}
}

// Edit Profile Screen
class _EditProfileScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String userBio;
  final File? profileImage;
  final Function(String, String, String, File?) onSave;

  const _EditProfileScreen({
    required this.userName,
    required this.userEmail,
    required this.userBio,
    required this.profileImage,
    required this.onSave,
  });

  @override
  State<_EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _bioController;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userName);
    _emailController = TextEditingController(text: widget.userEmail);
    _bioController = TextEditingController(text: widget.userBio);
    _selectedImage = widget.profileImage;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error selecting image: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        actions: [
          TextButton(
            onPressed: () {
              widget.onSave(
                _nameController.text,
                _emailController.text,
                _bioController.text,
                _selectedImage,
              );
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _selectedImage != null
                    ? FileImage(_selectedImage!)
                    : widget.profileImage != null
                        ? FileImage(widget.profileImage!)
                        : const NetworkImage(
                            "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200",
                          ) as ImageProvider,
                child: Container(
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
              decoration: const InputDecoration(
                labelText: "Email",
                prefixIcon: Icon(Icons.email),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
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
              onPressed: () {
                widget.onSave(
                  _nameController.text,
                  _emailController.text,
                  _bioController.text,
                  _selectedImage,
                );
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }
}