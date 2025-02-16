import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:innopetcare/views/pet_owners/main_screen.dart';
import 'package:innopetcare/views/pet_owners/nav_screns/pet_detail_screen.dart';

class PetHealthRecordScreen extends StatelessWidget {
  final String uid;
  final String projectId;
  final Color colorTheme;

  PetHealthRecordScreen(
      {required this.uid, required this.projectId, required this.colorTheme});

  // Fetch pets based on clientId and projectId
  Stream<QuerySnapshot> _getPets() {
    return FirebaseFirestore.instance
        .collection('pets')
        .where('clientId', isEqualTo: uid)
        .where('projectId', isEqualTo: projectId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate to MainScreen when back button is pressed
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(uid: uid, projectId: projectId),
          ),
        );
        return false; // Prevent default back button behavior
      },
      child: Scaffold(
        body: Column(
          children: [
            // Centered heading at the top
            Padding(
              padding: const EdgeInsets.only(top: 48.0, bottom: 16.0),
              child: Center(
                child: Text(
                  'Pet Health Records',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: colorTheme,
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getPets(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'No pets found.',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    );
                  }

                  // Display pets in a grid
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // 2 items per row
                        crossAxisSpacing: 16.0,
                        mainAxisSpacing: 16.0,
                        childAspectRatio:
                            0.8, // Adjust to control card height relative to width
                      ),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var pet = snapshot.data!.docs[index];
                        String petName = pet['petName'] ?? 'Unknown';
                        String petImage =
                            pet['image'] ?? ''; // URL to pet image
                        String petUid = pet.id;

                        return Card(
                          color: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: _buildPetCard(
                                context, petName, petImage, petUid),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build each Pet Card
  Widget _buildPetCard(
      BuildContext context, String petName, String petImage, String petUid) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          backgroundImage: petImage.isNotEmpty ? NetworkImage(petImage) : null,
          radius: 40,
        ),
        SizedBox(height: 10),
        Text(
          petName,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PetDetailScreen(
                  petUid: petUid,
                  projectId: projectId,
                  colorTheme: colorTheme,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: colorTheme,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            "View Records",
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
