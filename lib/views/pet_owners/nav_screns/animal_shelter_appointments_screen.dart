import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:innopetcare/terms_conditions_screen.dart';
import 'package:innopetcare/views/pet_owners/nav_screns/dashboard_screen.dart';
import 'package:innopetcare/views/pet_owners/nav_screns/notifications_screen.dart';
import 'package:innopetcare/views/privacy_policy_screen.dart';
import 'package:intl/intl.dart';

class AnimalShelterAppointmentsScreen extends StatefulWidget {
  final String uid;
  final String projectId;
  final Color colorTheme;

  const AnimalShelterAppointmentsScreen(
      {required this.uid,
      required this.projectId,
      required this.colorTheme,
      Key? key})
      : super(key: key);

  @override
  _AnimalShelterAppointmentsScreenState createState() =>
      _AnimalShelterAppointmentsScreenState();
}

class _AnimalShelterAppointmentsScreenState
    extends State<AnimalShelterAppointmentsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentsController = TextEditingController();
  final _numberOfVisitorsController = TextEditingController();

  String? _selectedReason;
  DateTime? _selectedDate;
  String? _selectedTime;
  bool agreeTerms = false;
  bool agreePrivacy = false;
  Map<String, dynamic> customSchedules = {};
  List<String> _times = [];

  List<Object>? disableDaysOfWeekEdit;
  @override
  void initState() {
    super.initState();
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

  // Dropdown options
  final List<String> _reasons = [
    "Visit Shelter",
    "Drop-off Donations",
    "Volunteer Work",
    "For Adoption",
  ];

  DateTime getNextAvailableDate(
      DateTime currentDate, List<int> disableDaysOfWeek) {
    print(disableDaysOfWeek);
    DateTime nextDate = currentDate.add(Duration(days: 1));
    // Start from tomorrow
    while (disableDaysOfWeek.contains(nextDate.weekday)) {
      nextDate = nextDate.add(Duration(days: 1));
      // Move to the next day
    }
    return nextDate;
  }



List<String> getTimes(DateTime date) {
  String dayKey = [
    "sunday",
    "monday",
    "tuesday",
    "wednesday",
    "thursday",
    "friday",
    "saturday"
  ][date.weekday % 7];

  Map<String, dynamic>? schedule = customSchedules['customSchedules']?[dayKey];
  if (schedule == null) {
    return [];
  }

  String startTime = schedule['start']; // Stored as "HH:mm"
  String endTime = schedule['end']; // Stored as "HH:mm"

  int startHour = int.parse(startTime.split(':')[0]);
  int startMinute = int.parse(startTime.split(':')[1]);
  int endHour = int.parse(endTime.split(':')[0]);
  int endMinute = int.parse(endTime.split(':')[1]);

  List<String> timeSlots = [];
  int currentHour = startHour;
  int currentMinute = startMinute;

  while (currentHour < endHour ||
      (currentHour == endHour && currentMinute < endMinute)) {
    // Use 24-hour format for backend logic
    String timeSlot24Hour = _formatTime24Hour(currentHour, currentMinute);
    timeSlots.add(timeSlot24Hour);

    currentMinute += 30;
    if (currentMinute >= 60) {
      currentMinute = 0;
      currentHour += 1;
    }
  }

  return timeSlots;
}

// Helper to format time in 24-hour format (HH:mm)
String _formatTime24Hour(int hour, int minute) {
  return "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";
}

// Helper to convert 24-hour format (HH:mm) to 12-hour format (hh:mm a)
String formatTimeTo12Hour(String time24Hour) {
  final hour = int.parse(time24Hour.split(':')[0]);
  final minute = int.parse(time24Hour.split(':')[1]);
  final time = DateTime(0, 1, 1, hour, minute);
  return DateFormat('hh:mm a').format(time);
}

Future<List<String>> fetchAvailableTimeSlots(DateTime date) async {
  try {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('projectId', isEqualTo: widget.projectId)
        .get();

    String selectedDate = DateFormat('yyyy-MM-dd').format(date);

    List<String> bookedSlots = snapshot.docs
        .map((doc) {
          if (doc['status'] != 'rejected') {
            DateTime eventDateTime =
                (doc['event_datetime'] as Timestamp).toDate();
            if (DateFormat('yyyy-MM-dd').format(eventDateTime) == selectedDate) {
              return DateFormat('HH:mm').format(eventDateTime); // 24-hour format
            }
          }
          return null;
        })
        .where((slot) => slot != null)
        .cast<String>()
        .toList();

    List<String> timeSlotsForDay = getTimes(date);

    List<String> availableSlots = timeSlotsForDay
        .where((slot) => !bookedSlots.contains(slot))
        .toList();

    // Convert available slots to 12-hour format for display
    return availableSlots.map((slot) => formatTimeTo12Hour(slot)).toList();
  } catch (e) {
    print("Error fetching available time slots: $e");
    return [];
  }
}



  Future<void> _bookAppointment() async {
    if (_formKey.currentState!.validate()) {
      if (!agreeTerms) {
        setState(() => agreeTerms = true); // Activate warning color
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text("Please agree to the Terms and Conditions to proceed."),
          ),
        );
        return;
      }

      if (!agreePrivacy) {
        setState(() => agreePrivacy = true); // Activate warning color
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Please agree to the Privacy Policy to proceed."),
          ),
        );
        return;
      }

      try {
        // Parse the selected time
        final timeParts = _selectedTime!.split(' ');
        final timeNumbers = timeParts[0].split(':');
        final int hour = int.parse(timeNumbers[0]) +
            (timeParts[1].toLowerCase() == 'pm' &&
                    int.parse(timeNumbers[0]) != 12
                ? 12
                : 0); // Adjust for PM hours
        final int minute = int.parse(timeNumbers[1]);

        // Create a DateTime object for the selected date and time
        final selectedDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          hour,
          minute,
        );

        // Save the appointment
        await FirebaseFirestore.instance.collection('appointments').add({
          'clientId': widget.uid,
          'event_datetime': selectedDateTime,
          'projectId': widget.projectId,
          'reason': _selectedReason,
          'additional': _commentsController.text,
          'numberOfVisitors': int.parse(_numberOfVisitorsController.text),
          'status': 'pending',
          'createdAt': Timestamp.now(),
        });

        // Notify the user
        final formattedDateTime =
            DateFormat('MMMM d, yyyy h:mm a').format(selectedDateTime);
        final message =
            'Your appointment has been submitted for $formattedDateTime. Status: Pending.';
        _showLocalNotification(message);

        // Save notification
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(widget.projectId)
            .collection(widget.uid)
            .add({
          'message': message,
          'read': false,
          'type': 'appointment',
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Appointment booked successfully")),
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
        print("Error booking appointment: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to book appointment")),
        );
      }
    }
  }

  Future<void> _showLocalNotification(String message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'appointment_channel', // ID
      'Appointment Notifications', // Name
      channelDescription: 'Notifications for appointment bookings',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      'Appointment Confirmation',
      message,
      platformChannelSpecifics,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      color: widget
                          .colorTheme, // Set the color to widget.colorTheme
                    ),
                  ),
                ),
              ),
              // Reason for Appointment
              DropdownButtonFormField<String>(
                decoration:
                    InputDecoration(labelText: "Reason for Appointment"),
                items: _reasons
                    .map((reason) =>
                        DropdownMenuItem(value: reason, child: Text(reason)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedReason = value),
                validator: (value) => value == null
                    ? "Please select a reason for the appointment"
                    : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: "Appointment Date"),
                readOnly: true,
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    firstDate:
                        DateTime.now().add(Duration(days: 1)), // Disable today
                    lastDate: DateTime(
                        DateTime.now().year + 1), // Allow dates up to one year
                    selectableDayPredicate: (DateTime day) {
                      // Parse custom schedules
                      List<DateTime> blockedDays =
                          (customSchedules['blockedDays'] as List<dynamic>)
                              .map((date) => DateTime.parse(date))
                              .toList();
                      List<int> disableDaysOfWeek =
                          List<int>.from(customSchedules['disableDaysOfWeek']);
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
                    // Clear the time selection first to avoid assertion errors
                    setState(() {
                      _selectedTime =
                          null; // Reset selected time if the date changes
                      _selectedDate = pickedDate; // Update the selected date
                      _times
                          .clear(); // Clear previous times to avoid mismatched options
                    });

                    // Fetch and update available time slots for the new date
                    final availableSlots =
                        await fetchAvailableTimeSlots(pickedDate);
                    final times = getTimes(pickedDate);

                    // Update the time slots after clearing
                    setState(() {
                      _times.addAll(availableSlots);
                      _times.addAll(times);
                    });
                  }
                },
                validator: (value) => _selectedDate == null
                    ? "Please select an appointment date"
                    : null,
                controller: TextEditingController(
                  text: _selectedDate != null
                      ? DateFormat.yMd().format(_selectedDate!)
                      : '',
                ),
              ),

              SizedBox(height: 16),

