import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:innopetcare/innopetcare_options_screen.dart';
import 'package:innopetcare/login_screen.dart';

class SitesScreen extends StatefulWidget {
  @override
  _SitesScreenState createState() => _SitesScreenState();
}

class _SitesScreenState extends State<SitesScreen> {
  String selectedFilter = 'All';
  bool isGridView = false;
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sites'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => InnopetcareOptionsScreen()),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          // Wrap the entire Column with SingleChildScrollView
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(width: 8), // Add some padding on the left
                    _buildFilterButton('All'),
                    SizedBox(width: 8),
                    _buildFilterButton('Veterinary Site'),
                    SizedBox(width: 8),
                    _buildFilterButton('Animal Shelter Site'),
                    SizedBox(width: 8),
                    IconButton(
                      icon:
                          Icon(isGridView ? Icons.view_list : Icons.grid_view),
                      onPressed: () {
                        setState(() {
                          isGridView = !isGridView;
                        });
                      },
                    ),
                    SizedBox(width: 8), // Add some padding on the right
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name or location...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (query) {
                    setState(() {
                      searchQuery = query.toLowerCase();
                    });
                  },
                ),
              ),
              // Make sure the GridView and ListView can shrink
              isGridView ? _buildGridView() : _buildListView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(String filter) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedFilter = filter;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: selectedFilter == filter ? Colors.brown : Colors.grey,
        foregroundColor: Colors.white,
      ),
      child: Text(filter),
    );
  }

  Widget _buildGridView() {
    return StreamBuilder(
      stream: _filteredProjectsStream(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        var projects = snapshot.data!.docs;
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.4, // Reduce the ratio for taller grid items
          ),
          shrinkWrap: true, // Ensure the GridView takes up only necessary space
          physics:
              NeverScrollableScrollPhysics(), // Disable GridView's internal scrolling
          itemCount: projects.length,
          itemBuilder: (context, index) {
            var project = projects[index];
            return _buildProjectTile(project);
          },
        );
      },
    );
  }

  Widget _buildListView() {
    return StreamBuilder(
      stream: _filteredProjectsStream(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        var projects = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true, // Ensure the ListView takes up only necessary space
          physics:
              NeverScrollableScrollPhysics(), // Disable ListView's internal scrolling
          itemCount: projects.length,
          itemBuilder: (context, index) {
            var project = projects[index];
            return _buildProjectTile(project);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _filteredProjectsStream() {
    Query<Map<String, dynamic>> collection =
        FirebaseFirestore.instance.collection('projects');

    if (selectedFilter != 'All') {
      collection = collection.where('type', isEqualTo: selectedFilter);
    }

    return collection.where('status', isEqualTo: 'active').snapshots();
  }

  Widget _buildProjectTile(DocumentSnapshot project) {
    return FutureBuilder<Map<String, String>>(
      future: getGlobalSectionData(project.id),
      builder: (context, AsyncSnapshot<Map<String, String>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Container();
        }

        // Extract the global data
        var globalData = snapshot.data!;
        String name = globalData['name'] ?? 'Unknown';
        String imageUrl =
            globalData['image'] ?? 'https://via.placeholder.com/50';
        String address = globalData['address'] ?? 'No address provided';
        String headerColorString = globalData['headerColor'] ?? '#795548';
        // Check if search query matches either name or address
        var nameMatches =
            name.toLowerCase().contains(searchQuery.toLowerCase());
        var addressMatches =
            address.toLowerCase().contains(searchQuery.toLowerCase());

        if (!nameMatches && !addressMatches) {
          return Container();
        }

        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(
                imageUrl,
                width: double.infinity,
                height: 100,
                fit: BoxFit.cover,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            address,
                            style: TextStyle(
                              fontSize:
                                  12, // Adjust this value to make the font smaller
                              color: Colors
                                  .grey.shade900, // Optional: Set text color
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(
                              projectId: project.id,
                              globalData: globalData,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.brown, // Set the button's background color
                        foregroundColor: Colors.white, // Set the text color
                        padding: EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12), // Optional padding
                      ),
                      child: Text('Visit Now'),
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, String>> getGlobalSectionData(String projectId) async {
    var globalSections = await FirebaseFirestore.instance
        .collection('global-sections')
        .doc(projectId)
        .get();

    if (globalSections.exists) {
      return {
        'name': globalSections['name'] ?? 'Unknown',
        'image': globalSections['image'] ?? 'https://via.placeholder.com/50',
        'address': globalSections['address'] ?? 'No address provided',
        'headerColor': globalSections['headerColor'],
        'slug': globalSections['slug'],
      };
    } else {
      return {
        'name': 'Unknown',
        'image': 'https://via.placeholder.com/50',
        'address': 'No address provided',
      };
    }
  }
}
