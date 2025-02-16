import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:innopetcare/email_verification_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class RegisterScreen extends StatefulWidget {
  final String projectId;
  final Map<String, String> globalData;
  final Color colorTheme;

  RegisterScreen({
    required this.projectId,
    required this.globalData,
    required this.colorTheme,
  });

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String siteType = '';
  bool showTooltip = false;
  final FocusNode passwordFocusNode = FocusNode();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool agreeTerms = false;
  bool agreePrivacy = false;

  // Password validation flags
  bool hasMinLength = false;
  bool hasUpperCase = false;
  bool hasLowerCase = false;
  bool hasNumber = false;
  bool hasSpecialCharacter = false;

  @override
  void initState() {
    super.initState();
    // Add a listener to the focus node
    passwordFocusNode.addListener(() {
      setState(() {
        showTooltip = passwordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    // Dispose the focus node to prevent memory leaks
    passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String path) async {
    final String slug = widget.globalData['slug'] ?? '';
    final Uri url = Uri.parse('https://innopetcare.com/sites/$slug/$path');

    await launchUrl(url);
  }

  void _validatePassword(String password) {
    setState(() {
      hasMinLength = password.length >= 8;
      hasUpperCase = password.contains(RegExp(r'[A-Z]'));
      hasLowerCase = password.contains(RegExp(r'[a-z]'));
      hasNumber = password.contains(RegExp(r'[0-9]'));
      hasSpecialCharacter =
          password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

void _handleSignUp() async {
  if (!agreeTerms || !agreePrivacy) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Please agree to the Terms and Privacy Policy."),
      ),
    );
    return;
  }

  // Validate phone number
  final phone = phoneController.text.trim();
  if (!RegExp(r'^9\d{9}$').hasMatch(phone)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Enter a valid phone number (9XXXXXXXXX)."),
      ),
    );
    return;
  }

  // Email Validation
  final email = emailController.text.trim();
  if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(email)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Enter a valid email address."),
      ),
    );
    return;
  }

  // Password Validation
  if (!(hasMinLength && hasUpperCase && hasLowerCase && hasNumber && hasSpecialCharacter)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Password must satisfy the following:\n"
          "- At least 8 characters\n"
          "- At least one uppercase letter\n"
          "- At least one lowercase letter\n"
          "- At least one number\n"
          "- At least one special character (e.g., !, @, #, \$)",
        ),
      ),
    );
    return;
  }

  // Password Match Validation
  if (passwordController.text.trim() != confirmPasswordController.text.trim()) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Passwords do not match."),
      ),
    );
    return;
  }

  try {
    // Step 1: Register the user in Firebase Authentication
    final UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: passwordController.text.trim(),
    );

   // Step 2: Get the newly created user's UID
      final String uid = userCredential.user?.uid ?? '';
      if (uid.isEmpty) {
        throw Exception('Failed to retrieve user ID.');
      }

      // Step 3: Fetch the project type from Firestore
      final projectTypeDoc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .get();

      String siteType = 'Unknown Type'; // Default value in case of failure

      if (projectTypeDoc.exists) {
        siteType = projectTypeDoc.data()?['type'] ?? 'Unknown Type';
        print("Site Type: $siteType");
      } else {
        print("Project not found with ID: ${widget.projectId}");
      }

      // Step 4: Determine status based on siteType
      final status = (siteType != 'Veterinary Site') ? 'approved' : 'pending';

      // Step 5: Prepare new client data for Firestore
      final newClient = {
        'email': emailController.text.trim(),
        'status': status,
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'projectId': widget.projectId,
        'lastActivityTime': FieldValue.serverTimestamp(),
        'accountCreated': FieldValue.serverTimestamp(),
        'profileImage':
            'https://firebasestorage.googleapis.com/v0/b/innopetcare-2a866.appspot.com/o/profileImages%2FjSwk4p1VkJUAR2cxC15jCxlgW113?alt=media&token=5238a85e-9430-4874-bc86-d38d38b28d9a',
      };

      // Step 6: Add the new client to Firestore using the same UID
      await FirebaseFirestore.instance
          .collection('clients')
          .doc(uid)
          .set(newClient);

      // Step 7: Show success message based on status
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account created successfully!')),
      );

      // Step 8: Redirect to EmailVerification Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EmailVerification(
            projectId: widget.projectId,
            globalData: widget.globalData,
            colorTheme: widget.colorTheme,
          ),
        ),
      );
      
    } on FirebaseAuthException catch (e) {
    // Handle Firebase Auth-specific errors
    String errorMessage;
    if (e.code == 'email-already-in-use') {
      errorMessage = 'The email is already in use by another account. Try to sign in instead';
    } else if (e.code == 'weak-password') {
      errorMessage = 'The password is too weak.';
    } else {
      errorMessage = 'Registration failed: ${e.message}';
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage)),
    );
  } catch (e) {
    // Handle general errors
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Registration failed: $e')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Back button
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: widget.colorTheme),
                    onPressed: () => Navigator.pop(context),
                  ),
                  SizedBox(width: 4), // Add spacing between the icon and text
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'Back',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: widget.colorTheme,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              // Cat illustration
              Center(
                child: Column(
                  children: [
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
                    }),
                    const SizedBox(height: 24),
                    // Title and Subtitle
                    Text(
                      widget.globalData['name'] ?? "Veterinary Site",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create new account',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: widget.colorTheme,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Pet Owner Name
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Pet Owner Name',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Email
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: 'Email',
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Phone Number
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.number, // Numeric keyboard
                maxLength: 10, // Limit input to 10 digits
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, // Allow numbers only
                ],
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black, // Ensure input text is visible
                ),
                decoration: InputDecoration(
                  counterText: '', // Hides the default character counter
                  hintText:
                      '9XXXXXXXXX', // Placeholder for the phone number format
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: Colors
                        .grey[600], // Hint text color, visible when not focused
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12.0, right: 8.0),
                    child: Text(
                      '+63 |', // Static prefix text
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black, // Ensure prefix text is visible
                      ),
                    ),
                  ),
                  prefixIconConstraints: BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ), // Allows prefixIcon to adjust its size
                  filled: true,
                  fillColor: Colors.grey[200], // Background color of the field
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide.none, // Remove border for clean design
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey[300]!,
                      width: 1, // Border when not focused
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ), // Padding inside the field
                ),
                onChanged: (value) {
                  // Optional: Handle real-time input changes
                  print("Current Input: $value");
                },
              ),
              const SizedBox(height: 16),
              // Password
              TextFormField(
                controller: passwordController,
                obscureText: obscurePassword,
                onChanged: _validatePassword,
                focusNode: passwordFocusNode, // Attach the focus node
                decoration: InputDecoration(
                  hintText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Tooltip
              if (showTooltip)
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Password Assistance',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildValidationRow(
                            'At least 8 characters in length', hasMinLength),
                        _buildValidationRow(
                            'At least one uppercase letter', hasUpperCase),
                        _buildValidationRow(
                            'At least one lowercase letter', hasLowerCase),
                        _buildValidationRow('At least one number', hasNumber),
                        _buildValidationRow(
                            'At least one special character (e.g., !, @, #)',
                            hasSpecialCharacter),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              // Confirm Password
              TextFormField(
                controller: confirmPasswordController,
                obscureText: obscureConfirmPassword,
                decoration: InputDecoration(
                  hintText: 'Confirm Password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        obscureConfirmPassword = !obscureConfirmPassword;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Terms and Conditions
              CheckboxListTile(
                title: GestureDetector(
                  onTap: () => _launchUrl('terms-and-conditions'),
                  child: Text(
                    'I agree to the Terms and Conditions',
                    style: TextStyle(
                      decoration: TextDecoration.none,
                      color: widget.colorTheme,
                      fontSize: 14,
                    ),
                  ),
                ),
                value: agreeTerms,
                onChanged: (value) {
                  setState(() {
                    agreeTerms = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: widget.colorTheme,
              ),
              // Privacy Policy
              CheckboxListTile(
                title: GestureDetector(
                  onTap: () => _launchUrl('privacy-policy'),
                  child: Text(
                    'I agree to the Privacy Policy',
                    style: TextStyle(
                      decoration: TextDecoration.none,
                      color: widget.colorTheme,
                      fontSize: 14,
                    ),
                  ),
                ),
                value: agreePrivacy,
                onChanged: (value) {
                  setState(() {
                    agreePrivacy = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: widget.colorTheme,
              ),
              const SizedBox(height: 16),
              // Sign Up Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.colorTheme,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'SIGN UP',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Login Link
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context); // Navigate back to Login
                      },
                      child: Text(
                        'Login',
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
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build a validation row
  Widget _buildValidationRow(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.cancel,
          color: isValid ? Colors.green : Colors.red,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
