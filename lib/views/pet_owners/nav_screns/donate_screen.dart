import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:innopetcare/views/pet_owners/nav_screns/animal_shelter_appointments_screen.dart';
import 'package:innopetcare/views/pet_owners/nav_screns/widgets/custom_app_bar.dart';
import 'donate_sites.dart';

class DonateScreen extends StatefulWidget {
  final String uid;
  final String projectId;
  final Color colorTheme;

  const DonateScreen(
      {required this.uid, required this.projectId, required this.colorTheme});

  @override
  _DonateScreenState createState() => _DonateScreenState();
}

class _DonateScreenState extends State<DonateScreen> {
  List<Map<String, dynamic>> sections = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchDonationSections();
  }

  Future<void> fetchDonationSections() async {
    try {
      FirebaseFirestore db = FirebaseFirestore.instance;
      // Fetch the sections from Firestore
      final sectionsSnapshot =
          await db.collection('donations/${widget.projectId}/sections').get();

      setState(() {
        sections = sectionsSnapshot.docs
            .map((doc) => {"id": doc.id, ...doc.data()})
            .toList();
        loading = false;
      });
    } catch (e) {
      print("Error fetching donation sections: $e");
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(uid: widget.uid, projectId: widget.projectId),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        for (var section in sections) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  section['sectionTitle'] ?? 'Default Title',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: widget.colorTheme,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  section['sectionSubtext'] ??
                                      'Default Subtext',
                                  style: const TextStyle(
                                      fontSize: 18, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  section['sectionContent'] ??
                                      'Default Content',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 16),
                                if (section['sectionType'] == 'carousel' &&
                                    (section['sectionImages'] as List<dynamic>?)
                                            ?.isNotEmpty ==
                                        true)
                                  buildCarousel(section['sectionImages']),
                                if (section['sectionType'] == 'grid' &&
                                    (section['sectionImages'] as List<dynamic>?)
                                            ?.isNotEmpty ==
                                        true)
                                  buildGrid(section['sectionImages']),
                              ],
                            ),
                          ),
                        ],
                        DonateSites(
                            uid: widget.uid, projectId: widget.projectId),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                // Button placed at the bottom
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Add message above the button
                      Center(
                        child: Text(
                          "If you want to donate supplies, you may click the button below:",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(
                          height:
                              8), // Add spacing between the message and the button
                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.colorTheme,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AnimalShelterAppointmentsScreen(
                                  uid: widget.uid,
                                  projectId: widget.projectId,
                                  colorTheme: widget.colorTheme,
                                ),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.attach_money,
                                  color: Colors.white),
                              const SizedBox(width: 8),
                              const Text(
                                'Donate Now',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // Helper method to build a carousel
  Widget buildCarousel(List<dynamic> images) {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Image.network(
            images[index],
            fit: BoxFit.cover,
            width: double.infinity,
          );
        },
      ),
    );
  }

  // Helper method to build a grid
  Widget buildGrid(List<dynamic> images) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return Image.network(
          images[index],
          fit: BoxFit.cover,
        );
      },
    );
  }
}
