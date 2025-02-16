import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SendFeedbackScreen extends StatefulWidget {
  final String uid;
  final String projectId;
  final Color colorTheme;

  const SendFeedbackScreen({
    Key? key,
    required this.uid,
    required this.projectId,
    required this.colorTheme,
  }) : super(key: key);

  @override
  _SendFeedbackScreenState createState() => _SendFeedbackScreenState();
}

class _SendFeedbackScreenState extends State<SendFeedbackScreen> {
  List<Map<String, dynamic>> questions = [];
  Map<String, dynamic> formData = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchProjectInfo();
    fetchQuestions();
  }

  Future<void> fetchProjectInfo() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('global-sections')
          .where('slug', isEqualTo: widget.projectId)
          .get();

    } catch (error) {
      print("Error fetching project info: $error");
    }
  }

  Future<void> fetchQuestions() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('user-feedback')
          .doc(widget.projectId)
          .collection('questions')
          .orderBy('questionCreated', descending: false)
          .get();

      setState(() {
        questions = snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
            .toList();
        loading = false;
      });
    } catch (error) {
      print("Error fetching questions: $error");
      setState(() {
        loading = false;
      });
    }
  }

  void handleChange(String questionId, dynamic value) {
    setState(() {
      formData[questionId] = value;
    });
  }

  Future<void> handleSubmit() async {
    // Validate that all required fields are filled out
    List<Map<String, dynamic>> unansweredQuestions = questions
        .where((q) =>
            !formData.containsKey(q['id']) ||
            (q['type'] == 'checkbox' &&
                (formData[q['id']] as List?)?.isEmpty == true))
        .toList();

    if (unansweredQuestions.isNotEmpty) {
      Fluttertoast.showToast(msg: "Please answer all the questions!");
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('user-feedback-users')
          .doc(widget.projectId)
          .collection('responses')
          .add({
        'createdAt': DateTime.now(),
        'projectId': widget.projectId,
        'responses': formData,
      });

      Fluttertoast.showToast(msg: "Feedback submitted successfully!");

      // Reset form
      setState(() {
        formData.clear();
      });
    } catch (error) {
      print("Error submitting feedback: $error");
      Fluttertoast.showToast(msg: "Failed to submit feedback.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'User Feedback',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: widget.colorTheme,
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var question in questions) buildQuestion(question),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            widget.colorTheme,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        "Submit Feedback",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget buildQuestion(Map<String, dynamic> question) {
    switch (question['type']) {
      case 'rating':
        return buildStarRating(question);
      case 'text':
        return buildTextInput(question);
      case 'choice':
        return buildRadioOptions(question);
      case 'checkbox':
        return buildCheckboxOptions(question);
      default:
        return Container();
    }
  }

  Widget buildStarRating(Map<String, dynamic> question) {
    int rating = formData[question['id']] ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question['question'], style: const TextStyle(fontSize: 18)),
        Row(
          children: List.generate(5, (index) {
            return IconButton(
              icon: Icon(
                Icons.star,
                color: index < rating ? Colors.yellow : Colors.grey,
              ),
              onPressed: () => handleChange(question['id'], index + 1),
            );
          }),
        ),
      ],
    );
  }

  Widget buildTextInput(Map<String, dynamic> question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question['question'], style: const TextStyle(fontSize: 18)),
        TextField(
          onChanged: (value) => handleChange(question['id'], value),
          decoration: InputDecoration(
            hintText: question['placeholder'] ?? '',
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget buildRadioOptions(Map<String, dynamic> question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question['question'], style: const TextStyle(fontSize: 18)),
        for (var option in question['options'])
          RadioListTile(
            value: option,
            groupValue: formData[question['id']],
            onChanged: (value) => handleChange(question['id'], value),
            title: Text(option),
          ),
      ],
    );
  }

  Widget buildCheckboxOptions(Map<String, dynamic> question) {
    List<String> selectedOptions = formData[question['id']] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question['question'], style: const TextStyle(fontSize: 18)),
        for (var option in question['options'])
          CheckboxListTile(
            value: selectedOptions.contains(option),
            onChanged: (bool? value) {
              if (value == true) {
                selectedOptions.add(option);
              } else {
                selectedOptions.remove(option);
              }
              handleChange(question['id'], selectedOptions);
            },
            title: Text(option),
          ),
      ],
    );
  }
}
