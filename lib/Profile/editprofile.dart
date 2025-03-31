import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  
  const EditProfileScreen({super.key, required this.userData});
  
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  
  final _formKey = GlobalKey<FormState>();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.userData['fullName']);
    _emailController = TextEditingController(text: widget.userData['email']);
    _phoneController = TextEditingController(text: widget.userData['phone']);
    _addressController = TextEditingController(
      text: widget.userData['address'] ?? 'Empty'
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isUpdating = true);
    
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
            'fullName': _fullNameController.text,
            'email': _emailController.text,
            'phone': _phoneController.text,
            'address': _addressController.text,
            'updatedAt': DateTime.now(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
            
      if (!mounted) return;
      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      setState(() => _isUpdating = false);
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
        title: const Text("Edit Profile"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ProfilePic(
                image: 'https://i.postimg.cc/cCsYDjvj/user-2.png',
                imageUploadBtnPress: () {},
              ),
              const Divider(),
              Column(
                children: [
                  UserInfoEditField(
                    text: "Name",
                    child: TextFormField(
                      controller: _fullNameController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF00BF6D).withOpacity(0.05),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0 * 1.5, vertical: 16.0),
                        border: const OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(50)),
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Name is required' : null,
                    ),
                  ),
                  UserInfoEditField(
                    text: "Email",
                    child: TextFormField(
                      controller: _emailController,
                      enabled: false, // Makes field uneditable
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF00BF6D).withOpacity(0.05),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0 * 1.5, vertical: 16.0),
                        border: const OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(50)),
                        ),
                      ),
                    ),
                  ),
                  UserInfoEditField(
                    text: "Phone",
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF00BF6D).withOpacity(0.05),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0 * 1.5, vertical: 16.0),
                        border: const OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(50)),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          value!.isEmpty ? 'Phone is required' : null,
                    ),
                  ),
                  UserInfoEditField(
                    text: "Address",
                    child: TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF00BF6D).withOpacity(0.05),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0 * 1.5, vertical: 16.0),
                        border: const OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(50)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .color!
                            .withOpacity(0.08),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  SizedBox(
                    width: 160,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BF6D),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: _isUpdating ? null : _updateProfile,
                      child: _isUpdating
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Save Update"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// class EditProfileScreen extends StatefulWidget {
//   final Map<String, dynamic> userData;
//   const EditProfileScreen({super.key, required this.userData});
//   @override
//   State<EditProfileScreen> createState() => _EditProfileScreenState();
// }

// class _EditProfileScreenState extends State<EditProfileScreen> {
//   late final TextEditingController _fullNameController;
//   late final TextEditingController _phoneController;
//   late final TextEditingController _emailController;
//   // late final TextEditingController _locationController;

  
//   @override
//   void initState() {
//     super.initState();
//     _fullNameController = TextEditingController(text: widget.userData['fullName']);
//     _phoneController = TextEditingController(text: widget.userData['phone']);
//     _emailController = TextEditingController(text: widget.userData['email']);
//     // _locationController = TextEditingController(text: widget.userData['location']);

//   }
  
//   @override
//   void dispose() {
//     _fullNameController.dispose();
//     _phoneController.dispose();
//     _emailController.dispose();
//     super.dispose();
//   }
  
//   Future<void> _submitForm() async {
//     if (!_formKey.currentState!.validate()) return;
    
//     try {
//       final userId = FirebaseAuth.instance.currentUser!.uid;
//       await updateUserProfile(
//         userId: userId,
//         fullName: _fullNameController.text,
//         phone: _phoneController.text,
//         email: _emailController.text,
//       );
      
//       // Show success message
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Profile updated successfully')),
//       );
      
//       // Navigate back and refresh the profile view
//       Navigator.pop(context, true);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error updating profile: $e')),
//       );
//     }
//   }
  
//   final _formKey = GlobalKey<FormState>();


//   Future<void> updateUserProfile({
//     required String userId,
//     required String fullName,
//     required String phone,
//     required String email,
//   }) async {
//     try {
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(userId)
//           .update({
//             'fullName': fullName,
//             'phone': phone,
//             'email': email,
//             'updatedAt': DateTime.now(), // Add update timestamp
//           });
//       print('Profile updated successfully');
//     } catch (e) {
//       print('Error updating profile: $e');
//       throw Exception('Failed to update profile');
//     }
//   }


