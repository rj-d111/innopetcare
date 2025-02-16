import 'dart:async';
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
      _showSnackbar('Failed to send email: $e');
    }
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
          _showToast('Your email has been successfully verified!');
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

  void _logOut() async {
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
                  _logOut();
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isVerified
                    ? 'Your email is verified! Redirecting...'
                    : 'Please verify your email. Check your inbox.',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.colorTheme),
                textAlign: TextAlign.center,
              ),
              if (!isVerified)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: CircularProgressIndicator(
                    color: widget.colorTheme,
                  ),
                ),
              SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget
                      .colorTheme, // Use widget.colorTheme or any color of your choice
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                  ),
                ),
                onPressed: _sendVerificationEmail,
                child: Text(
                  'Resend Verification Email',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: _logOut,
                style: TextButton.styleFrom(
                  foregroundColor: widget.colorTheme, // Sets the text color
                ),
                child: Text(
                  'Log Out',
                  style: TextStyle(
                      fontSize: 16), // Optional: Adjust font size for emphasis
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
