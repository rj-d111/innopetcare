import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:innopetcare/login_screen.dart';
import 'package:innopetcare/views/pet_owners/nav_screns/animal_shelter_list.dart';
import 'package:innopetcare/views/pet_owners/nav_screns/messages_screen.dart';
import 'package:innopetcare/views/pet_owners/nav_screns/notifications_screen.dart';
import 'package:innopetcare/views/pet_owners/nav_screns/profiles_screen.dart';
import 'package:innopetcare/views/pet_owners/nav_screns/widgets/custom_app_bar.dart';

class HomePageScreen extends StatefulWidget {
  final String uid;
  final String projectId;

  const HomePageScreen({required this.uid, required this.projectId});

  @override
  _HomePageScreenState createState() => _HomePageScreenState();
}

class _HomePageScreenState extends State<HomePageScreen> {
  String projectName = "";
  String projectLogoUrl = "";
  Color headerColor = Colors.blue;
  Color headerTextColor = Colors.white;
  String? projectType;
  List<Map<String, dynamic>> sections = [];

  @override
  void initState() {
    super.initState();
    _fetchProjectDetails();
    _fetchHomeSections();
  }

  Future<void> _fetchProjectDetails() async {
    try {
      var globalSectionsDoc = await FirebaseFirestore.instance
          .collection('global-sections')
          .where('projectId', isEqualTo: widget.projectId)
          .get();

      if (globalSectionsDoc.docs.isNotEmpty) {
        var data = globalSectionsDoc.docs.first.data();
        setState(() {
          projectName = data['name'];
          projectLogoUrl = data['image'];
          headerColor =
              Color(int.parse(data['headerColor'].replaceAll('#', '0xff')));
          headerTextColor =
              Color(int.parse(data['headerTextColor'].replaceAll('#', '0xff')));
        });
      }

      var projectDoc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .get();

      if (projectDoc.exists && projectDoc.data() != null) {
        setState(() {
          projectType = projectDoc['type'];
        });
      }
    } catch (e) {
      print('Error fetching project details: $e');
    }
  }

  Future<void> _fetchHomeSections() async {
    try {
      var homeSectionsSnapshot = await FirebaseFirestore.instance
          .collection('home-sections')
          .doc(widget.projectId)
          .collection('sections')
          // .orderBy('sectionCreated', ascending: true)
          .get();

      setState(() {
        sections = homeSectionsSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      });
    } catch (e) {
      print('Error fetching home sections: $e');
    }
  }
void _showAnimalShelterModal(BuildContext context) async {
  List<Map<String, dynamic>> shelters = [];

  try {
    // Fetch projects of type "Animal Shelter Site" with status "active"
    var shelterProjectsSnapshot = await FirebaseFirestore.instance
        .collection('projects')
        .where('type', isEqualTo: "Animal Shelter Site")
        .where('status', isEqualTo: "active")
        .get();

    for (var projectDoc in shelterProjectsSnapshot.docs) {
      String projectId = projectDoc.id;

      try {
        // Fetch global section details matching the projectId
        var globalSectionsSnapshot = await FirebaseFirestore.instance
            .collection('global-sections')
            .where('projectId', isEqualTo: projectId)
            .get();

        if (globalSectionsSnapshot.docs.isNotEmpty) {
          var globalData = globalSectionsSnapshot.docs.first.data();
          shelters.add({
            'name': globalData['name'] ?? 'Unnamed Shelter',
            'image': globalData['image'] ?? '',
            'projectId': projectId,
            'globalData': globalData, // Include globalData for passing
          });
        }
      } catch (e) {
        print('Error fetching global sections for projectId $projectId: $e');
      }
    }

    if (shelters.isNotEmpty) {
      // Show modal with animal shelters
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        builder: (context) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.4,
          maxChildSize: 0.9,
          minChildSize: 0.32,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: AnimalShelterListScreen(shelters: shelters),
            );
          },
        ),
      );
    } else {
      // Show a dialog if no shelters are found
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("No Shelters Found"),
          content: const Text("There are no active animal shelters at the moment."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  } catch (e) {
    print('Error fetching animal shelters: $e');
  }
}

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Exit App"),
            content: Text("Are you sure you want to quit?"),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(false), // Dismiss dialog
                child: Text("No"),
              ),
              TextButton(
                onPressed: () {
                  // Close dialog and exit app
                  Navigator.of(context).pop(true);
                  if (Platform.isAndroid) {
                    SystemNavigator.pop(); // Closes the app on Android
                  } else if (Platform.isIOS) {
                    exit(0); // Forces the app to quit on iOS
                  }
                },
                child: Text("Yes"),
              ),
            ],
          ),
        ) ??
        false; // Return false if dialog is dismissed
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool shouldExit = await _showExitConfirmationDialog(context);
        return shouldExit;
      },
      child: Scaffold(
        appBar: CustomAppBar(uid: widget.uid, projectId: widget.projectId),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: sections.map((section) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section['sectionTitle'] ?? '',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      section['sectionSubtext'] ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      section['sectionContent'] ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 16),
                    if (section['sectionType'] == 'carousel')
                      _buildCarousel(section['sectionImages'])
                    else if (section['sectionType'] == 'grid')
                      _buildGrid(section['sectionImages']),
                    SizedBox(height: 20),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildCarousel(List<dynamic> images) {
    PageController _pageController = PageController();
    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: _pageController,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Stack(
            children: [
              Image.network(
                images[index],
                fit: BoxFit.cover,
                width: double.infinity,
              ),
              if (index > 0)
                Positioned(
                  left: 10,
                  top: 0,
                  bottom: 0,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      _pageController.previousPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut);
                    },
                  ),
                ),
              if (index < images.length - 1)
                Positioned(
                  right: 10,
                  top: 0,
                  bottom: 0,
                  child: IconButton(
                    icon: Icon(Icons.arrow_forward, color: Colors.white),
                    onPressed: () {
                      _pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut);
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGrid(List<dynamic> images) {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: images.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        return Image.network(
          images[index],
          fit: BoxFit.cover,
        );
      },
    );
  }
}
