import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart';
import 'package:innopetcare/views/pet_owners/main_screen.dart';
import 'package:innopetcare/views/pet_owners/nav_screns/home_page_screen.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:permission_handler/permission_handler.dart';

class MessagesScreen extends StatefulWidget {
  final String uid;
  final String projectId;
  final Color colorTheme;

  MessagesScreen(
      {required this.uid, required this.projectId, required this.colorTheme});

  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String projectName = '';
  DateTime? lastActivityTime;
  Color headerColor = Colors.blue;
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  bool isUploading = false;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  late String chatDocId;
  String? projectImage;

  @override
  void initState() {
    super.initState();
    // Initialize headerColor using widget.colorTheme
    headerColor = widget.colorTheme;
    _fetchProjectDetails();
    chatDocId = '${widget.projectId}_${widget.uid}';
    print(chatDocId);
    print(projectName);
    print(projectImage);
    _initializeMessageListener();
  }

Future<void> _initializeMessageListener() async {
  FirebaseFirestore.instance
      .collection('chats')
      .doc('${widget.projectId}_${widget.uid}')
      .snapshots()
      .listen((snapshot) {
    if (snapshot.exists) {
      var chatData = snapshot.data();
      if (chatData != null) {
        String lastSenderId = chatData['lastSenderId'];
        String lastMessage = chatData['lastMessage'];
        
        // Check if the last sender ID matches the project ID
        if (lastSenderId == widget.projectId) {
          _showNotification(lastMessage);
        } else {
          print('Message not from the project.');
        }
      }
    }
  });
}

Future<void> _showNotification(String message) async {
  // Extract relevant data from the message

  // Replace 'yourUserId' with the current user's ID
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'messages_channel', // Channel ID
      'Messages', // Channel Name
      channelDescription: 'Notifications for new messages',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _localNotificationsPlugin.show(
      0, // Notification ID
      'New Message',
      message,
      notificationDetails,
    );

}

