import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Import local notifications package
import 'package:innopetcare/api/firebase_api.dart';
import 'package:innopetcare/draft.dart';
import 'package:innopetcare/login_screen.dart';
import 'package:innopetcare/sites_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:innopetcare/innopetcare_screen.dart';
import 'package:innopetcare/views/pet_owners/main_screen.dart';

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  await showNotification(
    message.notification?.title ?? "New Notification",
    message.notification?.body ?? "You have a new message",
  );
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();

  // Initialize local notifications
  initializeLocalNotifications();

  // Handle background notifications
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

Future<void> requestStoragePermission(BuildContext context) async {
  if (await Permission.storage.isGranted) {
    print("Storage permission already granted.");
    return;
  }

  if (await Permission.storage.request().isGranted) {
    print("Storage permission granted.");
    return;
  }

  // For Android 13+
  if (await Permission.photos.isGranted) {
    print("Photos permission already granted.");
    return;
  }

  if (await Permission.photos.request().isGranted) {
    print("Photos permission granted.");
    return;
  }

  if (await Permission.photos.isPermanentlyDenied) {
    print("Photos permission permanently denied.");
    await openAppSettings();
  }
}

Future<void> initializeFirebase() async {
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyD4b0LFgPqr0IX5KRemQeoKOX9b3YWVaMU',
      appId: '1:485214746152:android:0823337d728994b982e71d',
      messagingSenderId: '485214746152',
      projectId: 'innopetcare-2a866',
      storageBucket: 'gs://innopetcare-2a866.appspot.com',
    ),
  );
}

void initializeLocalNotifications() {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> showNotification(String title, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'comment_channel', // Unique ID for this channel
    'Comments', // Channel name
    channelDescription: 'Notifications for new comments',
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

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(statusBarColor: Colors.transparent));

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'InnoPetCare',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
        useMaterial3: true,
        fontFamily: 'Poppins-Medium',
      ),
      home: const AuthCheck(), // Start with AuthCheck widget
    );
  }
}

// Widget to check if user is authenticated and retrieve projectId
class AuthCheck extends StatelessWidget {
  const AuthCheck({Key? key}) : super(key: key);

  Future<String?> _getSavedProjectId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Get all keys stored in SharedPreferences
    Set<String> keys = prefs.getKeys();

    print("Keys stored in SharedPreferences:");
    for (String key in keys) {
      print("Key: $key, Value: ${prefs.get(key)}");
    }

    String? projectId = prefs.getString('projectId');
    debugPrint('Retrieved projectId: $projectId');
    return projectId;
  }

  @override
  Widget build(BuildContext context) {
    // Listen to foreground messages

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await requestStoragePermission(context);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Foreground notification received: ${message.notification?.title}");

      // Show a local notification
      showNotification(
        message.notification?.title ?? "New Notification",
        message.notification?.body ?? "You have a new message",
      );
    });

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          // User is logged in
          print(snapshot.data!);
          final user = snapshot.data!;
          return FutureBuilder<String?>(
            future: _getSavedProjectId(),
            builder: (context, projectIdSnapshot) {
              if (projectIdSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              // Navigate to MainScreen with retrieved projectId
              // final projectId = projectIdSnapshot.data ??
              //     '4jDgGh4QCHbsHgXw7VUA'; // Handle null projectId
              final projectId = projectIdSnapshot.data;
              if (projectId == null) {
                // FirebaseAuth.instance.signOut();
                // Log out the user here (replace with your logout logic)
                print('Project ID is null. Logging out user...');
                return SitesScreen(); // Or navigate to your login screen
              }
              if (!user.emailVerified) {
                // FirebaseAuth.instance.signOut();
                return SitesScreen();
              }

              return MainScreen(uid: user.uid, projectId: projectId);
            },
          );
        } else {
          // User is not logged in, go to InnoPetCareScreen
          return InnoPetCareScreen();
        }
      },
    );
  }
}
