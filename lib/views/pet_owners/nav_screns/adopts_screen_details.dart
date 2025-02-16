import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'messages_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class AdoptsScreenDetails extends StatefulWidget {
  final String uid;
  final String projectId;
  final String petId;
  final Color colorTheme;

  const AdoptsScreenDetails({
    Key? key,
    required this.uid,
    required this.projectId,
    required this.petId,
    required this.colorTheme,
  }) : super(key: key);

  @override
  _AdoptsScreenDetailsState createState() => _AdoptsScreenDetailsState();
}

class _AdoptsScreenDetailsState extends State<AdoptsScreenDetails> {
  Map<String, dynamic>? petData;
  List<Map<String, dynamic>> sections = [];
  List<Map<String, dynamic>> records = [];
  List<Map<String, dynamic>> selectedSectionColumns = [];
  String? selectedSectionId;
  bool isLoading = true;
  bool isRecordsLoading = false;

  late Future<Map<String, dynamic>?> petDetails;
  late Future<void> sectionsFuture;

  @override
  void initState() {
    super.initState();
    petDetails = _fetchPetDetails();
    sectionsFuture = _fetchSections();
  }

  // Fetch pet details from Firestore
  Future<Map<String, dynamic>?> _fetchPetDetails() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('adoptions')
          .doc(widget.projectId)
          .collection("animals")
          .doc(widget.petId)
          .get();

      if (snapshot.exists) {
        return snapshot.data();
      }
    } catch (e) {
      print('Error fetching pet details: $e');
    }
    return null;
  }

  // Fetch sections from Firestore
  Future<void> _fetchSections() async {
    try {
      final sectionsSnapshot = await FirebaseFirestore.instance
          .collection('adoption-record-sections')
          .doc(widget.projectId)
          .collection('sections')
          .get();

      final fetchedSections = sectionsSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc.data()['name'],
        };
      }).toList();

      setState(() {
        sections = fetchedSections;
      });
    } catch (e) {
      print('Error fetching sections: $e');
    }
  }

  // Fetch records for the selected section
  Future<void> _fetchRecords(String sectionId) async {
    setState(() {
      isRecordsLoading = true;
      records = [];
    });

    try {
      final columnsSnapshot = await FirebaseFirestore.instance
          .collection('adoption-record-sections')
          .doc(widget.projectId)
          .collection('sections')
          .doc(sectionId)
          .collection('columns')
          .get();

      final columns = columnsSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc.data()['name'],
        };
      }).toList();

      final recordsSnapshot = await FirebaseFirestore.instance
          .collection('adoption-records')
          .doc(widget.projectId)
          .collection(widget.petId)
          .doc(sectionId)
          .collection('records')
          .get();

      final fetchedRecords = recordsSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      setState(() {
        selectedSectionColumns = columns;
        records = fetchedRecords;
      });
    } catch (e) {
      print('Error fetching records: $e');
    } finally {
      setState(() {
        isRecordsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pet Details"),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: petDetails,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Pet details not available'));
          }

          final pet = snapshot.data!;
          final petGenderIcon = pet['gender'] == 'male' ? '♂' : '♀';
          final petGenderColor =
              pet['gender'] == 'male' ? Colors.blue : Colors.pink;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Pet Image
                CircleAvatar(
                  backgroundImage:
                      pet['image'] != null ? NetworkImage(pet['image']) : null,
                  radius: 60,
                ),
                const SizedBox(height: 16),

                // Pet Name
                Text(
                  pet['petName'] ?? 'Pet Name',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Pet Details
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          text: 'Gender: ',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: petGenderColor,
                          ),
                          children: [
                            TextSpan(
                              text: petGenderIcon,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow('Birthdate', pet['birthdate']),
                      const SizedBox(height: 8),
                      _buildDetailRow('Color', pet['color']),
                      const SizedBox(height: 8),
                      _buildDetailRow('Breed', pet['breed']),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'Weight',
                        '${pet['weight'] ?? 'Unknown'} kg',
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow('Description', pet['description']),
                      const SizedBox(height: 16),
                      // Notes
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          pet['notes'] ?? 'No additional notes',
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Add the Row for the buttons here
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal:
                                    8.0), // Add padding around the button
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Navigate to MessagesScreen for Adoption Inquiry
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MessagesScreen(
                                      projectId: widget.projectId,
                                      uid: widget.uid,
                                      colorTheme: widget.colorTheme,
                                    ),
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.message,
                                color: widget.colorTheme,
                              ),
                              label: Text(
                                'Adoption Inquiry',
                                style: TextStyle(color: widget.colorTheme),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.white, // Button background color
                                side: BorderSide(
                                    color: widget.colorTheme,
                                    width: 1.5), // Add border
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical:
                                        8), // Internal padding for button content // Internal padding for button content
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal:
                                    8.0), // Add padding around the button
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  // Fetch the URL from Firestore
                                  DocumentSnapshot<Map<String, dynamic>> doc =
                                      await FirebaseFirestore.instance
                                          .collection('adopt-sections')
                                          .doc(widget.projectId)
                                          .get();

                                  String? adoptFileUrl =
                                      doc.data()?['adoptFile'];

                                  if (adoptFileUrl != null &&
                                      adoptFileUrl.isNotEmpty) {
                                    // Launch the URL
                                    await launchUrl(Uri.parse(adoptFileUrl));
                                  } else {
                                    // Show error if URL is not found
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Adoption form not available.'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  // Handle any errors
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Failed to load adoption form. Please try again.'),
                                    ),
                                  );
                                }
                              },
                              icon: Icon(
                                Icons.download,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Download Form',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget
                                    .colorTheme, // Button background color
                                side: BorderSide(
                                    color: widget.colorTheme,
                                    width: 1.5), // Add border
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical:
                                        8), // Internal padding for button content
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Buttons

                // Dropdown and Records
                FutureBuilder<void>(
                  future: sectionsFuture,
                  builder: (context, sectionSnapshot) {
                    if (sectionSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Record Type',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: widget.colorTheme,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButton<String>(
                          isExpanded: true,
                          value: selectedSectionId,
                          hint: const Text('Select Section'),
                          items: sections.map((section) {
                            return DropdownMenuItem<String>(
                              value: section['id'],
                              child: Text(section['name']),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedSectionId = value;
                            });
                            if (value != null) {
                              _fetchRecords(value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        isRecordsLoading
                            ? const Center(child: CircularProgressIndicator())
                            : records.isEmpty
                                ? const Text(
                                    'No records available for the selected section.')
                                : _buildRecordsList(),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String title, String? value) {
    return RichText(
      text: TextSpan(
        text: '$title: ',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        children: [
          TextSpan(
            text: value ?? 'Unknown',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: selectedSectionColumns.map((column) {
                final value = record['records']?[column['id']] ?? 'N/A';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        column['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
