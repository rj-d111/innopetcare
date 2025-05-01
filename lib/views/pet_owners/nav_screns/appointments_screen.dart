import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:innopetcare/terms_conditions_screen.dart';
import 'package:innopetcare/views/pet_owners/nav_screns/notifications_screen.dart';
import 'package:innopetcare/views/privacy_policy_screen.dart';
import 'package:intl/intl.dart';
import 'package:cloud_functions/cloud_functions.dart';


class AppointmentsScreen extends StatefulWidget {
  final String uid;
  final String projectId;
  final Color colorTheme;

  AppointmentsScreen(
      {required this.uid, required this.projectId, required this.colorTheme});

  @override
  _AppointmentsScreenState createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedService;
  String? selectedPet;
  DateTime? selectedDate;
  String? selectedTime;
  String? condition;
  String? additionalInfo;
  bool agreePrivacy = false;
  bool agreeTerms = false;
  List<String> availableTimeSlots = [];
  List<String> bookedTimeSlots = [];

  List<String> services = [];
  List<String> pets = ['No Pets'];
  Map<String, dynamic> customSchedules = {};

  @override
  void initState() {
    super.initState();
    fetchServices();
    fetchPets();
    fetchCustomSchedules();
  }

  Future<void> fetchCustomSchedules() async {
    //Reference to the document
    DocumentReference docRef = FirebaseFirestore.instance
        .collection('appointments-section')
        .doc(widget.projectId);
// Fetch the document
    DocumentSnapshot docSnap = await docRef.get();
    if (docSnap.exists) {
// Extract data from the document
      Map<String, dynamic> data = docSnap.data() as Map<String, dynamic>;
      customSchedules = data;

      print(customSchedules);
// Save the fetched custom schedules
    } else {
      print("No such document!");
    }
  }

  // Fetch services from Firestore
  Future<void> fetchServices() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('services')
        .where('projectId', isEqualTo: widget.projectId)
        .get();

    List<String> fetchedServices =
        snapshot.docs.map((doc) => doc['title'].toString()).toList();

    setState(() {
      services = fetchedServices.toSet().toList();
    });
  }

  // Fetch pets associated with the user
  Future<void> fetchPets() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('pets')
        .where('clientId', isEqualTo: widget.uid)
        .where('projectId', isEqualTo: widget.projectId)
        .get();

    if (snapshot.docs.isNotEmpty) {
      List<String> fetchedPets =
          snapshot.docs.map((doc) => doc['petName'].toString()).toList();

      setState(() {
        pets = fetchedPets.toSet().toList();
      });
    } else {
      setState(() {
        pets = []; // No pets available, clear the list
      });
    }
  }

  List<String> getTimeSlotsForDay(DateTime date) {
    print(date);
    List<String> timeSlots = [];
    String dayKey = [
      "sunday",
      "monday",
      "tuesday",
      "wednesday",
      "thursday",
      "friday",
      "saturday"
    ][date.weekday % 7]; // Map 1-7 to the correct index for days of the week

    Map<String, dynamic>? schedule =
        customSchedules['customSchedules']?[dayKey];
    if (schedule == null) {
      // No schedule for the selected day
      return [];
    }

    // Parse start and end times
    String startTime = schedule['start'];
    String endTime = schedule['end'];

    int startHour = int.parse(startTime.split(':')[0]);
    int startMinute = int.parse(startTime.split(':')[1]);
    int endHour = int.parse(endTime.split(':')[0]);
    int endMinute = int.parse(endTime.split(':')[1]);

    // Generate time slots in 30-minute intervals
    int currentHour = startHour;
    int currentMinute = startMinute;

    while (currentHour < endHour ||
        (currentHour == endHour && currentMinute < endMinute)) {
      String timeSlot = _formatTime(currentHour, currentMinute);
      timeSlots.add(timeSlot);

      // Increment by 30 minutes
      currentMinute += 30;
      if (currentMinute >= 60) {
        currentMinute = 0;
        currentHour += 1;
      }
    }

    return timeSlots;
  }

