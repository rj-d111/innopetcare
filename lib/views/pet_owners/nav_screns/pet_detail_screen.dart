import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PetDetailScreen extends StatefulWidget {
  final String petUid;
  final String projectId;
  final Color colorTheme;

  const PetDetailScreen({
    required this.petUid,
    required this.projectId,
    required this.colorTheme,
    Key? key,
  }) : super(key: key);

  @override
  _PetDetailScreenState createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  Map<String, dynamic>? petData;
  List<Map<String, dynamic>> sections = [];
  List<Map<String, dynamic>> records = [];
  String? selectedSectionId;
  bool isLoading = true;
  bool isRecordsLoading = false;
  String? selectedSection;
  List<Map<String, dynamic>> selectedSectionColumns = [];

  @override
  void initState() {
    super.initState();
    _fetchPetDetails();
    _fetchSections();
  }

  // Fetch pet details based on petUid
  Future<void> _fetchPetDetails() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('pets')
          .doc(widget.petUid)
          .get();

      if (snapshot.exists) {
        setState(() {
          petData = snapshot.data();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching pet details: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Calculate pet age
  String _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    final years = now.year - birthDate.year;
    final months = now.month - birthDate.month;
    return (months < 0)
        ? '$years years, ${12 + months} months'
        : '$years years, $months months';
  }

  Future<void> _fetchSections() async {
    try {
      final sectionsSnapshot = await FirebaseFirestore.instance
          .collection('pet-health-sections')
          .doc(widget.projectId)
          .collection('sections')
          .get();

      List<Map<String, dynamic>> fetchedSections = [];
      for (var sectionDoc in sectionsSnapshot.docs) {
        final sectionData = sectionDoc.data();
        final sectionId = sectionDoc.id;
        // Fetch columns for each section
        final columnsSnapshot = await FirebaseFirestore.instance
            .collection('pet-health-sections')
            .doc(widget.projectId)
            .collection('sections')
            .doc(sectionId)
            .collection('columns')
            .get();

        final columns = columnsSnapshot.docs.map((colDoc) {
          return {'id': colDoc.id, ...colDoc.data()};
        }).toList();

        fetchedSections.add({
          'id': sectionId,
          'name': sectionData['name'],
        });
      }

      setState(() {
        sections = fetchedSections;
        print(sections);
      });
    } catch (error) {
      print('Error fetching sections: $error');
    }
  }

  Future<void> _fetchRecords(String sectionId) async {
    setState(() {
      isRecordsLoading = true;
      records = [];
    });

    try {
      // Fetch columns for the selected section
      final columnsSnapshot = await FirebaseFirestore.instance
          .collection('pet-health-sections')
          .doc(widget.projectId)
          .collection('sections')
          .doc(sectionId)
          .collection('columns')
          .get();

      // Extract column UIDs and names
      List<Map<String, dynamic>> columns = columnsSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc.data()['name'],
        };
      }).toList();

      // Fetch records for the selected section
      final recordsRef = FirebaseFirestore.instance
          .collection('pet-health-records')
          .doc(widget.projectId)
          .collection(widget.petUid)
          .doc(sectionId)
          .collection('records');

      final snapshot = await recordsRef.get();
      final fetchedRecords = snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();

      setState(() {
        records = fetchedRecords;
        selectedSectionColumns = columns; // Store the columns for the section
      });
    } catch (error) {
      print('Error fetching records: $error');
    } finally {
      setState(() {
        isRecordsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : petData == null
              ? Center(child: Text('Pet details not found.'))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Back Button
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon:
                              Icon(Icons.arrow_back, color: widget.colorTheme),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Centered Title
                      Padding(
                        padding: const EdgeInsets.only(top: 32.0, bottom: 24.0),
                        child: Center(
                          child: Text(
                            'Pet Details',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: widget.colorTheme,
                            ),
                          ),
                        ),
                      ),

                      // Pet Image with circular frame
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: petData?['image'] != null
                            ? NetworkImage(petData!['image'])
                            : AssetImage('assets/default_pet_image.png')
                                as ImageProvider,
                      ),
                      SizedBox(height: 16),

                      // Pet Name
                      Text(
                        petData?['petName'] ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),

                      // Pet Information
                      _buildPetInfoRow(
                        'Age',
                        _calculateAge(
                          DateTime.tryParse(petData?['birthdate'] ?? '') ??
                              DateTime.now(),
                        ),
                      ),
                      _buildPetInfoRow(
                        'Birth Date',
                        DateFormat('MMMM d, yyyy').format(
                          DateTime.tryParse(petData?['birthdate'] ?? '') ??
                              DateTime.now(),
                        ),
                      ),
                      _buildPetInfoRow(
                          'Species', petData?['species'] ?? 'Unknown'),
                      _buildPetInfoRow(
                        'Gender',
                        petData?['gender'] == 'male' ? '♂' : '♀',
                        valueColor: petData?['gender'] == 'male'
                            ? Colors.blue
                            : Colors.pink,
                      ),
                      _buildPetInfoRow('Weight', '${petData?['weight']} kg'),
                      _buildPetInfoRow('Color', petData?['color'] ?? 'Unknown'),

                      SizedBox(height: 16),

                      // Health Concerns
                      _buildSectionTitle('Health Concerns'),
                      _buildPetInfoRow(
                        'Allergies',
                        petData?['allergies'] ?? 'None',
                      ),
                      _buildPetInfoRow(
                        'Existing Conditions',
                        petData?['existingConditions'] ?? 'None',
                      ),
                     const SizedBox(height: 32),
                      // Dropdown for sections
                      _buildDropdownSection(),
                      SizedBox(height: 16),
                      // Display Records List
                      isRecordsLoading
                          ? Center(child: CircularProgressIndicator())
                          : _buildRecordsList(),
                    ],
                  ),
                  // Dropdown for sections
                ),
    );
  }

  // Dropdown for sections
  Widget _buildDropdownSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Type of Record',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: widget.colorTheme,
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.colorTheme.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: widget.colorTheme),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedSection,
              dropdownColor: Colors.white,
              iconEnabledColor: widget.colorTheme,
              items: sections.map((section) {
                return DropdownMenuItem<String>(
                  value: section['id'],
                  child: Text(
                    section['name'],
                    style: TextStyle(color: widget.colorTheme),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedSection = newValue;
                  if (newValue != null) {
                    _fetchRecords(newValue);
                  }
                });
              },
              hint: Text(
                'Select Type of Record',
                style: TextStyle(color: widget.colorTheme),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordsList() {
    if (records.isEmpty) {
      return Center(
        child: Text('No records found for the selected section.'),
      );
    }

    if (selectedSectionColumns.isEmpty) {
      return Center(
        child: Text('No columns defined for this section.'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: records.length,
      itemBuilder: (context, index) {
        var record = records[index];

        return Card(
          margin: EdgeInsets.only(top: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dynamically render each column's data
                ...selectedSectionColumns.map((column) {
                  String columnId = column['id'];
                  String columnName = column['name'];

                  // Access the nested 'records' map
                  String columnValue =
                      record['records']?[columnId]?.toString() ?? '-';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          columnName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            columnValue,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method to display pet information rows
  Widget _buildPetInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: valueColor ?? Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // Section Title
  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: widget.colorTheme,
        ),
      ),
    );
  }
}
