import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:innopetcare/views/pet_owners/nav_screns/animal_shelter_appointments_screen.dart';
import 'package:innopetcare/views/pet_owners/nav_screns/appointments_screen.dart';
import 'package:innopetcare/views/pet_owners/nav_screns/messages_screen.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  final String uid;
  final String projectId;
  final Color colorTheme;

  const DashboardScreen(
      {Key? key,
      required this.uid,
      required this.projectId,
      required this.colorTheme})
      : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String projectName = "";
  String clientName = "";
  String clientId = "";
  String headerColor = "#ff4081"; // Default color
  bool isAnimalShelter = false;
  Map<String, dynamic>? upcomingAppointment;

  @override
  void initState() {
    super.initState();
    fetchClientDetails();
    fetchProjectDetails();
    fetchUpcomingAppointment();
  }

  Future<void> fetchClientDetails() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          clientId = user.uid;
          clientName = user.displayName ?? "User";
        });
      }
    } catch (e) {
      print('Error fetching client details: $e');
    }
  }

  Future<void> fetchProjectDetails() async {
    try {
      final projectQuery = await FirebaseFirestore.instance
          .collection('global-sections')
          .doc(widget.projectId)
          .get();

      if (projectQuery.exists) {
        final data = projectQuery.data();
        if (data != null) {
          setState(() {
            projectName = data['name'] ?? "Project";
            headerColor = data['headerColor'] ?? "#ff4081";
          });
        }

        // Fetch project type
        final projectRef = FirebaseFirestore.instance
            .collection('projects')
            .doc(widget.projectId);
        final projectSnapshot = await projectRef.get();

        if (projectSnapshot.exists) {
          setState(() {
            isAnimalShelter = projectSnapshot['type'] == "Animal Shelter Site";
          });
        }
      }
    } catch (e) {
      print('Error fetching project details: $e');
    }
  }

  Future<void> fetchUpcomingAppointment() async {
    try {
      final appointmentsRef =
          FirebaseFirestore.instance.collection('appointments');
      final querySnapshot = await appointmentsRef
          .where('clientId', isEqualTo: clientId)
          .where('projectId', isEqualTo: widget.projectId)
          .get();

      final appointments = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Filter and sort future appointments
      final futureAppointments = appointments
          .map((appointment) {
            appointment['event_datetime'] =
                (appointment['event_datetime'] as Timestamp).toDate();
            return appointment;
          })
          .where((appointment) =>
              appointment['event_datetime'].isAfter(DateTime.now()))
          .toList()
        ..sort((a, b) => a['event_datetime'].compareTo(b['event_datetime']));

      setState(() {
        upcomingAppointment =
            futureAppointments.isNotEmpty ? futureAppointments.first : null;
      });
    } catch (e) {
      print('Error fetching appointments: $e');
    }
  }

  String formatAppointmentDate(DateTime date) {
    return DateFormat('MMMM d, yyyy h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back Button
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: widget.colorTheme),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 16),

            // Centered "Dashboard" Text
            Center(
              child: Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: widget.colorTheme,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Welcome Message Container (No Box Shadow, No Background Color)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome $clientName!',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "We're happy to see you here at $projectName",
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Upcoming Appointment Container (No Box Shadow, No Background Color)
            if (upcomingAppointment != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Upcoming Appointment",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Your appointment is on: ${formatAppointmentDate(upcomingAppointment!['event_datetime'])}",
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      "Status: ${upcomingAppointment!['status']}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 48.0),

            // Button to navigate to the Appointments Screen
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MessagesScreen(
                      projectId: widget.projectId,
                      uid: widget.uid,
                      colorTheme: widget.colorTheme,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.message, color: Colors.white),
              label: const Text(
                "Connected Care Center",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.colorTheme,
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
