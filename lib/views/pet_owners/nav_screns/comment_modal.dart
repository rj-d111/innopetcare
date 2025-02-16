import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:innopetcare/main.dart';
import 'package:intl/intl.dart'; // Import intl package
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class CommentModal extends StatefulWidget {
  final String postId;
  final String projectId;
  final String uid;

  const CommentModal({
    required this.postId,
    required this.projectId,
    required this.uid,
    Key? key,
  }) : super(key: key);

  @override
  State<CommentModal> createState() => _CommentModalState();
}

class _CommentModalState extends State<CommentModal> {
  List<Map<String, dynamic>> comments = [];
  bool isLoading = true;
  final TextEditingController commentController = TextEditingController();
  String? authorId; // Declare authorId as a nullable variable

  @override
  void initState() {
    super.initState();
    fetchComments();
    fetchAuthorId(); // Fetch authorId when the widget initializes
  }

  Future<void> fetchAuthorId() async {
    String? fetchedAuthorId =
        await getAuthorId(widget.projectId, widget.postId);
    setState(() {
      authorId = fetchedAuthorId;
    });
  }
  Future<String?> getAuthorId(String projectId, String postId) async {
    try {
      // Reference to the specific document in Firestore
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('community-forum')
          .doc(projectId)
          .collection('posts')
          .doc(postId)
          .get();

      // Check if the document exists
      if (documentSnapshot.exists) {
        // Fetch the authorId field from the document
        String? authorId = documentSnapshot['authorId'];
        print('Author ID: $authorId');
        return authorId;
      } else {
        print('Document does not exist.');
        return null;
      }
    } catch (e) {
      print('Error fetching authorId: $e');
      return null;
    }
  }

  void fetchComments() {
    final currentUserId =
        FirebaseAuth.instance.currentUser?.uid; // Get current user's ID

    FirebaseFirestore.instance
        .collection(
            'community-forum/${widget.projectId}/posts/${widget.postId}/comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen((querySnapshot) async {
      final List<Map<String, dynamic>> updatedComments = [];
      for (var doc in querySnapshot.docs) {
        final commentData = doc.data();
        final userId = commentData['userId'];

        try {
          // Fetch user details from the clients collection
          final userSnap = await FirebaseFirestore.instance
              .collection('clients')
              .doc(userId)
              .get();

          final userName = userSnap.exists ? userSnap['name'] : 'Anonymous';
          final profileImage =
              userSnap.exists ? userSnap['profileImage'] : null;

          updatedComments.add({
            'id': doc.id,
            ...commentData,
            'userName': userName,
            'profileImage': profileImage,
          });
          print("Logged in user");
          print(FirebaseAuth.instance.currentUser?.uid);
          print("User id is " + userId);
          print("uid is " + widget.uid);
          print(widget.uid == authorId);
          // Notify the current user if the comment is from another user
          if (authorId == widget.uid) {
            if (userId != currentUserId) {
              showNotification(
                'New Comment on Your Post',
                '$userName commented: "${commentData['comment']}"',
              );
            }
          }
        } catch (e) {
          print("Error fetching user details for comment: $e");
          updatedComments.add({
            'id': doc.id,
            ...commentData,
            'userName': 'Anonymous',
            'profileImage': null,
          });
        }
      }

      setState(() {
        comments = updatedComments;
        isLoading = false;
      });
    });
  }

  void addComment() async {
    if (commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Comment cannot be empty.")),
      );
      return;
    }

    try {
      final commentRef = FirebaseFirestore.instance
          .collection(
              'community-forum/${widget.projectId}/posts/${widget.postId}/comments')
          .doc();

      await commentRef.set({
        'comment': commentController.text.trim(),
        'userId': widget.uid,
        'createdAt': Timestamp.now(),
      });

      commentController.clear(); // Clear input field
    } catch (error) {
      print("Error adding comment: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add comment.")),
      );
    }
  }

@override
Widget build(BuildContext context) {
  return GestureDetector(
    onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard when tapping outside
    child: Container(
      height: MediaQuery.of(context).size.height, // Full screen height
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16), // Rounded corners
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          Container(
            width: 50,
            height: 5,
            margin: EdgeInsets.only(top: 8, bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          // Comments Title
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Comments",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(),
          // Comments List
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 16.0,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Image
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: comment['profileImage'] != null
                                  ? NetworkImage(comment['profileImage'])
                                  : AssetImage('assets/default_avatar.png')
                                      as ImageProvider,
                              backgroundColor: Colors.grey[200],
                            ),
                            SizedBox(width: 12),
                            // Comment Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        comment['userName'] ?? 'Anonymous',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        comment['createdAt'] != null
                                            ? DateFormat('MMM d, yyyy h:mm a')
                                                .format(
                                                (comment['createdAt']
                                                        as Timestamp)
                                                    .toDate()
                                                    .toLocal(),
                                              )
                                            : 'Date not available',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    comment['comment'] ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          // Add Comment Input
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      decoration: InputDecoration(
                        hintText: "Write a comment...",
                        filled: true,
                        fillColor: Colors.grey[200], // Light gray background
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none, // No border outline
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.0),
                  IconButton(
                    icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
                    onPressed: addComment,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
