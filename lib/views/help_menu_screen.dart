import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HelpMenuScreen extends StatefulWidget {
  final String uid;
  final String projectId;
  final Color colorTheme;

  const HelpMenuScreen({
    required this.uid,
    required this.projectId,
    required this.colorTheme,
    Key? key,
  }) : super(key: key);

  @override
  _HelpMenuScreenState createState() => _HelpMenuScreenState();
}

class _HelpMenuScreenState extends State<HelpMenuScreen> {
  String globalSectionName = '';
  String projectType = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // Fetch global section name
      final globalSectionDoc = await FirebaseFirestore.instance
          .collection('global-sections')
          .doc(widget.projectId)
          .get();

      if (globalSectionDoc.exists) {
        setState(() {
          globalSectionName = globalSectionDoc.data()?['name'] ?? '';
        });
      }

      // Fetch project type
      final projectDoc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .get();

      if (projectDoc.exists) {
        setState(() {
          projectType = projectDoc.data()?['type'] ?? '';
        });
      }
    } catch (e) {
      print("Error fetching data: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: widget.colorTheme,
        title: const Text(
          'Help Menu',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Help Information Section
            Text(
              'Help Information for $globalSectionName Site',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: widget.colorTheme,
              ),
            ),
            const SizedBox(height: 20),
            // Add the full-width image from assets
            Image.asset(
              'assets/img/help-menu.png',
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 20),

            // Getting Started
            _buildSectionTitle('Getting Started'),
            _buildContent(
              'User Registration: To create your account, click the "For $projectType" button on the homepage. Fill in the required details, including your email address, password, and organization information.\n'
              'Initial Setup: After registration, complete your shelter profile by adding essential information such as shelter name, address, contact details, and shelter description.',
            ),

            // Managing Your Profile
            _buildSectionTitle('Managing Your Profile'),
            _buildContent(
              'Updating Information: Visit the "User Profile" section to update your personal and shelter details, including contact information and profile photo.\n'
              'Changing Password: To secure your account, navigate to "Privacy Settings" and select the "Change Password" option to set a new password.',
            ),

            // Adoption Process
            _buildSectionTitle('Adoption Process'),
            _buildContent(
              'Inquiring About Adoption: Potential adopters can browse pets available for adoption and send inquiries through the Connected Care Center. Admins can respond to these inquiries to guide adopters on the next steps.\n'
              'Scheduling Appointments for Adoption: Use the "Schedule Appointments" feature to arrange in-person visits for adopters to meet the pets.',
            ),

            // Using Scheduling Tools
            _buildSectionTitle('Using Scheduling Tools'),
            _buildContent(
              'Scheduling Appointments: Organize adoption visits, volunteer shifts, visitor appointments, and supply donation drop-offs using the "Schedule Appointments" feature.',
            ),

            // Feedback and Reports
            _buildSectionTitle('Feedback and Reports'),
            _buildContent(
              'Submitting Feedback: Share your insights and suggestions using the "Feedback" option in the Help section.\n'
              'Submitting a Report for Issues: If you encounter any issues with the platform, go to the "Submit Report" section in the Help menu.',
            ),

            // Data Privacy and Security
            _buildSectionTitle('Data Privacy and Security'),
            _buildContent(
              'Data Management: Ensure compliance with data privacy regulations by reviewing and managing user consent and information in the "Privacy Settings" section.',
            ),

            // FAQs
            _buildSectionTitle('FAQs'),
            _buildContent(
              'How do I create an account?\n'
              'Click the "For $projectType" button on the homepage, enter your email, set a password, and complete the registration form.\n\n'
              'What should I do if I forget my password?\n'
              'Click the "Forgot Password?" link on the login page, enter your email, and follow the reset instructions sent to your inbox.\n\n'
              'How do I schedule appointments for adoptions or donations?\n'
              'Go to the "Schedule Appointments" section, select the appointment type, and fill in the necessary details.\n\n'
              'What should I do if I encounter a technical issue?\n'
              'Navigate to the "Submit Report" section in the Help menu, describe the issue in detail, and submit it for assistance.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 10.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: widget.colorTheme,
        ),
      ),
    );
  }

  Widget _buildContent(String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        content,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}
