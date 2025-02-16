import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:innopetcare/views/pet_owners/nav_screns/animal_shelter_appointments_screen.dart';
import 'package:innopetcare/views/pet_owners/nav_screns/widgets/custom_app_bar.dart';

class VolunteerScreen extends StatefulWidget {
  final String uid;
  final String projectId;
  final Color colorTheme;

  const VolunteerScreen(
      {required this.uid, required this.projectId, required this.colorTheme});

  @override
  _VolunteerScreenState createState() => _VolunteerScreenState();
}

class _VolunteerScreenState extends State<VolunteerScreen> {
  List<Map<String, dynamic>> sections = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchProjectData();
  }

  Future<void> fetchProjectData() async {
    try {
      // Fetch the global section document directly using the projectId
      final globalSectionDoc = await FirebaseFirestore.instance
          .collection("global-sections")
          .doc(widget.projectId)
          .get();

      if (globalSectionDoc.exists) {
        final projectId = globalSectionDoc.id;

        // Fetch the sections using the projectId directly
        final sectionsSnapshot = await FirebaseFirestore.instance
            .collection("volunteer-sections/$projectId/sections")
            .get();

        setState(() {
          sections = sectionsSnapshot.docs
              .map((sectionDoc) => {
                    "id": sectionDoc.id,
                    ...sectionDoc.data() as Map<String, dynamic>
                  })
              .toList();
          loading = false;
        });
      } else {
        print(
            "No global-section document found for projectId: ${widget.projectId}");
        setState(() {
          loading = false;
        });
      }
    } catch (error) {
      print("Error fetching project data: $error");
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
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    children: sections.map((section) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  section["sectionTitle"] ?? "Default Title",
                                  style: TextStyle(
                                      fontSize: 24,
                                      color: widget.colorTheme,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  section["sectionSubtext"] ??
                                      "Default Subtext",
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  section["sectionContent"] ??
                                      "Default Content",
                                  style: TextStyle(fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          if (section["sectionType"] == "carousel" &&
                              (section["sectionImages"] as List<dynamic>?)
                                      ?.isNotEmpty ==
                                  true)
                            CarouselWidget(
                                images: List<String>.from(
                                    section["sectionImages"])),
                          if (section["sectionType"] == "grid" &&
                              (section["sectionImages"] as List<dynamic>?)
                                      ?.isNotEmpty ==
                                  true)
                            GridWidget(
                                images: List<String>.from(
                                    section["sectionImages"])),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                // Add the regular button below the ListView
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          widget.colorTheme, // Pink color for the button
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnimalShelterAppointmentsScreen(
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
                        Icon(Icons.volunteer_activism, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Volunteer Now',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class CarouselWidget extends StatefulWidget {
  final List<String> images;

  const CarouselWidget({Key? key, required this.images}) : super(key: key);

  @override
  _CarouselWidgetState createState() => _CarouselWidgetState();
}

class _CarouselWidgetState extends State<CarouselWidget> {
  PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 400,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return Image.network(
                widget.images[index],
                fit: BoxFit.cover,
                width: double.infinity,
              );
            },
          ),
        ),
        if (widget.images.length > 1)
          Positioned(
            left: 20,
            child: IconButton(
              icon: Icon(Icons.arrow_back_ios),
              color: Colors.white,
              onPressed: () {
                if (_currentPage > 0) {
                  _pageController.previousPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
            ),
          ),
        if (widget.images.length > 1)
          Positioned(
            right: 20,
            child: IconButton(
              icon: Icon(Icons.arrow_forward_ios),
              color: Colors.white,
              onPressed: () {
                if (_currentPage < widget.images.length - 1) {
                  _pageController.nextPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
            ),
          ),
      ],
    );
  }
}

class GridWidget extends StatelessWidget {
  final List<String> images;

  const GridWidget({Key? key, required this.images}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int columnCount = images.length >= 4 ? 4 : images.length;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columnCount,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              images[index],
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }
}
