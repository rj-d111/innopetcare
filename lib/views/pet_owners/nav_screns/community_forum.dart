import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:innopetcare/views/pet_owners/nav_screns/comment_modal.dart';
import 'package:innopetcare/views/pet_owners/nav_screns/home_page_screen.dart';
import 'package:innopetcare/views/pet_owners/nav_screns/post_form_screen.dart';
import 'package:intl/intl.dart'; // Import intl package
import 'package:share_plus/share_plus.dart';

class CommunityForumScreen extends StatefulWidget {
  final String uid;
  final String projectId;
  final Color colorTheme;

  const CommunityForumScreen({
    required this.uid,
    required this.projectId,
    required this.colorTheme,
    Key? key,
  }) : super(key: key);

  @override
  State<CommunityForumScreen> createState() => _CommunityForumScreenState();
}

class _CommunityForumScreenState extends State<CommunityForumScreen> {
  List<Map<String, dynamic>> posts = [];
  bool isLoading = true;
  String? activePostId; // Store the ID of the active post for the comment modal

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  void fetchPosts() {
    FirebaseFirestore.instance
        .collection('community-forum/${widget.projectId}/posts')
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .listen((querySnapshot) async {
      final List<Map<String, dynamic>> updatedPosts = [];
      for (var doc in querySnapshot.docs) {
        final postData = doc.data();
        final authorId = postData['authorId'];

        try {
          // Fetch client details based on authorId
          final clientSnap = await FirebaseFirestore.instance
              .collection('clients')
              .doc(authorId)
              .get();

          final authorName =
              clientSnap.exists ? clientSnap['name'] : 'Anonymous';
          final profileImage =
              clientSnap.exists ? clientSnap['profileImage'] : null;

          updatedPosts.add({
            'id': doc.id,
            ...postData,
            'authorName': authorName,
            'profileImage': profileImage,
          });
        } catch (e) {
          print("Error fetching author details for post $authorId: $e");
          updatedPosts.add({
            'id': doc.id,
            ...postData,
            'authorName': 'Anonymous',
            'profileImage': null,
          });
        }
      }

      setState(() {
        posts = updatedPosts;
        isLoading = false;
      });
    });
  }

