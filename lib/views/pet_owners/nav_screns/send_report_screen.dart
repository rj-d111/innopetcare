import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SendReportScreen extends StatefulWidget {
  final String uid;
  final String projectId;
  final Color colorTheme;

  const SendReportScreen({
    Key? key,
    required this.uid,
    required this.projectId,
    required this.colorTheme,
  }) : super(key: key);

  @override
  State<SendReportScreen> createState() => _SendReportScreenState();
}

class _SendReportScreenState extends State<SendReportScreen> {
  List<Map<String, dynamic>> questions = [];
  Map<String, String> formData = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    setState(() => loading = true);

    try {
      // Fetch questions from Firestore
      final questionsRef = FirebaseFirestore.instance
          .collection('send-report-section/${widget.projectId}/questions')
          .orderBy('sectionCreated', descending: false);

      final questionsSnapshot = await questionsRef.get();

      setState(() {
        questions = questionsSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();
        loading = false;
      });
    } catch (e) {
      print('Error fetching questions: $e');
      setState(() => loading = false);
    }
  }

  // Handle input changes
  void handleChange(String id, String value) {
    setState(() {
      formData[id] = value;
    });
  }

  // Handle form submission
  Future<void> handleSubmit() async {
    try {
      if (widget.projectId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project ID is missing.')),
        );
        return;
      }

      // Prepare the response data
      final response = {
        'projectId': widget.projectId,
        'responses': formData,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Save to Firestore: /send-report-users/{projectId}/responses
      final responsesRef = FirebaseFirestore.instance
          .collection('send-report-users/${widget.projectId}/responses');
      await responsesRef.add(response);

      // Show success message and reset form
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted successfully!')),
      );
      setState(() {
        formData = {};
      });
    } catch (e) {
      print('Error submitting report: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit report.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Report'),
        backgroundColor: widget.colorTheme,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Send Report',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ...questions.map((question) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            question['question'] ?? '',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue: formData[question['id']] ?? '',
                            onChanged: (value) =>
                                handleChange(question['id'], value),
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: question['placeholder'] ?? '',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.colorTheme,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('Submit Report', style: TextStyle(color: Colors.white),),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
