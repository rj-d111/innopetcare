import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TermsConditionsScreen extends StatefulWidget {
  final String uid;
  final String projectId;
  final bool termsAccepted;
  const TermsConditionsScreen(
      {Key? key,
      required this.uid,
      required this.projectId,
      this.termsAccepted = false})
      : super(key: key);

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {
  String siteName = '';
  bool loading = true;
  Color appBarColor = Colors.white;

  @override
  void initState() {
    super.initState();
    fetchSiteName();
  }

  Future<void> fetchSiteName() async {
    try {
      // Fetch the document from 'global-sections' using the document ID (projectId)
      final DocumentSnapshot<Map<String, dynamic>> globalSectionDoc =
          await FirebaseFirestore.instance
              .collection('global-sections')
              .doc(widget.projectId)
              .get();

      // Check if the document exists
      if (globalSectionDoc.exists) {
        final data = globalSectionDoc.data();
        setState(() {
          siteName = data?['name'] ?? 'InnoPetCare';
          appBarColor =
              Color(int.parse(data?['headerColor'].replaceFirst('#', '0xff')));
          loading = false;
        });
      } else {
        setState(() {
          siteName = 'InnoPetCare';
          loading = false;
        });
      }
    } catch (e) {
      print('Error fetching site name: $e');
      setState(() {
        siteName = 'Animal Shelter';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: appBarColor, // Change this to your app bar color
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Check Icon for Terms Acceptance
                  if (widget.termsAccepted)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment
                          .start, // Aligns the icon with the start of the text
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You have already accepted the Terms and Conditions',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                  if (widget.termsAccepted) const SizedBox(height: 20),

                  // Terms and Conditions Heading
                  Text(
                    '$siteName Terms and Conditions',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Terms and Conditions Content
                  buildTermsContent(siteName),
                ],
              ),
            ),
    );
  }

  /// Helper method to build the Terms & Conditions content dynamically
  Widget buildTermsContent(String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome to $name. By accessing or using our services, you agree to comply with and be bound by the following terms and conditions. Please read them carefully.',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        const Text(
          'General',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          'These terms and conditions govern your use of $name’s website and services.',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        const Text(
          'We require 24 hours\' notice for any cancellations or rescheduling.',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        const Text(
          'Services',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          'It is your responsibility to arrive on time for your appointment. If you are late, we may need to reschedule your appointment to ensure other clients are not inconvenienced.',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        Text(
          'We reserve the right to refuse treatment to any animal if it is deemed necessary for health, safety, or ethical reasons.',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        const Text(
          'Medical Records',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          '$name will take all reasonable care in providing services to your pet. However, we cannot be held liable for any unforeseen complications or adverse reactions resulting from treatments.',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        Text(
          'You agree to indemnify and hold $name harmless from any claims, damages, or expenses arising from your use of our services.',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        const Text(
          'Privacy',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          'We are committed to protecting your privacy. All personal information collected will be used in accordance with our Privacy Policy.',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        Text(
          'We may use your contact information to send you updates, reminders, and promotional materials related to our services.',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        const Text(
          'Changes to Terms',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          '$name reserves the right to modify these terms and conditions at any time. Any changes will be posted on our website and will become effective immediately.',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        const Text(
          'Your continued use of our services after any changes constitutes your acceptance of the new terms and conditions.',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        const Text(
          'Governing Law',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          'These terms and conditions are governed by and construed in accordance with the laws of the jurisdiction in which $name operates.',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        Text(
          'Any disputes arising out of or in connection with these terms and conditions shall be subject to the exclusive jurisdiction of the courts in that jurisdiction.',
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}
