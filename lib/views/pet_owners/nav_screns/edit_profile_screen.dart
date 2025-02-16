import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class EditProfileScreen extends StatefulWidget {
  final String uid;
  final String projectId;

  const EditProfileScreen(
      {Key? key, required this.uid, required this.projectId})
      : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _email;
  String? _profileImageUrl =
      'https://innopetcare.com/_services/unknown_user.jpg';
  bool _isLoading = true;
  bool _saving = false;
  File? _selectedImage;
  Future<int>? storagePermissionChecker;
  @override
  void initState() {
    super.initState();
    _fetchClientInfo();
  }

  // Fetch user profile info from Firestore
  Future<void> _fetchClientInfo() async {
    setState(() => _isLoading = true);
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('clients').doc(widget.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        _nameController.text = data['name'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _email = data['email'];
        _profileImageUrl = data['profileImage'] ?? _profileImageUrl;
      }
    } catch (error) {
      print("Error fetching user data: $error");
    } finally {
      setState(() => _isLoading = false);
    }
  }


Future<void> requestGalleryPermissions(BuildContext context) async {
  try {
    _pickImage(); // Simply launch the image picker
  } catch (e) {
    print("Error launching image picker: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error launching image picker.')),
    );
  }
}

 // Handle profile image selection
Future<void> _pickImage() async {
  try {
    final ImagePicker picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    } else {
      print("No image selected.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected.')),
      );
    }
  } catch (e) {
    print("Error picking image: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error picking image.')),
    );
  }
}

  // Upload profile image to Firebase Storage
  Future<String?> _uploadProfileImage(File image) async {
    try {
      final ref = _storage.ref().child('profileImages/${widget.uid}');
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (error) {
      print("Error uploading image: $error");
      return null;
    }
  }

  // Save changes to Firestore
  Future<void> _handleSaveChanges() async {
    setState(() => _saving = true);
    try {
      final userDocRef = _firestore.collection('clients').doc(widget.uid);

      // Update profile image if a new file is selected
      String? profileImageUrl = _profileImageUrl;
      if (_selectedImage != null) {
        profileImageUrl = await _uploadProfileImage(_selectedImage!);
      }

      // Update Firestore
      await userDocRef.update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'profileImage': profileImageUrl,
      });

      // Update Firebase Auth profile
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(_nameController.text.trim());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (error) {
      print("Error saving profile: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating profile')),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : NetworkImage(_profileImageUrl!)
                                  as ImageProvider,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt,
                                color: Colors.blue),
                            onPressed: () async {
                              await requestGalleryPermissions(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: "Name"),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: "Phone"),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      labelText: "Email",
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    readOnly: true,
                    controller: TextEditingController(text: _email),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saving ? null : _handleSaveChanges,
                    child: _saving
                        ? const CircularProgressIndicator()
                        : const Text("Save Changes"),
                  ),
                ],
              ),
            ),
    );
  }
}
