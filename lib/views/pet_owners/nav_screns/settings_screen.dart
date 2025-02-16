import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:innopetcare/sites_screen.dart';
import 'package:innopetcare/views/pet_owners/nav_screns/privacy_settings_screen.dart';
import 'package:innopetcare/views/pet_owners/nav_screns/send_report_screen.dart';
import 'package:innopetcare/views/pet_owners/nav_screns/widgets/custom_app_bar.dart';
import 'package:innopetcare/views/send_feedback_screen.dart';
import 'package:innopetcare/views/help_menu_screen.dart';
import 'package:innopetcare/views/privacy_policy_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String uid;
  final String projectId;
  final Color colorTheme;

  const SettingsScreen({
    Key? key,
    required this.uid,
    required this.projectId,
    required this.colorTheme,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout(context);
              },
              child: const Text('Yes', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Fluttertoast.showToast(
        msg: "Successfully logged out", toastLength: Toast.LENGTH_SHORT);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => SitesScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: widget.colorTheme.withOpacity(0.1),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: widget.colorTheme),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            Text(
              'Settings',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: widget.colorTheme),
            ),
            const SizedBox(height: 16),

            // Privacy Settings
            _buildSettingsTile(context, 'Privacy Settings', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrivacySettingsScreen(
                    uid: widget.uid,
                    projectId: widget.projectId,
                  ),
                ),
              );
            }),

            // Send Feedback
            _buildSettingsTile(context, 'Send Feedback', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SendFeedbackScreen(
                      uid: widget.uid,
                      projectId: widget.projectId,
                      colorTheme: widget.colorTheme),
                ),
              );
            }),
            // Send Report
            _buildSettingsTile(context, 'Send Report', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SendReportScreen(
                    uid: widget.uid,
                    projectId: widget.projectId,
                    colorTheme: widget.colorTheme,
                  ),
                ),
              );
            }),
            // Logout
            _buildSettingsTile(context, 'Logout', () => _confirmLogout(context),
                isLogout: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
      BuildContext context, String title, VoidCallback onTap,
      {bool isLogout = false}) {
    return Column(
      children: [
        ListTile(
          title: Text(
            title,
            style: TextStyle(
              color: isLogout ? Colors.red : Colors.black,
              fontWeight: isLogout ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          onTap: onTap,
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: isLogout ? Colors.red : Colors.black,
            size: 16,
          ),
        ),
        Divider(color: widget.colorTheme.withOpacity(0.5), thickness: 1),
      ],
    );
  }
}