// Fetch booked slots and filter available time slots
  Future<void> fetchAvailableTimeSlots(DateTime date) async {
    try {
      // Fetch all appointments for the project
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('projectId', isEqualTo: widget.projectId)
          .get();

      // Format the selected date
      String selectedDate = DateFormat('yyyy-MM-dd').format(date);

      // Filter appointments for the selected date
      List<String> bookedSlots = snapshot.docs
          .map((doc) {
            if (doc['status'] != 'rejected') {
              DateTime eventDateTime =
                  (doc['event_datetime'] as Timestamp).toDate();
              if (DateFormat('yyyy-MM-dd').format(eventDateTime) ==
                  selectedDate) {
                return DateFormat('h:mm a').format(eventDateTime);
              }
            }
            return null; // Exclude irrelevant appointments
          })
          .where((timeSlot) => timeSlot != null) // Remove null values
          .cast<String>()
          .toList();

      // Generate time slots based on the schedule for the selected day
      List<String> timeSlotsForDay = getTimeSlotsForDay(date);

      // Update the state with booked and available time slots
      setState(() {
        bookedTimeSlots = bookedSlots;
        availableTimeSlots = timeSlotsForDay
            .where((slot) => !bookedTimeSlots.contains(slot))
            .toList();
      });
    } catch (e) {
      print("Error fetching booked slots: $e");
    }
  }

