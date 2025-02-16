import 'package:flutter/material.dart';
import 'package:innopetcare/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String projectId;
  final Map<String, String> globalData; // Add this parameter
  final Color colorTheme;

  ForgotPasswordScreen(
      {required this.projectId,
      required this.globalData,
      required this.colorTheme});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();

  // Function to validate email format
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    } else if (!RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  // Function to send reset password link
  void _sendResetPasswordLink() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: emailController.text.trim(),
        );

        // Show a success message when the email is sent
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Success'),
            content: Text(
              'A reset password link has been sent to ${emailController.text}. Please check your email.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      } on FirebaseAuthException catch (e) {
        // Handle errors from Firebase
        String errorMessage;
        if (e.code == 'user-not-found') {
          errorMessage = 'No user found with this email.';
        } else {
          errorMessage = 'Failed to send reset email. Please try again.';
        }

        // Show error message dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      } catch (e) {
        // Handle any other errors
        print("Error: $e");
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('An unexpected error occurred. Please try again.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background color
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // InnoPetCare Logo
                Image.network(
                  widget.globalData['image'] ??
                      'assets/img/InnoPetCareICON_black.png',
                  width: MediaQuery.of(context).size.width * 0.25,
                  fit: BoxFit
                      .cover, // Ensures the image is scaled proportionally
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/img/InnoPetCareICON_black.png', // Fallback image
                      width: MediaQuery.of(context).size.width * 0.25,
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Project Name
                Text(
                  widget.globalData['name'] ?? "",
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // Forgot Password Text
                Text(
                  'Forgot Your Password?',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.colorTheme),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your email and we’ll send you a link to reset your password',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 30),

                // Email Field and Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: 'Email',
                          prefixIcon: Icon(Icons.email, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none, // Clean design
                          ),
                        ),
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 30),

                      // Send Reset Password Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _sendResetPasswordLink,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.colorTheme,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'SEND RESET PASSWORD',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Back to Login Link
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginScreen(
                          projectId: widget.projectId,
                          globalData: widget.globalData,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back, color: widget.colorTheme),
                      const SizedBox(width: 4),
                      Text(
                        'Back to Login',
                        style: TextStyle(
                          color: widget.colorTheme,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
