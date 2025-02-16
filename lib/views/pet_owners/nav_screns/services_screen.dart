import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ServicesScreen extends StatefulWidget {
  final String projectId;
  final String uid;
  final Color colorTheme;

  const ServicesScreen(
      {Key? key,
      required this.uid,
      required this.projectId,
      required this.colorTheme})
      : super(key: key);

  @override
  _ServicesScreenState createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  bool isGridView = false; // Toggle between grid and list view

  // Fetch services from Firestore
  Future<List<Map<String, dynamic>>> _fetchServices() async {
    try {
      var servicesSnapshot = await FirebaseFirestore.instance
          .collection('services')
          .where('projectId', isEqualTo: widget.projectId)
          .get();

      return servicesSnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      print('Error fetching services: $e');
      return [];
    }
  }

  // Fetch image from Firebase Storage
  Future<String?> fetchFirebaseImage(String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      print("Error fetching image from Firebase: $e");
      return null;
    }
  }

  // Widget to build service card
  Widget _buildServiceCard(Map<String, dynamic> service,
      {bool isGridView = false}) {
    final String? iconUrl = service['icon'];
    final bool isSvg = iconUrl != null && iconUrl.endsWith('.svg');

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: isGridView
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (iconUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: isSvg
                          ? SvgPicture.network(
                              iconUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              placeholderBuilder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : Image.network(
                              iconUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.broken_image,
                                  size: 60,
                                  color: Colors.red,
                                );
                              },
                            ),
                    ),
                  const SizedBox(height: 12),
                  SelectableText(
                    service['title'] ?? 'Service Title',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: Text(
                      service['description'] ??
                          'Service description goes here.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Center the image vertically
                children: [
                  if (iconUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: isSvg
                          ? SvgPicture.network(
                              iconUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              placeholderBuilder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : Image.network(
                              iconUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.red,
                                );
                              },
                            ),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service['title'] ?? 'Service Title',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          service['description'] ??
                              'Service description goes here.',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchServices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No services available'));
          }

          final services = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 48.0),
                      child: SelectableText(
                        'Services',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: widget.colorTheme,
                        ),
                      ),
                    ),
                    // IconButton(
                    //   icon: Icon(
                    //     isGridView ? Icons.view_list : Icons.grid_view,
                    //   ),
                    //   onPressed: () {
                    //     setState(() {
                    //       isGridView = !isGridView;
                    //     });
                    //   },
                    // ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: isGridView
                      ? GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 300,
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 16,
                          ),
                          itemCount: services.length,
                          itemBuilder: (context, index) {
                            return _buildServiceCard(services[index],
                                isGridView: true);
                          },
                        )
                      : ListView.builder(
                          itemCount: services.length,
                          itemBuilder: (context, index) {
                            return _buildServiceCard(services[index],
                                isGridView: false);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
