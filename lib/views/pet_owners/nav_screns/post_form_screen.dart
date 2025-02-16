import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class PostFormScreen extends StatefulWidget {
  final String uid;
  final String projectId;
  final Color colorTheme;
  final Map<String, dynamic>? post;

  const PostFormScreen({
    required this.uid,
    required this.projectId,
    required this.colorTheme,
    this.post,
    Key? key,
  }) : super(key: key);

  @override
  _PostFormScreenState createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  late quill.QuillController _quillController;
  List<XFile> _selectedImages = [];
  bool _isLoading = false;

  String? authorName;
  String? profileImage;

  @override
  void initState() {
    super.initState();

    // Initialize title and content
    _titleController.text = widget.post?['title'] ?? '';
    _quillController = quill.QuillController(
      document: widget.post != null && widget.post!['content'] != null
          ? quill.Document.fromDelta(
              Delta()..insert(widget.post!['content'] + "\n"))
          : quill.Document(),
      selection: const TextSelection.collapsed(offset: 0),
    );

    _selectedImages = [];
    _fetchAuthorDetails();
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _fetchAuthorDetails() async {
    try {
      final clientRef =
          FirebaseFirestore.instance.collection('clients').doc(widget.uid);
      final clientSnap = await clientRef.get();

      if (clientSnap.exists) {
        setState(() {
          authorName = clientSnap['name'] ?? 'Anonymous';
          profileImage = clientSnap['profileImage'];
        });
      } else {
        setState(() {
          authorName = 'Anonymous';
          profileImage = null;
        });
      }
    } catch (e) {
      print('Error fetching author details: $e');
      setState(() {
        authorName = 'Anonymous';
        profileImage = null;
      });
    }
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();

    if (images != null) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  Future<List<String>> _uploadImages() async {
    final storage = FirebaseStorage.instance;
    final List<String> imageUrls = [];

    for (final image in _selectedImages) {
      final File file = File(image.path);
      final String fileName = image.name;
      final ref = storage.ref().child(
          'community-forum/${widget.projectId}/posts/${widget.post?['id'] ?? 'newPost'}/$fileName');
      await ref.putFile(file);
      final String downloadUrl = await ref.getDownloadURL();
      imageUrls.add(downloadUrl);
    }

    return imageUrls;
  }

  String quillToMarkdown(List<dynamic> delta) {
    final buffer = StringBuffer();

    for (final operation in delta) {
      if (operation['insert'] != null) {
        final text = operation['insert'];
        if (operation['attributes'] != null) {
          final attributes = operation['attributes'];
          if (attributes.containsKey('bold')) {
            buffer.write('**$text**');
          } else if (attributes.containsKey('italic')) {
            buffer.write('*$text*');
          } else {
            buffer.write(text);
          }
        } else {
          buffer.write(text);
        }
      }
    }

    return buffer.toString();
  }

  Future<void> _savePost() async {
    if (!_formKey.currentState!.validate()) return;

    if (authorName == null || profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Unable to fetch author details.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final contentDelta = _quillController.document.toDelta().toJson();
      final contentMarkdown = quillToMarkdown(contentDelta);

      final imageUrls = await _uploadImages();

      final postRef = widget.post != null
          ? FirebaseFirestore.instance
              .collection('community-forum/${widget.projectId}/posts')
              .doc(widget.post!['id'])
          : FirebaseFirestore.instance
              .collection('community-forum/${widget.projectId}/posts')
              .doc();

      final postData = {
        'title': _titleController.text.trim(),
        'content': contentMarkdown,
        'images':
            imageUrls.isNotEmpty ? imageUrls : widget.post?['images'] ?? [],
        'authorId': widget.uid,
        'authorName': authorName,
        'profileImage': profileImage,
        'updatedAt': FieldValue.serverTimestamp(),
        'isDeleted': false,
        'isEdited': widget.post != null,
      };
      if (widget.post == null) {
        postData['createdAt'] = FieldValue.serverTimestamp();
        postData['likesCount'] = 0;
        postData['commentsCount'] = 0;
        postData['sharedCount'] = 0;
      }

      await postRef.set(postData);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.post != null
            ? 'Post updated successfully!'
            : 'Post created successfully!'),
      ));
      Navigator.pop(context);
    } catch (e) {
      print('Error saving post: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to save post. Please try again.'),
      ));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparent background
        elevation: 0, // Remove shadow
        title: Text(
          widget.post == null ? 'Create Post' : 'Edit Post',
          style: TextStyle(
            color: widget.colorTheme, // Set text color to widget.colorTheme
          ),
        ),
        iconTheme: IconThemeData(
          color: widget.colorTheme, // Set icon color to widget.colorTheme
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Text('Content', style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                    Container(
  decoration: BoxDecoration(
    border: Border.all(color: Colors.grey),
    borderRadius: BorderRadius.circular(4),
  ),
  child: Padding(
    padding: const EdgeInsets.all(8.0), // Add inner padding
    child: ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: 200, // Minimum height of the container
      ),
      child: quill.QuillEditor.basic(
        controller: _quillController,
        // readOnly: false,
      ),
    ),
  ),
),
  const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _pickImages,
                        icon: Icon(Icons.image),
                        label: Text('Add Images'),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _selectedImages
                            .asMap()
                            .entries
                            .map((entry) => Stack(
                                  children: [
                                    Image.file(
                                      File(entry.value.path),
                                      height: 100,
                                      width: 100,
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: IconButton(
                                        onPressed: () =>
                                            _removeImage(entry.key),
                                        icon: Icon(Icons.cancel,
                                            color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: _savePost,
                            child: Text(widget.post == null ? 'Post' : 'Save'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
