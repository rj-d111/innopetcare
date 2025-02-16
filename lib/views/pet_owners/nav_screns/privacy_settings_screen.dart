import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_launcher_icons/xml_templates.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PrivacySettingsScreen extends StatefulWidget {
  final String uid;
  final String projectId;

  const PrivacySettingsScreen({Key? key, required this.uid, required this.projectId}) : super(key: key);

  @override
  _PrivacySettingsScreenState createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String currentPassword = "";
  String newPassword = "";
  String retypePassword = "";
  String deletePassword = "";

  Future<void> handlePasswordChange() async {
    if (newPassword != retypePassword) {
      Fluttertoast.showToast(msg: "Passwords do not match");
      return;
    }

    try {
      await reauthenticateUser(currentPassword);
      await _auth.currentUser?.updatePassword(newPassword);
      Fluttertoast.showToast(msg: "Password changed successfully");
    } catch (error) {
      Fluttertoast.showToast(msg: "Error updating password");
      print("Error updating password: $error");
    }
  }

  Future<void> reauthenticateUser(String password) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );

    try {
      await user.reauthenticateWithCredential(credential);
      Fluttertoast.showToast(msg: "Re-authentication successful");
    } catch (error) {
      print("Error during re-authentication: $error");
      Fluttertoast.showToast(msg: "Re-authentication failed. Incorrect password.");
      throw error;
    }
  }

  Future<void> handleReauthenticateAndDelete() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await reauthenticateUser(deletePassword);

      // Update user's status to "deleted" in Firestore
      await _firestore.collection('users').doc(user.uid).update({'status': 'deleted'});

      // Delete the user from Firebase Authentication
      await user.delete();
      Fluttertoast.showToast(msg: "Account deleted successfully");

      // Sign out and navigate to login screen
      await _auth.signOut();
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (error) {
      print("Error deleting account: $error");
      Fluttertoast.showToast(msg: "Error deleting account. Please try again.");
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Account Deletion'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please enter your password to confirm deletion:'),
              TextField(
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                onChanged: (value) => setState(() => deletePassword = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.black)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await handleReauthenticateAndDelete();
                Navigator.of(context).pop();
              },
              child: const Text('Confirm Delete', style: TextStyle(color: Colors.white),),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Change Password',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 20),
            // Current Password
            TextField(
              decoration: const InputDecoration(labelText: 'Current Password'),
              obscureText: true,
              onChanged: (value) => setState(() => currentPassword = value),
            ),
            const SizedBox(height: 10),
            // New Password
            TextField(
              decoration: const InputDecoration(labelText: 'New Password'),
              obscureText: true,
              onChanged: (value) => setState(() => newPassword = value),
            ),
            const SizedBox(height: 10),
            // Retype New Password
            TextField(
              decoration: const InputDecoration(labelText: 'Retype New Password'),
              obscureText: true,
              onChanged: (value) => setState(() => retypePassword = value),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: handlePasswordChange,
              child: const Text('Save Password', style: TextStyle(color: Colors.black),),
            ),
            const SizedBox(height: 40),

            // Delete Account Section
            const Divider(),
            const SizedBox(height: 20),
            const Text(
              'Delete Account',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: _showDeleteAccountDialog,
              child: const Text('Delete Account', style: TextStyle(color: Colors.white),),
            ),
          ],
        ),
      ),
    );
  }
}