  Future<void> _initializeMessageListener2() async {
    FirebaseFirestore.instance
        .collection('chats')
        .doc(chatDocId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1) // Listen for the latest message
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        var message = snapshot.docs.first.data();
        _showNotification(message['text'] ?? 'New message');
      }
    });
  }

  // Function to fetch project details and user last activity time
  Future<void> _fetchProjectDetails() async {
    try {
      // Step 1: Retrieve the project document by its ID
      var projectDoc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .get();

      if (projectDoc.exists) {
        // Extract the userId from the project document
        String userId = projectDoc['userId'];

        // Step 2: Use the userId to fetch the user's lastActivityTime from the users collection
        var userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          setState(() {
            lastActivityTime =
                (userDoc['lastActivityTime'] as Timestamp).toDate();
          });
        }

        // Step 3: Fetch the additional project details from the global-sections collection
        var globalSectionsDoc = await FirebaseFirestore.instance
            .collection('global-sections')
            .doc(widget.projectId)
            .get();

        if (globalSectionsDoc.exists) {
          setState(() {
            projectName = globalSectionsDoc.data()?['name'] ?? '';
            projectImage = globalSectionsDoc.data()?['image'] ?? '';
          });
        }

        print(globalSectionsDoc);
      }
    } catch (e) {
      print('Error fetching project details: $e');
    }
  }

  // Helper function to convert hex color string to Color
  Color _hexToColor(String hexColor) {
    return Color(int.parse(hexColor.replaceFirst('#', '0xff')));
  }

  // Function to determine last active status
  Widget _buildLastActiveBadge() {
    if (lastActivityTime == null) return SizedBox.shrink();

    final now = DateTime.now();
    final difference = now.difference(lastActivityTime!);
    String statusText;
    Color badgeColor;

    if (difference.inMinutes <= 10) {
      statusText = 'Active Now';
      badgeColor = Colors.green;
    } else if (difference.inMinutes < 60) {
      statusText = 'Active for ${difference.inMinutes} mins';
      badgeColor = Colors.orange;
    } else if (difference.inHours < 24) {
      statusText = 'Active ${difference.inHours} hr ago';
      badgeColor = Colors.red;
    } else {
      final days = difference.inDays;
      statusText = 'Active $days day${days > 1 ? 's' : ''} ago';
      badgeColor = Colors.red;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  // Future<void> _sendMessage(
  //     {String? fileUrl, String? fileName, String fileType = 'text'}) async {
  //   if (messageController.text.trim().isEmpty && fileUrl == null) return;

  //   final messageData = {
  //     'text': fileType == 'text' ? messageController.text.trim() : null,
  //     if (fileType != 'text') 'fileUrl': fileUrl,
  //     if (fileType != 'text') 'fileName': fileName,
  //     'senderId': widget.uid,
  //     'receiverId': widget.projectId,
  //     'timestamp': FieldValue.serverTimestamp(),
  //     'isSeen': false,
  //     'type': fileType,
  //   };

  //   // Add the message to the messages collection
  //   await FirebaseFirestore.instance
  //       .collection('chats')
  //       .doc(chatDocId)
  //       .collection('messages')
  //       .add(messageData);

  //   // Update the lastMessage in the chat document
  //   await FirebaseFirestore.instance.collection('chats').doc(chatDocId).update({
  //     'lastMessage': messageController.text
  //         .trim(), // You can update it with text or file name
  //     'lastTimestamp': FieldValue.serverTimestamp(),
  //     'isSeenByAdmin': false,
  //     'isSeenByClient': true,
  //     'lastSenderId' : widget.uid,
  //     'clientId': widget.uid,
  //     'projectId': widget.projectId,

  //   });

  //   // Update the user's last activity time
  //   await FirebaseFirestore.instance
  //       .collection('clients')
  //       .doc(widget.uid)
  //       .update({'lastActivityTime': FieldValue.serverTimestamp()});

  //   setState(() => isUploading = false);
  //   messageController.clear();
  //   scrollController.jumpTo(scrollController.position.maxScrollExtent);
  // }

Future<void> _sendMessage({
  String? fileUrl,
  String? fileName,
  String fileType = 'text',
}) async {
  if (messageController.text.trim().isEmpty && fileUrl == null) return;

  final messageData = {
    'text': fileType == 'text' ? messageController.text.trim() : null,
    if (fileType != 'text') 'fileUrl': fileUrl,
    if (fileType != 'text') 'fileName': fileName,
    'senderId': widget.uid,
    'receiverId': widget.projectId,
    'timestamp': FieldValue.serverTimestamp(),
    'isSeen': false,
    'type': fileType,
  };

  try {
    // Add the message to the messages collection
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatDocId)
        .collection('messages')
        .add(messageData);

    // Update the lastMessage in the chat document
    await FirebaseFirestore.instance.collection('chats').doc(chatDocId).update({
      'lastMessage': fileType == 'text' ? messageController.text.trim() : fileName,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'isSeenByAdmin': false,
      'isSeenByClient': true,
      'lastSenderId': widget.uid,
      'clientId': widget.uid,
      'projectId': widget.projectId,
    });

    // Update the user's last activity time
    await FirebaseFirestore.instance
        .collection('clients')
        .doc(widget.uid)
        .update({'lastActivityTime': FieldValue.serverTimestamp()});
  } catch (error) {
    print('Error sending message: $error');
  } finally {
    // Ensure UI updates after message sent
    setState(() {
      isUploading = false;
    });
    messageController.clear();
    FocusScope.of(context).unfocus();
    Future.delayed(Duration(milliseconds: 100), () {
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
    });
  }
}

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() => isUploading = true);

    final file = File(pickedFile.path);
    final fileName = pickedFile.name;
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('messages/$chatDocId/images/$fileName');

    try {
      await storageRef.putFile(file);
      final fileUrl = await storageRef.getDownloadURL();
      await _sendMessage(
          fileUrl: fileUrl, fileName: fileName, fileType: 'image');
    } catch (e) {
      print("Error uploading image: $e");
      setState(() => isUploading = false);
    }
  }

  Future<void> _pickFile() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() => isUploading = true);

    final file = File(pickedFile.path);
    final fileName = pickedFile.name;
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('messages/$chatDocId/files/$fileName');

    try {
      await storageRef.putFile(file);
      final fileUrl = await storageRef.getDownloadURL();
      await _sendMessage(
          fileUrl: fileUrl, fileName: fileName, fileType: 'file');
    } catch (e) {
      print("Error uploading file: $e");
      setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: headerColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Navigate to HomePageScreen when back button is pressed
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    MainScreen(uid: widget.uid, projectId: widget.projectId),
              ),
            );
          },
        ),
        title: Row(
          children: [
            // Project Image
            if (projectImage != null) // Display if projectImage is available
              Padding(
                padding: const EdgeInsets.only(
                    right: 8.0), // Spacing between image and text
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                      8.0), // Adjust for a rounded rectangle
                  child: Image.network(
                    projectImage!,
                    width: 40, // Set width
                    height: 40, // Set height
                    fit: BoxFit.contain, // Adjust to cover the space
                  ),
                ),
              ),

            // Title and Badge Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  projectName.isNotEmpty ? projectName : 'Admin',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4), // Spacing between title and badge
                _buildLastActiveBadge(),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: 
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatDocId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  print('Error loading messages: ${snapshot.error}');
                  return Center(child: Text('Error loading messages'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No messages available'));
                }

                var messages = snapshot.data!.docs;
                Map<String, List<QueryDocumentSnapshot>> groupedMessages = {};
                for (var message in messages) {
                  DateTime messageDate = message['timestamp'] != null
                      ? (message['timestamp'] as Timestamp).toDate()
                      : DateTime.now();
                  String formattedDate =
                      DateFormat('MMMM d, yyyy').format(messageDate);

                  if (!groupedMessages.containsKey(formattedDate)) {
                    groupedMessages[formattedDate] = [];
                  }
                  groupedMessages[formattedDate]!.add(message);
                }

                return ListView.builder(
                  controller: scrollController,
                  itemCount: groupedMessages.keys.length,
                  itemBuilder: (context, index) {
                    String date = groupedMessages.keys.elementAt(index);
                    var dayMessages = groupedMessages[date]!;

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            date,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        ...dayMessages.map((message) {
                          bool isSender = message['senderId'] == widget.uid;
                          var messageData =
                              message.data() as Map<String, dynamic>?;
                          String? text = messageData?['text'];
                          Timestamp? timestamp =
                              message['timestamp'] as Timestamp?;
                          String? fileUrl = messageData?['fileUrl'];
                          String? fileName = messageData?['fileName'];

                          return _buildMessageBubble(
                              text, timestamp, isSender, fileUrl, fileName);
                        }).toList(),
                      ],
                    );
                  },
                );
              },
            ),


          ),
          _buildMessageInput(),
          if (isUploading) CircularProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String? text, Timestamp? timestamp, bool isSender,
      String? fileUrl, String? fileName) {
    DateTime messageTime = timestamp?.toDate() ?? DateTime.now();
    String formattedTime = DateFormat('hh:mm a').format(messageTime);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Align(
        alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: isSender ? headerColor : Colors.grey[300],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (text != null && text.isNotEmpty)
                Text(
                  text,
                  style: TextStyle(
                    color: isSender ? Colors.white : Colors.black,
                    fontSize: 16,
                  ),
                ),
              if (fileUrl != null)
                GestureDetector(
                  onLongPress: () => _showDownloadOptions(fileUrl, fileName),
                  child: fileName != null &&
                          (fileName.endsWith('.jpg') ||
                              fileName.endsWith('.png') ||
                              fileName.endsWith('.webp'))
                      ? Image.network(
                          fileUrl,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        )
                      : Row(
                          children: [
                            Icon(Icons.attach_file,
                                color: isSender ? Colors.white : Colors.black),
                            SizedBox(width: 8),
                            Text(
                              fileName ?? 'Attachment',
                              style: TextStyle(
                                color: isSender ? Colors.white : Colors.black,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                ),
              SizedBox(height: 5),
              Text(
                formattedTime,
                style: TextStyle(
                  color: isSender ? Colors.white70 : Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDownloadOptions(String fileUrl, String? fileName) {
    // showModalBottomSheet(
    //   context: context,
    //   builder: (BuildContext context) {
    //     return SafeArea(
    //       child: Wrap(
    //         children: [
    //           ListTile(
    //             leading: Icon(Icons.download),
    //             title: Text('Download Image'),
    //             onTap: () {
    //               Navigator.pop(context); // Close the bottom sheet
    //               _downloadFile(fileUrl, fileName);
    //             },
    //           ),
    //         ],
    //       ),
    //     );
    //   },
    // );
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid &&
        (await DeviceInfoPlugin().androidInfo).version.sdkInt >= 33) {
      final photosPermission = await Permission.photos.request();
      final videosPermission = await Permission.videos.request();
      if (photosPermission.isGranted && videosPermission.isGranted) {
        return true;
      }
    } else {
      final storagePermission = await Permission.storage.request();
      if (storagePermission.isGranted) {
        return true;
      }
    }
    return false;
  }

  Future<String?> _getDownloadsDirectoryPath() async {
    if (Platform.isAndroid) {
      return "/storage/emulated/0/Download";
    }
    if (Platform.isIOS) {
      return (await getApplicationDocumentsDirectory()).path;
    }
    return null;
  }

  String _generateUniqueFileName(String originalName) {
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return "$timestamp-${originalName.replaceAll(RegExp(r'[^\w.]'), '_')}";
  }

  Future<void> _downloadFile(String url, String? fileName) async {
    // Check and request storage permission
    if (await Permission.storage.request().isGranted) {
      try {
        // Get the downloads directory
        Directory? downloadsDir = await getExternalStorageDirectory();
        if (downloadsDir == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unable to access downloads directory')),
          );
          return;
        }

        // Define the path to the Downloads folder
        String downloadsPath = "${downloadsDir.path}/Download";

        // Ensure the directory exists
        Directory(downloadsPath).createSync(recursive: true);

        // Generate a safe file name
        String safeFileName = fileName ??
            'downloaded_file_${DateTime.now().millisecondsSinceEpoch}.jpg';
        String savePath = "$downloadsPath/$safeFileName";

        // Use Dio to download the file
        Dio dio = Dio();
        await dio.download(url, savePath);

        // Notify the user of the download success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File downloaded to $savePath')),
        );
      } catch (e) {
        // Notify the user of an error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading file: $e')),
        );
      }
    } else {
      // Notify the user that permission was denied
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Storage permission denied')),
      );
    }
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.attach_file),
            onPressed: _pickFile,
          ),
          IconButton(
            icon: Icon(Icons.image),
            onPressed: _pickImage,
          ),
          Expanded(
            child: TextField(
              controller: messageController,
              textInputAction: TextInputAction.newline,
              minLines: 1,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            color: headerColor ?? Colors.blue,
            onPressed: () => _sendMessage(),
          ),
        ],
      ),
    );
  }

  void _openFile(String url) async {
    // Check and request storage permission
    if (await Permission.storage.request().isGranted) {
      try {
        // Get the downloads directory
        Directory? downloadsDir = await getExternalStorageDirectory();
        if (downloadsDir == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unable to access downloads directory')),
          );
          return;
        }

        String downloadsPath = "${downloadsDir.path}/Download";
        // Ensure the directory exists
        Directory(downloadsPath).createSync(recursive: true);

        // Extract the file name from the URL
        String fileName = url.split('/').last;
        String savePath = "$downloadsPath/$fileName";

        // Download the file
        Dio dio = Dio();
        await dio.download(url, savePath);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File downloaded to $savePath')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading file: $e')),
        );
      }
    } else {
      // Show message if permission is denied
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Storage permission denied')),
      );
    }
  }
}
