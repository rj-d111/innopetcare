import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'adopts_screen_details.dart';

class AdoptsScreen extends StatefulWidget {
  final String uid;
  final String projectId;
  final Color colorTheme;

  AdoptsScreen(
      {required this.uid, required this.projectId, required this.colorTheme});

  @override
  _AdoptsScreenState createState() => _AdoptsScreenState();
}

class _AdoptsScreenState extends State<AdoptsScreen> {
  String filterSpecies = 'All';
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

Stream<QuerySnapshot> _fetchAdoptions() {
  var query = FirebaseFirestore.instance
      .collection('adoptions')
      .doc(widget.projectId)
      .collection('animals')
      .where('isArchive', isEqualTo: false);

  // Apply species filter
  if (filterSpecies != 'All') {
    if (filterSpecies == 'Other') {
      query = query.where('species', whereIn: ['rabbit', 'bird']);
    } else {
      query = query.where('species', isEqualTo: filterSpecies.toLowerCase());
    }
  }

  return query.snapshots();
}

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 32.0, bottom: 16.0),
              child: Center(
                child: Text(
                  'Adopt Pets',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: widget.colorTheme,
                  ),
                ),
              ),
            ),
            // Search Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search pets...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Filter Row
            Row(
              children: [
                _buildFilterButton('All'),
                _buildFilterButton('Dog'),
                _buildFilterButton('Cat'),
                _buildDropdownFilterButton('Other', ['Rabbit', 'Bird']),
              ],
            ),
            SizedBox(height: 16),
            // Adoptions List
         Expanded(
  child: StreamBuilder<QuerySnapshot>(
    stream: _fetchAdoptions(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return Center(
          child: Text('No pets available for adoption'),
        );
      }

      // Filter results locally if necessary
      final filteredAdoptions = snapshot.data!.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final petName = data['petName']?.toLowerCase() ?? '';
        return petName.contains(searchQuery.toLowerCase());
      }).toList();

      if (filteredAdoptions.isEmpty) {
        return Center(
          child: Text('No pets found matching your search.'),
        );
      }

      return ListView.builder(
        itemCount: filteredAdoptions.length,
        itemBuilder: (context, index) {
          final pet = {
            ...filteredAdoptions[index].data() as Map<String, dynamic>,
            'uid': filteredAdoptions[index].id,
          };
          return _buildPetCard(pet);
        },
      );
    },
  ),
),
  ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String species) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            filterSpecies = species;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              filterSpecies == species ? widget.colorTheme : Colors.grey[300],
          foregroundColor:
              filterSpecies == species ? Colors.white : Colors.black54,
        ),
        child: Text(species),
      ),
    );
  }

  Widget _buildDropdownFilterButton(String label, List<String> options) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: DropdownButton<String>(
        value: filterSpecies == 'Other' ? options[0] : null,
        icon: Icon(Icons.arrow_drop_down),
        hint: Text(label),
        onChanged: (String? newValue) {
          setState(() {
            filterSpecies = 'Other';
          });
        },
        items: options.map((String option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPetCard(Map<String, dynamic> pet) {
    final petGenderIcon = pet['gender'] == 'male' ? '♂' : '♀';
    final petGenderColor = pet['gender'] == 'male' ? Colors.blue : Colors.pink;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundImage:
                  pet['image'] != null ? NetworkImage(pet['image']) : null,
              radius: 40,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${pet['petName'] ?? 'Pet Name'} $petGenderIcon',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: petGenderColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    pet['breed'] ?? 'Breed Info',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdoptsScreenDetails(
                              uid: widget.uid,
                              projectId: widget.projectId,
                              petId: pet['uid'],
                              colorTheme: widget.colorTheme,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'View Pet Details >',
                        style: TextStyle(color: widget.colorTheme),
                      ),
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
}
