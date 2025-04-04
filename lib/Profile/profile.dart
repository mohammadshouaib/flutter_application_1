import 'package:flutter/material.dart';
import 'package:flutter_application_1/Profile/editprofile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


Future<Map<String, dynamic>?> fetchUserData() async {
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


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> userData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: false,
        elevation: 0,
        backgroundColor: const Color(0xFF00BF6D),
        foregroundColor: Colors.white,
        title: const Text("Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            FutureBuilder<Map<String, dynamic>?>(
              future: fetchUserData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Text("No user data found");
                }
                
                final userData = snapshot.data!;
                
                return Column(
                  children: [
                    const ProfilePic(image: "https://i.postimg.cc/cCsYDjvj/user-2.png"),
                    Text(
                      userData['fullName'] ?? "Annette Black", // Fallback if null
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(height: 16.0 * 2),
                    Info(
                      infoKey: "User ID",
                      info: "@${userData['email']?.split('@').first ?? "annette.me"}",
                    ),
                    Info(
                      infoKey: "Location",
                      info: (userData['address'] ?? 'Empty'), // You might want to add this to Firestore
                    ),
                    Info(
                      infoKey: "Phone",
                      info: userData['phone'] ?? "(239) 555-0108",
                    ),
                    Info(
                      infoKey: "Email Address",
                      info: userData['email'] ?? "demo@mail.com",
                    ),
                    const SizedBox(height: 16.0),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 160,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00BF6D),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                            shape: const StadiumBorder(),
                          ),
                          onPressed: () async {
                            final shouldRefresh = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditProfileScreen(userData: userData),
                              ),
                            );
                            
                            if (shouldRefresh == true) {
                              // Refresh your profile data here
                              setState(() {});
                            }
                          },
                          child: const Text("Edit profile"),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePic extends StatelessWidget {
  const ProfilePic({
    super.key,
    required this.image,
    this.isShowPhotoUpload = false,
    this.imageUploadBtnPress,
  });

  final String image;
  final bool isShowPhotoUpload;
  final VoidCallback? imageUploadBtnPress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color:
              Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.08),
        ),
      ),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(image),
          ),
          InkWell(
            onTap: imageUploadBtnPress,
            child: CircleAvatar(
              radius: 13,
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 20,
              ),
            ),
          )
        ],
      ),
    );
  }
}

class Info extends StatelessWidget {
  const Info({
    super.key,
    required this.infoKey,
    required this.info,
  });

  final String infoKey, info;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            infoKey,
            style: TextStyle(
              color: Theme.of(context)
                  .textTheme
                  .bodyLarge!
                  .color!
                  .withOpacity(0.8),
            ),
          ),
          Text(info),
        ],
      ),
    );
  }
}