//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         centerTitle: false,
//         elevation: 0,
//         backgroundColor: const Color(0xFF00BF6D),
//         foregroundColor: Colors.white,
//         title: const Text("Edit Profile"),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.symmetric(horizontal: 16.0),
//         child: Column(
//           children: [
//             ProfilePic(
//               image: 'https://i.postimg.cc/cCsYDjvj/user-2.png',
//               imageUploadBtnPress: () {},
//             ),
//             const Divider(),
//             Form(
//               child: Column(
//                 children: [
//                   UserInfoEditField(
//                     text: "Name",
//                     child: TextFormField(
//                       initialValue: widget.userData['fullName'],
//                       decoration: InputDecoration(
//                         filled: true,
//                         fillColor: const Color(0xFF00BF6D).withOpacity(0.05),
//                         contentPadding: const EdgeInsets.symmetric(
//                             horizontal: 16.0 * 1.5, vertical: 16.0),
//                         border: const OutlineInputBorder(
//                           borderSide: BorderSide.none,
//                           borderRadius: BorderRadius.all(Radius.circular(50)),
//                         ),
//                       ),
//                     ),
//                   ),
//                   UserInfoEditField(
//                     text: "Email",
//                     child: TextFormField(
//                       initialValue: userData["email"],
//                       decoration: InputDecoration(
//                         filled: true,
//                         fillColor: const Color(0xFF00BF6D).withOpacity(0.05),
//                         contentPadding: const EdgeInsets.symmetric(
//                             horizontal: 16.0 * 1.5, vertical: 16.0),
//                         border: const OutlineInputBorder(
//                           borderSide: BorderSide.none,
//                           borderRadius: BorderRadius.all(Radius.circular(50)),
//                         ),
//                       ),
//                     ),
//                   ),
//                   UserInfoEditField(
//                     text: "Phone",
//                     child: TextFormField(
//                       initialValue: userData["phone"],
//                       decoration: InputDecoration(
//                         filled: true,
//                         fillColor: const Color(0xFF00BF6D).withOpacity(0.05),
//                         contentPadding: const EdgeInsets.symmetric(
//                             horizontal: 16.0 * 1.5, vertical: 16.0),
//                         border: const OutlineInputBorder(
//                           borderSide: BorderSide.none,
//                           borderRadius: BorderRadius.all(Radius.circular(50)),
//                         ),
//                       ),
//                     ),
//                   ),
//                   UserInfoEditField(
//                     text: "Address",
//                     child: TextFormField(
//                       initialValue: "Empty",
//                       decoration: InputDecoration(
//                         filled: true,
//                         fillColor: const Color(0xFF00BF6D).withOpacity(0.05),
//                         contentPadding: const EdgeInsets.symmetric(
//                             horizontal: 16.0 * 1.5, vertical: 16.0),
//                         border: const OutlineInputBorder(
//                           borderSide: BorderSide.none,
//                           borderRadius: BorderRadius.all(Radius.circular(50)),
//                         ),
//                       ),
//                     ),
//                   ),
//                   // UserInfoEditField(
//                   //   text: "Old Password",
//                   //   child: TextFormField(
//                   //     obscureText: true,
//                   //     initialValue: "demopass",
//                   //     decoration: InputDecoration(
//                   //       suffixIcon: const Icon(
//                   //         Icons.visibility_off,
//                   //         size: 20,
//                   //       ),
//                   //       filled: true,
//                   //       fillColor: const Color(0xFF00BF6D).withOpacity(0.05),
//                   //       contentPadding: const EdgeInsets.symmetric(
//                   //           horizontal: 16.0 * 1.5, vertical: 16.0),
//                   //       border: const OutlineInputBorder(
//                   //         borderSide: BorderSide.none,
//                   //         borderRadius: BorderRadius.all(Radius.circular(50)),
//                   //       ),
//                   //     ),
//                   //   ),
//                   // ),
//                   // UserInfoEditField(
//                   //   text: "New Password",
//                   //   child: TextFormField(
//                   //     decoration: InputDecoration(
//                   //       hintText: "New Password",
//                   //       filled: true,
//                   //       fillColor: const Color(0xFF00BF6D).withOpacity(0.05),
//                   //       contentPadding: const EdgeInsets.symmetric(
//                   //           horizontal: 16.0 * 1.5, vertical: 16.0),
//                   //       border: const OutlineInputBorder(
//                   //         borderSide: BorderSide.none,
//                   //         borderRadius: BorderRadius.all(Radius.circular(50)),
//                   //       ),
//                   //     ),
//                   //   ),
//                   // ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 16.0),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 SizedBox(
//                   width: 120,
//                   child: ElevatedButton(
//                     onPressed: () {
//                       Navigator.pushReplacement(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => ProfileScreen(),
//                               ),
//                             );
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Theme.of(context)
//                           .textTheme
//                           .bodyLarge!
//                           .color!
//                           .withOpacity(0.08),
//                       foregroundColor: Colors.white,
//                       minimumSize: const Size(double.infinity, 48),
//                       shape: const StadiumBorder(),
//                     ),
//                     child: const Text("Cancel"),
//                   ),
//                 ),
//                 const SizedBox(width: 16.0),
//                 SizedBox(
//                   width: 160,
//                   child: ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF00BF6D),
//                       foregroundColor: Colors.white,
//                       minimumSize: const Size(double.infinity, 48),
//                       shape: const StadiumBorder(),
//                     ),
//                     onPressed: () {
//                     },
//                     child: const Text("Save Update"),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

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

class UserInfoEditField extends StatelessWidget {
  const UserInfoEditField({
    super.key,
    required this.text,
    required this.child,
  });

  final String text;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0 / 2),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(text),
          ),
          Expanded(
            flex: 3,
            child: child,
          ),
        ],
      ),
    );
  }
}