  void handleLike(String postId, bool isLiked) async {
    try {
      final postRef = FirebaseFirestore.instance
          .collection('community-forum/${widget.projectId}/posts')
          .doc(postId);

      if (isLiked) {
        await postRef.update({
          'likes': FieldValue.arrayRemove([widget.uid]),
        });
      } else {
        await postRef.update({
          'likes': FieldValue.arrayUnion([widget.uid]),
        });
      }
    } catch (error) {
      print("Error liking post: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update like status.")),
      );
    }
  }

  Future<void> handleShare(String postId) async {
    try {
      // Fetch the document for the given projectId from global-sections
      final slugSnapshot = await FirebaseFirestore.instance
          .collection('global-sections')
          .doc(widget.projectId)
          .get();

      if (!slugSnapshot.exists) {
        throw Exception(
            "Document not found for projectId: ${widget.projectId}");
      }

      // Extract the slug from the document data
      final slug = slugSnapshot.data()?['slug'] ?? "unknown";

      // Construct the URL using the postId
      // Construct the URL
      final postUrl =
          "https://innopetcare.com/sites/$slug/community-forum/${widget.projectId}/post/$postId";
      final shareContent = "Check out this post on Innopetcare:\n$postUrl";

      // Use share_plus to share
      await Share.share(
        shareContent,
        subject: "Innopetcare Community Forum Post",
      );
      // Copy the URL to the clipboard
      // await Clipboard.setData(ClipboardData(text: url));

      // Show success Snackbar
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text("Link copied to clipboard!"),
      //     backgroundColor: Colors.green,
      //   ),
      // );
    } catch (error) {
      // Handle errors gracefully
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to copy link: $error"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void handleDelete(String postId) async {
    bool confirmDelete = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Delete Post"),
            content: Text(
                "Are you sure you want to delete this post? This action cannot be undone."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("Delete"),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmDelete) {
      try {
        await FirebaseFirestore.instance
            .collection('community-forum/${widget.projectId}/posts')
            .doc(postId)
            .update({'isDeleted': true});
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Post deleted successfully.")));
      } catch (error) {
        print("Error deleting post: $error");
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to delete the post.")));
      }
    }
  }

  void navigateToPostForm({Map<String, dynamic>? post}) {
    print(post);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostFormScreen(
          uid: widget.uid,
          projectId: widget.projectId,
          colorTheme: widget.colorTheme,
          post: post,
        ),
      ),
    );
  }

  void openCommentModal(String postId) {
    setState(() {
      activePostId = postId; // Set the active post for the comment modal
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // For full-screen modal
      builder: (context) => CommentModal(
        postId: postId,
        projectId: widget.projectId,
        uid: widget.uid,
      ),
    ).then((_) {
      setState(() {
        activePostId = null; // Clear the active post when modal is closed
      });
    });
  }

  Future<bool> _onWillPop() async {
    // Navigate to HomePageScreen when back button is pressed
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomePageScreen(
          uid: widget.uid,
          projectId: widget.projectId,
        ),
      ),
    );
    return false; // Prevent default back button behavior
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // Override system back button behavior
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: widget.colorTheme,
          automaticallyImplyLeading: false, // Hides the default back button
          title: Text(
            "Community Forum",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => navigateToPostForm(), // Action for "Add Post"
              icon: Icon(
                Icons.add,
                color: Colors.white, // White icon
              ),
              label: Text(
                "Add Post",
                style: TextStyle(
                  color: Colors.white, // White text
                ),
              ),
            ),
          ],
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return Card(
                    margin: EdgeInsets.all(8.0),
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                post['profileImage'] ??
                                    'https://via.placeholder.com/40',
                              ),
                            ),
                            title: Text(post['authorName'] ?? 'Anonymous'),
                            subtitle: Text(
                              post['updatedAt'] != null
                                  ? DateFormat('MMM d, yyyy h:mm a').format(
                                      (post['updatedAt'] as Timestamp)
                                          .toDate()
                                          .toLocal(), // Format date
                                    )
                                  : 'Date not available',
                            ),
                            trailing: post['authorId'] == widget.uid
                                ? PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        navigateToPostForm(post: post);
                                      } else if (value == 'delete') {
                                        handleDelete(post['id']);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Edit'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                          Text(
                            post['title'] ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(post['content'] ?? ''),
                          if (post['images'] != null &&
                              (post['images'] as List).isNotEmpty)
                            SizedBox(
                              height: 200,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: (post['images'] as List).length,
                                itemBuilder: (context, imageIndex) {
                                  return Padding(
                                    padding: EdgeInsets.only(right: 8.0),
                                    child: Image.network(
                                      post['images'][imageIndex],
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                },
                              ),
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                onPressed: () async {
                                  final isLiked = (post['likes'] ?? [])
                                      .contains(widget.uid);

                                  try {
                                    // Reference to the post document
                                    final postRef = FirebaseFirestore.instance
                                        .collection(
                                            'community-forum/${widget.projectId}/posts')
                                        .doc(post['id']);

                                    if (isLiked) {
                                      // User already liked: Remove like and decrement likesCount
                                      await postRef.update({
                                        'likes': FieldValue.arrayRemove(
                                            [widget.uid]),
                                        'likesCount': FieldValue.increment(-1),
                                      });

                                      // Update local UI state if needed
                                      setState(() {
                                        post['likes'] =
                                            List.from(post['likes'] ?? [])
                                              ..remove(widget.uid);
                                        post['likesCount'] =
                                            (post['likesCount'] ?? 0) - 1;
                                      });
                                    } else {
                                      // User has not liked yet: Add like and increment likesCount
                                      await postRef.update({
                                        'likes':
                                            FieldValue.arrayUnion([widget.uid]),
                                        'likesCount': FieldValue.increment(1),
                                      });

                                      // Update local UI state if needed
                                      setState(() {
                                        post['likes'] =
                                            List.from(post['likes'] ?? [])
                                              ..add(widget.uid);
                                        post['likesCount'] =
                                            (post['likesCount'] ?? 0) + 1;
                                      });
                                    }
                                  } catch (error) {
                                    print("Error updating like status: $error");
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              "Failed to update like status.")),
                                    );
                                  }
                                },
                                icon: Icon(
                                  Icons.thumb_up,
                                  color:
                                      (post['likes'] ?? []).contains(widget.uid)
                                          ? Colors.blue
                                          : Colors.grey,
                                ),
                                label: Text(
                                  post['likesCount'] == null ||
                                          post['likesCount'] == 0
                                      ? "Like"
                                      : post['likesCount'] == 1
                                          ? "1 like"
                                          : "${post['likesCount']} likes",
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () =>
                                    openCommentModal(post['id']), // Open modal
                                icon: Icon(Icons.comment),
                                label: Text("Comment"),
                              ),
                              TextButton.icon(
                                onPressed: () => handleShare(post['id']),
                                icon: Icon(Icons.share),
                                label: Text("Share"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