// Appointment Time
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: "Appointment Time"),
                items: _times
                    .map((time) =>
                        DropdownMenuItem(value: time, child: Text(time)))
                    .toList(),
                value: _selectedTime, // Bind selected time here
                onChanged: (value) => setState(() => _selectedTime = value),
                validator: (value) =>
                    value == null ? "Please select an appointment time" : null,
              ),

              SizedBox(height: 16),

              // Number of Visitors
              TextFormField(
                controller: _numberOfVisitorsController,
                decoration: InputDecoration(labelText: "Number of Visitors"),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter the number of visitors";
                  }
                  final intValue = int.tryParse(value);
                  if (intValue == null || intValue < 1) {
                    return "Number of visitors must be at least 1";
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Comments/Suggestions
              TextFormField(
                controller: _commentsController,
                decoration: InputDecoration(labelText: "Comments/Suggestions"),
                maxLines: 3,
              ),
              SizedBox(height: 16),

              // Terms and Conditions checkbox
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox for Terms and Conditions
                  CheckboxListTile(
                    title: GestureDetector(
                      onTap: () {
                        // Navigate to TermsConditionsScreen when text is tapped
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

                  // Checkbox for Privacy Policy
                  CheckboxListTile(
                    title: GestureDetector(
                      onTap: () {
                        // Navigate to PrivacyPolicyScreen when text is tapped
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
                  const SizedBox(height: 10),
                ],
              ),
              SizedBox(height: 16),

              // Book Appointment Button
              ElevatedButton(
                onPressed: _bookAppointment,
                child: Text("Book Appointment"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