// Helper function to format time in 12-hour format
  String _formatTime(int hour, int minute) {
    final period = hour < 12 ? "AM" : "PM";
    final formattedHour = hour % 12 == 0 ? 12 : hour % 12;
    final formattedMinute = minute.toString().padLeft(2, '0');
    return "$formattedHour:$formattedMinute $period";
  }

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Exit App"),
            content: Text("Are you sure you want to quit?"),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(false), // Dismiss dialog
                child: Text("No"),
              ),
              TextButton(
                onPressed: () {
                  // Close dialog and exit app
                  Navigator.of(context).pop(true);
                  if (Platform.isAndroid) {
                    SystemNavigator.pop(); // Closes the app on Android
                  } else if (Platform.isIOS) {
                    exit(0); // Forces the app to quit on iOS
                  }
                },
                child: Text("Yes"),
              ),
            ],
          ),
        ) ??
        false; // Return false if dialog is dismissed
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool shouldExit = await _showExitConfirmationDialog(context);
        return shouldExit;
      },
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 32.0, bottom: 16.0),
                  child: Center(
                    child: Text(
                      'Set Appointment',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: widget.colorTheme,
                      ),
                    ),
                  ),
                ),
                DropdownButtonFormField(
                  decoration: const InputDecoration(
                      labelText: 'Reason for Appointment'),
                  value: services.isNotEmpty ? selectedService : null,
                  items: services.isNotEmpty
                      ? services
                          .map((service) => DropdownMenuItem(
                                child: Text(service),
                                value: service,
                              ))
                          .toList()
                      : [],
                  onChanged: (value) {
                    setState(() {
                      selectedService = value as String?;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select a reason' : null,
                ),
                const SizedBox(height: 16),
                pets.isEmpty // Check if pets list is empty
                    ? Text(
                        'You have no pets registered. You cannot create an appointment.',
                        style: TextStyle(color: Colors.red),
                      )
                    : DropdownButtonFormField(
                        decoration:
                            const InputDecoration(labelText: 'Select Pet'),
                        value: selectedPet,
                        items: pets
                            .map((pet) => DropdownMenuItem(
                                  child: Text(pet),
                                  value: pet,
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedPet = value as String?;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Please select a pet' : null,
                      ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now().add(Duration(days: 1)),
                      lastDate: DateTime(2100),
                      selectableDayPredicate: (DateTime day) {
                        // Parse custom schedules
                        List<DateTime> blockedDays =
                            (customSchedules['blockedDays'] as List<dynamic>)
                                .map((date) => DateTime.parse(date))
                                .toList();
                        List<int> disableDaysOfWeek = List<int>.from(
                            customSchedules['disableDaysOfWeek']);

                        // Convert 0 (Sunday) to 7 (Sunday) to match DateTime.weekday representation
                        disableDaysOfWeek = disableDaysOfWeek
                            .map((day) => day == 0 ? 7 : day)
                            .toList();

                        // Check if the day is in blockedDays
                        if (blockedDays
                            .contains(DateTime(day.year, day.month, day.day))) {
                          return false;
                        }

                        // Check if the day is one of the disabled days of the week
                        if (disableDaysOfWeek.contains(day.weekday)) {
                          return false;
                        }

                        // Otherwise, allow selection
                        return true;
                      },
                    );
                    if (pickedDate != null) {
                      setState(() {
                        selectedDate = pickedDate;
                        selectedTime = null;
                      });
                      getTimeSlotsForDay(pickedDate); // Fetch booked slots
                      fetchAvailableTimeSlots(pickedDate);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey, width: 1),
                      ),
                    ),
                    child: Text(
                      selectedDate != null
                          ? '${selectedDate!.toLocal()}'.split(' ')[0]
                          : 'Select Date',
                      style: TextStyle(
                        color:
                            selectedDate != null ? Colors.black : Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Select Time'),
                  value: selectedTime,
                  items: availableTimeSlots
                      .map((time) => DropdownMenuItem(
                            child: Text(time),
                            value: time,
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedTime = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select a time slot' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Please share condition about your pet'),
                  maxLines: 3,
                  onSaved: (value) => condition = value,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Additional Information'),
                  maxLines: 3,
                  onSaved: (value) => additionalInfo = value,
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TermsConditionsScreen(
                            uid: widget.uid,
                            projectId: widget.projectId,
                          ),
                        ),
                      );
                    },
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
                  onChanged: (bool? value) {
                    setState(() {
                      agreeTerms = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  title: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PrivacyPolicyScreen(
                            uid: widget.uid,
                            projectId: widget.projectId,
                          ),
                        ),
                      );
                    },
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
                  onChanged: (bool? value) {
                    setState(() {
                      agreePrivacy = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed:
                      pets.isEmpty || !agreePrivacy ? null : submitAppointment,
                  child: const Text('Submit Appointment'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

Future<void> submitAppointment() async {
  if (_formKey.currentState!.validate()) {
    _formKey.currentState!.save();

    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select both date and time')),
      );
      return;
    }

    // Parse time
    final timeParts = selectedTime!.split(':');
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1].split(' ')[0]);
    String period = timeParts[1].split(' ')[1]; // AM or PM

    if (period == 'PM' && hour != 12) {
      hour += 12;
    } else if (period == 'AM' && hour == 12) {
      hour = 0;
    }

    final selectedDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      hour,
      minute,
    );

    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDateTime);
    final formattedTime =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    try {
      // Step 1: Reserve the time slot via Firebase Function
      final functions = FirebaseFunctions.instanceFor();
      final callable = functions.httpsCallable('reserveVetAppointmentSlot');

      final response = await callable.call({
        'clientId': widget.uid,
        'projectId': widget.projectId,
        'date': formattedDate,
        'time': formattedTime,
      });

      if (response.data['success'] != true) {
        throw Exception("Slot reservation failed: ${response.data['message']}");
      }

      // Step 2: Add appointment to Firestore
      await FirebaseFirestore.instance.collection('appointments').add({
        'clientId': widget.uid,
        'condition': condition,
        'additional': additionalInfo,
        'event_datetime': Timestamp.fromDate(selectedDateTime),
        'pet': selectedPet,
        'projectId': widget.projectId,
        'reason': selectedService,
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });

      print("Appointment submitted successfully!");

      final userMessage =
          'Your appointment has been submitted for ${DateFormat('MMMM d, yyyy h:mm a').format(selectedDateTime)}. Status: Pending.';

      // Step 3: Save notification
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(widget.projectId)
          .collection(widget.uid)
          .add({
        'message': userMessage,
        'read': false,
        'timestamp': Timestamp.now(),
        'type': 'appointment',
      });

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment submitted successfully!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => NotificationsScreen(
            uid: widget.uid,
            projectId: widget.projectId,
            colorTheme: widget.colorTheme,
          ),
        ),
      );
    } catch (e) {
      print("Error submitting appointment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit appointment')),
      );
    }
  } else {
    print("Form validation failed");
  }
}
}
