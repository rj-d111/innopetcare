import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  final String uid;
  final String projectId;
  final bool privacyAccepted;

  const PrivacyPolicyScreen(
      {Key? key,
      required this.uid,
      required this.projectId,
      this.privacyAccepted = false})
      : super(key: key);

  @override
  _PrivacyPolicyScreenState createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  String siteName = '';
  bool isLoading = true;
  Color appBarColor = Colors.white;
  DateTime? accountCreated;
  @override
  void initState() {
    super.initState();
    fetchSiteName();
    fetchAccountCreatedDate();
  }

  Future<void> fetchAccountCreatedDate() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> docClient = await FirebaseFirestore
          .instance
          .collection('clients')
          .doc(widget.uid)
          .get();

      if (docClient.exists) {
        final data = docClient.data();
        Timestamp? timestamp = data?['accountCreated'];

        // Convert the Firestore Timestamp to DateTime
        setState(() {
          accountCreated = timestamp != null ? timestamp.toDate() : null;
        });
      }
    } catch (error) {
      print('Error fetching account creation date: $error');
    }
  }

// Method to format the account creation date
  String formatAccountCreatedDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return DateFormat('MMMM d, yyyy').format(date);
  }

  Future<void> fetchSiteName() async {
    try {
      // Fetch the document using the projectId as the document ID
      DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore
          .instance
          .collection('global-sections')
          .doc(widget.projectId)
          .get();

      if (doc.exists) {
        // Safely access the document data
        final data = doc.data();

        setState(() {
          siteName = data?['name'] ?? '';
          appBarColor = data?['headerColor'] != null
              ? Color(int.parse(data!['headerColor'].replaceFirst('#', '0xff')))
              : appBarColor; // Default color if headerColor is null
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching site name: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: appBarColor, // Adjust this to your app bar color
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Check Icon for Privacy Acceptance
                  if (widget.privacyAccepted)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment
                          .start, // Aligns icon to the start of the text
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You have already accepted the Privacy Policy',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                  if (widget.privacyAccepted) const SizedBox(height: 20),

                  // Privacy Policy Heading
                  Text(
                    '$siteName Privacy Policy',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: appBarColor, // Adjust this to your theme color
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Privacy Policy Content
                  Text(
                    'At $siteName, we prioritize your privacy and are committed to safeguarding your personal information. '
                    'This Privacy Policy outlines how we collect, use, disclose, and protect your data when you use our web platform designed for veterinary clinics and animal shelters.\n',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  buildSectionTitle('Information We Collect'),
                  buildContent(
                    'Personal Information: We collect information such as your name, email address, phone number, and any other contact details you provide during registration or use of the platform.\n'
                    'Pet Information: Details about the pets you manage, including names, breeds, ages, medical histories, and adoption statuses.\n'
                    'Usage Data: Information about your interactions with our platform, including IP address, browser type, device information, and pages visited.',
                  ),
                  const SizedBox(height: 20),
                  buildSectionTitle('How We Use Your Information'),
                  buildContent(
                    'Service Delivery: To provide and manage services related to veterinary care, pet management, and communication.\n'
                    'Platform Improvement: To analyze usage trends and enhance user experience by improving our services.\n'
                    'Communication: To send you updates and notifications related to $siteName.',
                  ),
                  const SizedBox(height: 20),
                  buildSectionTitle('Data Security'),
                  buildContent(
                    'We implement industry-standard security measures, including encryption and access controls, to protect your information from unauthorized access and misuse.',
                  ),
                  const SizedBox(height: 20),
                  buildSectionTitle('Your Rights'),
                  buildContent(
                    'You have the right to access, correct, or delete your personal information. To exercise these rights, please contact us at [insert contact information].',
                  ),
                  const SizedBox(height: 20),
                  buildSectionTitle('Changes to This Policy'),
                  buildContent(
                    'We may update this Privacy Policy from time to time. Any changes will be posted on our platform with an updated effective date.',
                  ),
                  const SizedBox(height: 40),
                  buildSectionTitle('Terms of Use for $siteName'),
                  buildContent('Effective Date: [Insert Date]\n'),
                  buildSectionTitle('Acceptance of Terms'),
                  buildContent(
                    'By accessing or using $siteName, you acknowledge that you have read, understood, and agree to be bound by these Terms of Use.',
                  ),
                ],
              ),
            ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: appBarColor,
      ),
    );
  }

  Widget buildContent(String content) {
    return Text(
      content,
      style: TextStyle(fontSize: 14, color: Colors.black),
    );
  }
}
