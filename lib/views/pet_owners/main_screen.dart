import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:innopetcare/main.dart';
import 'package:innopetcare/views/pet_owners/nav_screns/community_forum.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:innopetcare/views/pet_owners/nav_screns/adopts_screen.dart';
import 'package:innopetcare/views/pet_owners/nav_screns/appointments_screen.dart';
import 'package:innopetcare/views/pet_owners/nav_screns/animal_shelter_appointments_screen.dart';
import 'package:innopetcare/views/pet_owners/nav_screns/donate_screen.dart';
import 'package:innopetcare/views/pet_owners/nav_screns/home_page_screen.dart';
import 'package:innopetcare/views/pet_owners/nav_screns/profiles_screen.dart';
import 'package:innopetcare/views/pet_owners/nav_screns/records_screen.dart';
import 'package:innopetcare/views/pet_owners/nav_screns/services_screen.dart';
import 'package:innopetcare/views/pet_owners/nav_screns/volunteer_screen.dart';

class MainScreen extends StatefulWidget {
  final String uid;
  final String? projectId;

  const MainScreen({required this.uid, this.projectId, Key? key})
      : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _pageIndex = 0;
  late String projectId;
  List<Widget> _pages = [];
  List<BottomNavigationBarItem> _navItems = [];
  bool _isLoading = true;
  String? projectType;
  Color unselectedItemColor = const Color(0xFF094886); // Default color
  Color selectedItemColor = const Color(0xFFbc1823);
  bool isEnabled = true;
  bool appointmentsEnabled = true;
  bool communityEnabled = true;
  @override
  void initState() {
    super.initState();
    _requestStoragePermission(); // Request storage permission
    _setupFCM();
    _loadProjectDetails();
    _saveProjectId();
  }

  Future<void> _saveProjectId() async {
    // Obtain shared preferences.
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('projectId', projectId); 
  }

