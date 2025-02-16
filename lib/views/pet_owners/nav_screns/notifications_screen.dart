import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:innopetcare/views/pet_owners/nav_screns/home_page_screen.dart';
import 'package:intl/intl.dart';
import 'package:innopetcare/views/pet_owners/main_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final String uid;
  final String projectId;
  final Color colorTheme;

  NotificationsScreen({
    required this.uid,
    required this.projectId,
    required this.colorTheme,
  });

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late FlutterLocalNotificationsPlugin _localNotifications;

  @override
  void initState() {
    super.initState();
    _setupLocalNotifications();
    _setupFirestoreListener();
    _setupFCM();
  }

  // Initialize local notifications
  void _setupLocalNotifications() {
    _localNotifications = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
            '@mipmap/ic_launcher'); // Replace with your app icon

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    _localNotifications.initialize(initializationSettings);
  }

  // Setup Firestore listener for real-time updates
  void _setupFirestoreListener() {
    FirebaseFirestore.instance
        .collection('notifications')
        .doc(widget.projectId)
        .collection(widget.uid)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          // Trigger a local notification for new data
          _showLocalNotification(change.doc['message'] ?? 'New Notification');
        }
      }
    });
  }

  // Display a local notification
  Future<void> _showLocalNotification(String message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'notification_channel', // Channel ID
      'Notifications', // Channel Name
      channelDescription: 'Notification channel for app updates',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      0, // Notification ID
      'New Notification', // Notification Title
      message, // Notification Body
      platformDetails,
    );
  }

  // Setup Firebase Cloud Messaging
  void _setupFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

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

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _showLocalNotification(notification.body ?? 'Notification');
      }
    });
  }

  // Fetch notifications
  Stream<QuerySnapshot> _getNotifications() {
    return FirebaseFirestore.instance
        .collection('notifications')
        .doc(widget.projectId)
        .collection(widget.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Mark notification as read
  Future<void> _markAsRead(DocumentSnapshot notificationDoc) async {
    try {
      await notificationDoc.reference.update({'read': true});
      Fluttertoast.showToast(
        msg: "Notification marked as read",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      setState(() {});
    } catch (e) {
      print("Error marking notification as read: $e");
      Fluttertoast.showToast(
        msg: "Failed to mark notification as read",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      // Get all notifications for the user
      var querySnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .doc(widget.projectId)
          .collection(widget.uid)
          .get();

      if (querySnapshot.docs.isEmpty) {
        Fluttertoast.showToast(
          msg: "No notifications to mark as read",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.orange,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return;
      }

      // Initialize a Firestore batch
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Add each document update to the batch
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }

      // Commit the batch
      await batch.commit();

      // Show a toast message after marking all notifications as read
      Fluttertoast.showToast(
        msg: "All notifications marked as read",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: widget.colorTheme,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      // Trigger UI rebuild by refreshing the state
      setState(() {});
    } catch (e) {
      print("Error marking all notifications as read: $e");
      Fluttertoast.showToast(
        msg: "Failed to mark all as read",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate to HomeScreen when back button is pressed
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(
              uid: widget.uid,
              projectId: widget.projectId,
            ),
          ),
          (route) => false, // Clears the navigation stack
        );
        return false; // Prevent default back button behavior
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.transparent],
                ),
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: widget.colorTheme),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MainScreen(
                      uid: widget.uid,
                      projectId: widget.projectId,
                    ),
                  ),
                  (route) => false,
                );
              },
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: widget.colorTheme,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _markAllAsRead,
                icon: const Icon(Icons.mark_email_read),
                label: const Text('Mark All as Read'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: widget.colorTheme,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _getNotifications(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No notifications available.',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      );
                    }

                    // Display notifications as a list
                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var notification = snapshot.data!.docs[index];
                        String message = notification['message'] ?? '';
                        String title = notification['type'] ?? 'Notification';
                        title = title.isNotEmpty
                            ? title[0].toUpperCase() + title.substring(1)
                            : title;
                        bool isRead = notification['read'] ?? false;

                        // Format timestamp for display
                        Timestamp timestamp = notification['timestamp'];
                        String formattedDate =
                            DateFormat('MMMM d, yyyy hh:mm a')
                                .format(timestamp.toDate());

                        // Build notification tile
                        return _buildNotificationTile(
                          context,
                          notification: notification,
                          icon: isRead
                              ? Icons.notifications_none
                              : Icons.notifications_active,
                          title: title,
                          subtitle: message,
                          timestamp: formattedDate,
                          isRead: isRead,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Updated _buildNotificationTile to include a delete button
  Widget _buildNotificationTile(
    BuildContext context, {
    required DocumentSnapshot notification,
    required IconData icon,
    required String title,
    required String subtitle,
    required String timestamp,
    required bool isRead,
  }) {
    return GestureDetector(
      onTap: () async {
        if (!isRead) {
          await _markAsRead(notification);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isRead
              ? widget.colorTheme.withOpacity(0.1)
              : widget.colorTheme.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: widget.colorTheme.withOpacity(0.5), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 40, color: widget.colorTheme.withOpacity(0.5)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timestamp,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              tooltip: 'Delete Notification',
              onPressed: () => _deleteNotification(notification),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to delete a single notification
  Future<void> _deleteNotification(DocumentSnapshot notification) async {
    // Show a confirmation dialog before deleting
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Deletion"),
          content:
              const Text("Are you sure you want to delete this notification?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), // Cancel
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true), // Confirm
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      // Proceed to delete the notification
      try {
        await notification.reference.delete();
        Fluttertoast.showToast(
          msg: "Notification deleted",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } catch (e) {
        print("Error deleting notification: $e");
        Fluttertoast.showToast(
          msg: "Failed to delete notification",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    }
  }
}
