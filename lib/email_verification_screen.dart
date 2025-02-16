import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:innopetcare/login_screen.dart';

class EmailVerification extends StatefulWidget {
  final String projectId;
  final Map<String, String> globalData;
  final Color colorTheme;

  EmailVerification({
    required this.projectId,
    required this.globalData,
    required this.colorTheme,
  });

  @override
  _EmailVerificationState createState() => _EmailVerificationState();
}

class _EmailVerificationState extends State<EmailVerification> {
  late Timer _timer;
  bool isVerified = false;

  @override
  void initState() {
    super.initState();
    _sendVerificationEmail();
    _startVerificationCheck();
  }

  void _sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        _showSnackbar('Verification email has been sent.');
      }
    } catch (e) {
      _showSnackbar('Email verification has been sent to your inbox already');
      print('Status: $e');
    }
  }

  void _checkProjectType() async {
    try {
      // Fetch project details from Firestore
      final projectDoc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .get();

      if (projectDoc.exists) {
        final projectType = projectDoc['type'] ?? '';
        if (projectType == 'Veterinary Site') {
          _showPendingApprovalDialog();
        }
      }
    } catch (e) {
      print('Error checking project type: $e');
    }
  }

  void _showPendingApprovalDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Account Pending Approval'),
          content: Text(
              'Your account is currently pending approval. Please visit the clinic or contact us within the next 7 days to complete the approval process.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _navigateToLoginScreen();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _startVerificationCheck() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        if (user.emailVerified) {
          setState(() {
            isVerified = true;
          });
          _showToast(
              'Your email has been successfully verified! You can now log in to your account.');
          // Fetch project details and check for "Veterinary Site" type
          _checkProjectType();
          _timer.cancel();
          _navigateToLoginScreen();
        }
      }
    });
  }

  void _navigateToLoginScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(
          projectId: widget.projectId,
          globalData: widget.globalData,
        ),
      ),
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pop(context);
  }

  Future<bool> _onBackPressed() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Log Out"),
            content: Text(
                "Are you sure you want to log out? You will not be able to verify your email."),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  _handleLogout();
                },
                child: Text("Log Out"),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Email illustration
              Image.network(
                widget.globalData['image'] ??
                    'assets/img/InnoPetCareICON_black.png',
                width: MediaQuery.of(context).size.width * 0.25,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/img/InnoPetCareICON_black.png',
                    width: MediaQuery.of(context).size.width * 0.25,
                  );
                },
              ),
              const SizedBox(height: 24),
              // Title
              Text(
                widget.globalData['name'] ?? "Veterinary Site",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Email Verification',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: widget.colorTheme,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Description
              Text(
                'Please use the link below to verify your email and start your journey',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Verify Email Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _sendVerificationEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.colorTheme,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'RESEND VERIFICATION EMAIL',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Logout Button
              GestureDetector(
                onTap: () async {
                  bool confirmLogout = await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Confirm Logout"),
                        content: Text("Are you sure you want to log out?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context)
                                .pop(false), // Dismiss and return false
                            child: Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context)
                                .pop(true), // Dismiss and return true
                            child: Text(
                              "Logout",
                              style: TextStyle(
                                  color: Colors.red), // Highlight Logout action
                            ),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmLogout == true) {
                    _handleLogout(); // Execute logout function
                  }
                },
                child: Text(
                  'Log Out',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: widget.colorTheme,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
