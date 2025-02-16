import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:innopetcare/email_verification_screen.dart';
import 'package:innopetcare/forgot_password_screen.dart';
import 'package:innopetcare/register_screen.dart';
import 'package:innopetcare/views/pet_owners/main_screen.dart';

class LoginScreen extends StatefulWidget {
  final String projectId;
  final Map<String, String> globalData;

  LoginScreen({
    required this.projectId,
    required this.globalData,
  });

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool obscurePassword = true;
  bool isLoading = false;

  late Color headerColor;
  @override
  void initState() {
    super.initState();
    // Convert the hex string to a Color
    // Initialize headerColor from widget.globalData
    String headerColorHex = widget.globalData['headerColor'] ?? '#795548';
    headerColor = Color(int.parse(headerColorHex.replaceFirst('#', '0xFF')));
  }

  Future<void> _handleLogin() async {
    setState(() {
      isLoading = true;
    });

    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      _showMessage("Please enter your email address and password");
      setState(() {
        isLoading = false;
      });
      return;
    }
    try {
      // Step 1: Authenticate user with email and password
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      print("User authenticated successfully: ${userCredential.user?.uid}");

      User? user = userCredential.user;

      if (user != null) {
        bool isVerified = user.emailVerified;

        if (!isVerified) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmailVerification(
                projectId: widget.projectId,
                globalData: widget.globalData,
                colorTheme: headerColor,
              ),
            ),
          );
          return;
        }
      }

      // Step 2: Fetch client data from Firestore using the new "status" attribute
      QuerySnapshot clientsSnapshot = await FirebaseFirestore.instance
          .collection('clients')
          .where('email', isEqualTo: emailController.text.trim())
          .where('projectId', isEqualTo: widget.projectId)
          .get();

      if (clientsSnapshot.docs.isNotEmpty) {
        DocumentSnapshot clientDoc = clientsSnapshot.docs.first;

        // Check the "status" attribute
        String status = clientDoc['status'];
        print("Client found: ${clientDoc.id}, status: $status");

        if (status != 'approved') {
          // Check if email is verified
          User? user = FirebaseAuth.instance.currentUser;
          if (user != null && !user.emailVerified) {
            // Redirect to EmailVerification() if email is not verified
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => EmailVerification(
                      projectId: widget.projectId,
                      globalData: widget.globalData,
                      colorTheme: headerColor)),
            );
            return;
          }

          // Log the user out
          await FirebaseAuth.instance.signOut();
          // If status is not "approved", block login
          String message = status == 'pending'
              ? "Your account is currently pending approval. Please visit the clinic or contact us within the next 7 days to complete the approval process."
              : "Your account has been rejected. Please contact support.";
          _showMessage(message);
          setState(() {
            isLoading = false;
          });
          return;
        }

        // Step 3: Save project ID locally and navigate to main screen if status is "approved"
        // await _saveProjectId(widget.projectId);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(
              uid: userCredential.user!.uid,
              projectId: widget.projectId,
            ),
          ),
        );
      } else {
        print("No client found with the given email and projectId.");
        _showMessage("User not found. Please check your credentials.");
      }
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException: ${e.message}");
      _showMessage(e.message ?? "Login failed. Please try again.");
    } catch (e) {
      print("General error: $e");
      _showMessage("An error occurred. Please try again.");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context)
                  .size
                  .height, // Ensure vertical centering
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center, // Center vertically
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                    const SizedBox(height: 24),

                    // Welcome Text
                    Text(
                      widget.globalData['name'] ?? "",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Welcome! Login to your account.",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: headerColor ?? Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Let’s work together to take care of our furry friends.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Email field
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        prefixIcon: Icon(Icons.email, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Password', // Hint text inside the rectangle
                        prefixIcon: Icon(Icons.lock,
                            color: Colors.grey), // Lock icon on the left
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword =
                                  !obscurePassword; // Toggle visibility
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors
                            .grey[200], // Background color of the text field
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide.none, // Removes the border line
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 16), // Padding inside the field
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Login button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: headerColor ?? Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'LOGIN',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Forgot password link
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ForgotPasswordScreen(
                                projectId: widget.projectId,
                                globalData: widget.globalData,
                                colorTheme: headerColor),
                          ),
                        );
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: headerColor ?? Colors.orange,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Register link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegisterScreen(
                                    projectId: widget.projectId,
                                    globalData: widget.globalData,
                                    colorTheme: headerColor),
                              ),
                            );
                          },
                          child: Text(
                            'Register',
                            style: TextStyle(
                              color: headerColor ?? Colors.orange,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
