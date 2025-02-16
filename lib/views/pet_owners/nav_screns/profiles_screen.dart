import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:innopetcare/terms_conditions_screen.dart';
import 'package:innopetcare/views/help_menu_screen.dart';
import 'package:innopetcare/views/privacy_policy_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'edit_profile_screen.dart';
import 'dashboard_screen.dart';
import 'about_us_screen.dart';
import 'contact_us_screen.dart';
import 'messages_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';

class ProfilesScreen extends StatefulWidget {
  final String uid;
  final String projectId;
  final Color colorTheme;

  ProfilesScreen(
      {required this.uid, required this.projectId, required this.colorTheme});

  @override
  _ProfilesScreenState createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  String name = '';
  String description = '';
  String ownerName = '';
  String contactNumber = '';
  String email = '';
  String profileImage = '';
  String address = '';
  String image = '';
  String slug = '';

  @override
  void initState() {
    super.initState();
    _fetchGlobalSectionsDetails();
    _fetchClientDetails();
  }

  Future<void> _fetchGlobalSectionsDetails() async {
    try {
      // Fetch the document from Firestore
      var globalSectionsDoc = await FirebaseFirestore.instance
          .collection('global-sections')
          .doc(widget.projectId)
          .get();

      // Check if the document exists and fetch data safely
      if (globalSectionsDoc.exists) {
        var data = globalSectionsDoc.data();
        if (data != null) {
          setState(() {
            name = data['name'] ?? 'Unknown';
            address = data['address'] ?? '';
            image = data['image'] ?? '';
            slug = data['slug'] ?? '';
          });
        }
      } else {
        print("Document not found for projectId: ${widget.projectId}");
      }
    } catch (e) {
      print('Error fetching global sections details: $e');
    }
  }

  Future<void> _fetchClientDetails() async {
    try {
      // Fetch user document from Firestore
      DocumentSnapshot clientDoc = await FirebaseFirestore.instance
          .collection('clients')
          .doc(widget.uid)
          .get();

      // Check if the document exists and has data
      if (clientDoc.exists) {
        var data = clientDoc.data() as Map<String, dynamic>?;

        if (data != null) {
          setState(() {
            ownerName = data['name'] ?? 'Unknown';
            contactNumber = data['phone'] ?? 'No Contact';
            email = data['email'] ?? 'No Email';
            profileImage = data['profileImage'] ?? '';
          });
        }
      } else {
        print('No client data found for UID: ${widget.uid}');
      }
    } catch (e) {
      print('Error fetching client details: $e');
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    launchUrl(uri);
  }

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Exit App"),
            content: Text("Are you sure you want to quit?"),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(false), // Dismiss dialog
                child: Text("No"),
              ),
              TextButton(
                onPressed: () {
                  // Close dialog and exit app
                  Navigator.of(context).pop(true);
                  if (Platform.isAndroid) {
                    SystemNavigator.pop(); // Closes the app on Android
                  } else if (Platform.isIOS) {
                    exit(0); // Forces the app to quit on iOS
                  }
                },
                child: Text("Yes"),
              ),
            ],
          ),
        ) ??
        false; // Return false if dialog is dismissed
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool shouldExit = await _showExitConfirmationDialog(context);
        return shouldExit;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 160.0,
          backgroundColor: Colors.white,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  image.isNotEmpty
                      ? Image.network(image, height: 40)
                      : Container(),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.settings, color: widget.colorTheme),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SettingsScreen(
                            uid: widget.uid,
                            projectId: widget.projectId,
                            colorTheme: widget.colorTheme,
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.notifications, color: widget.colorTheme),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationsScreen(
                            uid: widget.uid,
                            projectId: widget.projectId,
                            colorTheme: widget.colorTheme,
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.message, color: widget.colorTheme),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MessagesScreen(
                            uid: widget.uid,
                            projectId: widget.projectId,
                            colorTheme: widget.colorTheme,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      name,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SelectableText(
                      address,
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AboutUsScreen(
                                  uid: widget.uid,
                                  projectId: widget.projectId,
                                ),
                              ),
                            );
                          },
                          child: Text('About Us',
                              style: TextStyle(color: widget.colorTheme)),
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ContactUsScreen(
                                  uid: widget.uid,
                                  projectId: widget.projectId,
                                  colorTheme: widget.colorTheme,
                                ),
                              ),
                            );
                          },
                          child: Text('Contact Us',
                              style: TextStyle(color: widget.colorTheme)),
                        ),
                        const SizedBox(width: 10),
                        TextButton(
                          onPressed: () async {
                            final Uri url = Uri.parse(
                                'https://innopetcare.com/sites/$slug/help');

                            await launchUrl(url,
                                mode: LaunchMode.externalApplication);
                          },
                          child: Text(
                            'Help',
                            style: TextStyle(color: widget.colorTheme),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: profileImage.isNotEmpty
                        ? CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(profileImage),
                            backgroundColor: Colors.transparent,
                          )
                        : CircleAvatar(
                            radius: 50,
                            backgroundColor: widget.colorTheme,
                            child: Icon(Icons.person,
                                size: 50, color: Colors.white),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ownerName,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(
                            uid: widget.uid,
                            projectId: widget.projectId,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit, color: Colors.grey),
                    label: const Text('Edit Profile',
                        style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.colorTheme.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProfileInfoRow(
                          label: 'Contact no.:',
                          value: contactNumber.startsWith('+63')
                              ? contactNumber
                              : '+63$contactNumber',
                        ),
                        ProfileInfoRow(label: 'Email:', value: email),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DashboardScreen(
                            uid: widget.uid,
                            projectId: widget.projectId,
                            colorTheme: widget.colorTheme,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.colorTheme,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      child: Text(
                        'Go to Dashboard',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Row for Terms and Conditions and Privacy Policy
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TermsConditionsScreen(
                                uid: widget.uid,
                                projectId: widget.projectId,
                                termsAccepted: true,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'Terms and Conditions',
                          style: TextStyle(
                            fontSize: 14,
                            color: widget.colorTheme,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PrivacyPolicyScreen(
                                uid: widget.uid,
                                projectId: widget.projectId,
                                privacyAccepted: true,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'Privacy Policy',
                          style: TextStyle(
                            fontSize: 14,
                            color: widget.colorTheme,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const ProfileInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          SelectableText(value, style: TextStyle(color: Colors.black)),
        ],
      ),
    );
  }
}