  /// Function to request storage permissions
  Future<void> _requestStoragePermission() async {
    PermissionStatus status = await Permission.storage.request();

    if (status.isGranted) {
      print("Storage permission granted");
    } else if (status.isDenied) {
      print("Storage permission denied. Requesting again...");
      // Optionally, you can re-request permission after some time or provide instructions to enable it.
    } else if (status.isPermanentlyDenied) {
      print("Storage permission permanently denied");
      // Prompt the user to enable the permission from app settings.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Storage permission is permanently denied. Please enable it in settings."),
          action: SnackBarAction(
            label: "Settings",
            onPressed: () {
              openAppSettings(); // Open app settings
            },
          ),
        ),
      );
    }
  }

  void _setupFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request notification permissions
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("User granted permission");
    } else {
      print("User declined or has not accepted permission");
    }

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _showLocalNotification(
          notification.title ?? "Notification",
          notification.body ?? "You have a new message",
        );
      }
    });

    // Handle notification clicks (background and terminated state)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Notification clicked: ${message.data}");
      // Navigate to a specific screen if needed
    });

    // Optional: Fetch and display the current FCM token
    String? token = await messaging.getToken();
    print("FCM Token: $token");
    // You can save this token to Firestore for server-side use
  }

  Future<void> _showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'default_channel', // Channel ID
      'Default', // Channel name
      channelDescription: 'Default notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      title,
      body,
      platformChannelSpecifics,
    );
  }

  Future<void> _loadProjectDetails() async {
    final prefs = await SharedPreferences.getInstance();
    projectId = widget.projectId ??
        prefs.getString('projectId') ??
        'EvBPMJCxjJPlQ98TOhNQdKttjLP2';

    try {
      // Step 1: Fetch the project type from the projects collection
      var projectDoc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .get();

      if (projectDoc.exists) {
        projectType = projectDoc['type'];
      }

      // Step 2: Fetch the header color from global-sections collection
      var globalSectionsDoc = await FirebaseFirestore.instance
          .collection('global-sections')
          .doc(projectId)
          .get();

      if (globalSectionsDoc.exists) {
        var data = globalSectionsDoc.data();
        if (data != null && data.containsKey('headerColor')) {
          setState(() {
            unselectedItemColor =
                Color(int.parse(data['headerColor'].replaceFirst('#', '0xff')));
            selectedItemColor = Color(
                int.parse(data['selectedItemColor'].replaceFirst('#', '0xff')));
          });
        }
      }
      // Step 3: Load isEnabled and setup pages and navigation items
      await _loadIsEnabled();
      // Step 3: Load isEnabled from appointments-section
      await _loadAppointmentsEnabled();

      // Step 3: Load isEnabled from appointments-section
      await _loadCommunityForumEnabled();

      _setupPagesAndNavItems();
    } catch (e) {
      print('Error fetching project details: $e');
    }
  }

  Future<void> _loadIsEnabled() async {
    try {
      // Fetch the document from the pet-sections collection
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection("adopt-sections")
          .doc(projectId)
          .get();

      if (docSnapshot.exists) {
        // Retrieve the isEnabled field
        setState(() {
          isEnabled = docSnapshot.get("isEnabled") ?? true;
          print(isEnabled);
        });
      } else {
        print("Document does not exist");
        setState(() {
          isEnabled = true; // Default value if the document is not found
        });
      }
    } catch (e) {
      print("Error fetching isEnabled: $e");
      setState(() {
        isEnabled = true; // Default value on error
      });
    }
  }

  Future<void> _loadAppointmentsEnabled() async {
    try {
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection("appointments-section")
          .doc(projectId)
          .get();

      if (docSnapshot.exists) {
        // Retrieve the isEnabled field
        setState(() {
          appointmentsEnabled = docSnapshot.get("isEnabled") ?? true;
        });
      } else {
        print("Appointments document does not exist");
        setState(() {
          appointmentsEnabled = true; // Default to true if not found
        });
      }
    } catch (e) {
      print("Error fetching appointmentsEnabled: $e");
      setState(() {
        appointmentsEnabled = true; // Default to true on error
      });
    }
  }

  Future<void> _loadCommunityForumEnabled() async {
    try {
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection("community-forum-section")
          .doc(projectId)
          .get();

      if (docSnapshot.exists) {
        // Retrieve the isEnabled field
        setState(() {
          communityEnabled = docSnapshot.get("isEnabled") ?? true;
        });
      } else {
        print("Community Forum document does not exist");
        setState(() {
          communityEnabled = true; // Default to true if not found
        });
      }
    } catch (e) {
      print("Error fetching communityEnabled: $e");
      setState(() {
        communityEnabled = true; // Default to true on error
      });
    }
  }

  void _setupPagesAndNavItems() {
    if (projectType == 'Veterinary Site') {
      _pages = [
        HomePageScreen(uid: widget.uid, projectId: projectId),
        if (appointmentsEnabled)
          AppointmentsScreen(
              uid: widget.uid,
              projectId: projectId,
              colorTheme: unselectedItemColor),
        ServicesScreen(
            uid: widget.uid,
            projectId: projectId,
            colorTheme: unselectedItemColor),
        PetHealthRecordScreen(
            uid: widget.uid,
            projectId: projectId,
            colorTheme: unselectedItemColor),
        if (isEnabled) // Conditionally add AdoptsScreen
          AdoptsScreen(
              uid: widget.uid,
              projectId: projectId,
              colorTheme: unselectedItemColor),
        if (communityEnabled)
          CommunityForumScreen(
              uid: widget.uid,
              projectId: projectId,
              colorTheme: unselectedItemColor),
        ProfilesScreen(
            uid: widget.uid,
            projectId: projectId,
            colorTheme: unselectedItemColor),
      ];
      _navItems = [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        if (appointmentsEnabled)
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: 'Appointments'),
        BottomNavigationBarItem(
            icon: Icon(Icons.medical_services), label: 'Services'),
        BottomNavigationBarItem(
            icon: Icon(Icons.description), label: 'Records'),
        if (isEnabled) // Conditionally add navigation item
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Adopt'),
        if (communityEnabled)
          BottomNavigationBarItem(
              icon: Icon(Icons.emoji_people_rounded), label: 'Community'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ];
    } else if (projectType == 'Animal Shelter Site') {
      _pages = [
        HomePageScreen(uid: widget.uid, projectId: projectId),
        if (appointmentsEnabled)
          AnimalShelterAppointmentsScreen(
              uid: widget.uid,
              projectId: projectId,
              colorTheme: unselectedItemColor),
        VolunteerScreen(
            uid: widget.uid,
            projectId: projectId,
            colorTheme: unselectedItemColor),
        DonateScreen(
            uid: widget.uid,
            projectId: projectId,
            colorTheme: unselectedItemColor),
        AdoptsScreen(
            uid: widget.uid,
            projectId: projectId,
            colorTheme: unselectedItemColor),
        if (communityEnabled)
          CommunityForumScreen(
              uid: widget.uid,
              projectId: projectId,
              colorTheme: unselectedItemColor),
        ProfilesScreen(
            uid: widget.uid,
            projectId: projectId,
            colorTheme: unselectedItemColor),
      ];
      _navItems = [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        if (appointmentsEnabled)
          BottomNavigationBarItem(
              icon: Icon(Icons.event), label: 'Appointments'),
        BottomNavigationBarItem(
            icon: Icon(Icons.volunteer_activism), label: 'Volunteer'),
        BottomNavigationBarItem(
            icon: Icon(Icons.attach_money), label: 'Donate'),
        BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Adopt'),
        if (communityEnabled)
          BottomNavigationBarItem(
              icon: Icon(Icons.emoji_people_rounded), label: 'Community'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ];
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _pageIndex,
        onTap: (value) {
          setState(() {
            _pageIndex = value;
          });
        },
        unselectedItemColor: unselectedItemColor, // Use fetched color here
        selectedItemColor: selectedItemColor,
        items: _navItems,
      ),
      body: _pages[_pageIndex],
    );
  }
}
