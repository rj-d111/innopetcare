import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:innopetcare/views/pet_owners/nav_screns/messages_screen.dart';
import 'package:innopetcare/views/pet_owners/nav_screns/notifications_screen.dart';
import 'package:innopetcare/login_screen.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String uid;
  final String projectId;

  const CustomAppBar({
    Key? key,
    required this.uid,
    required this.projectId,
  }) : super(key: key);

  @override
  _CustomAppBarState createState() => _CustomAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  String projectName = "";
  String projectLogoUrl = "";
  Color headerColor = Colors.white;
  Color headerTextColor = Colors.white;
  String? projectType;

  @override
  void initState() {
    super.initState();
    _fetchProjectDetails();
  }

  Future<void> _fetchProjectDetails() async {
    try {
      // Fetch the global section document using its document ID directly
      var globalSectionDoc = await FirebaseFirestore.instance
          .collection('global-sections')
          .doc(widget.projectId)
          .get();

      if (globalSectionDoc.exists) {
        var data = globalSectionDoc.data();
        setState(() {
          projectName = data?['name'] ?? 'Project Name';
          projectLogoUrl = data?['image'] ?? '';
          headerColor =
              Color(int.parse(data?['headerColor'].replaceAll('#', '0xff')));
          headerTextColor = Color(
              int.parse(data?['headerTextColor'].replaceAll('#', '0xff')));
        });
      }

      // Fetch the project document using its document ID directly
      var projectDoc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .get();

      if (projectDoc.exists) {
        setState(() {
          projectType = projectDoc.data()?['type'];
        });
      }
    } catch (e) {
      print('Error fetching project details: $e');
    }
  }

void _showAnimalShelterModal(BuildContext context) async {
  // Show a loading modal first
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
       builder: (context) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.3,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(), // Loading Circular Indicator
              SizedBox(height: 16),
              Text(
                "Loading, please wait...",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
              ),
            ],
          ),
        ),
      );
    },
  );

  List<Map<String, dynamic>> shelters = [];

  try {
    // Fetch projects of type "Animal Shelter Site" with status "active"
    var shelterProjectsSnapshot = await FirebaseFirestore.instance
        .collection('projects')
        .where('type', isEqualTo: "Animal Shelter Site")
        .where('status', isEqualTo: "active")
        .get();

    // Loop through each project
    for (var projectDoc in shelterProjectsSnapshot.docs) {
      String projectId = projectDoc.id;

      try {
        // Fetch global section details using the projectId directly
        var globalSectionDoc = await FirebaseFirestore.instance
            .collection('global-sections')
            .doc(projectId)
            .get();

        if (globalSectionDoc.exists) {
          // Safely convert data to Map<String, String>
          final data = globalSectionDoc.data();
          if (data != null) {
            Map<String, String> parsedGlobalData = data.map((key, value) =>
                MapEntry(key, value != null ? value.toString() : ''));

            shelters.add({
              'name': parsedGlobalData['name'] ?? 'Unnamed Shelter',
              'image': parsedGlobalData['image'] ?? '',
              'projectId': projectId,
              'globalData': parsedGlobalData,
            });
          }
        }
      } catch (e) {
        print('Error fetching global section for projectId $projectId: $e');
      }
    }

    // Sort the shelters alphabetically by name
    shelters.sort((a, b) => a['name'].compareTo(b['name']));

    // Close the loading modal
    Navigator.pop(context);

    if (shelters.isNotEmpty) {
      // Show modal with animal shelters
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                // Drag Handle
                Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // Modal Title and Close Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Animal Shelters",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // List of Shelters
                Expanded(
                  child: ListView.builder(
                    itemCount: shelters.length,
                    itemBuilder: (context, index) {
                      final shelter = shelters[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundImage: shelter['image'].isNotEmpty
                              ? NetworkImage(shelter['image'])
                              : const AssetImage('assets/default_avatar.png')
                                  as ImageProvider,
                          backgroundColor: Colors.grey[200],
                        ),
                        title: Text(
                          shelter['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginScreen(
                                  projectId: shelter['projectId'],
                                  globalData: shelter['globalData'],
                                ),
                              ),
                            );
                          },
                          child: const Text('Visit Now'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      // If no shelters are found, show a simple message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("No Shelters Found"),
          content: const Text(
              "There are no active animal shelters at the moment."),
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
    // Close the loading modal in case of error
    Navigator.pop(context);

    print('Error fetching animal shelters: $e');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: const Text("Something went wrong while fetching data."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: headerColor,
      title: Row(
        children: [
          if (projectLogoUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Image.network(
                projectLogoUrl,
                width: 30,
                height: 30,
                fit: BoxFit.contain,
              ),
            ),
          Text(
            projectName,
            style: TextStyle(
              color: headerTextColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
      actions: [
        if (projectType != 'Animal Shelter Site')
          IconButton(
            icon: Image.asset('assets/img/adopt-pet.png'),
            onPressed: () => _showAnimalShelterModal(context),
          ),
        IconButton(
          icon: Icon(Icons.notifications, color: headerTextColor),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotificationsScreen(
                  uid: widget.uid,
                  projectId: widget.projectId,
                  colorTheme: headerColor,
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.message, color: headerTextColor),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MessagesScreen(
                  uid: widget.uid,
                  projectId: widget.projectId,
                  colorTheme: headerColor,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
