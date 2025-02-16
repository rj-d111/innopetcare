import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ContactUsLocations extends StatefulWidget {
  final String projectId;
  final String uid;

  const ContactUsLocations({Key? key, required this.uid, required this.projectId})
      : super(key: key);

  @override
  _ContactUsLocationsState createState() => _ContactUsLocationsState();
}

class _ContactUsLocationsState extends State<ContactUsLocations> {
  List<Map<String, dynamic>> contacts = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchContacts();
  }

  Future<void> fetchContacts() async {
    setState(() => loading = true);
    try {
      // Fetch contacts from Firestore
      final contactsRef = FirebaseFirestore.instance
          .collection('contact-sections/${widget.projectId}/sections');
      final snapshot = await contactsRef.get();

      final fetchedContacts = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();

      setState(() {
        contacts = fetchedContacts;
        loading = false;
      });
    } catch (error) {
      print('Error fetching contacts: $error');
      setState(() => loading = false);
    }
  }

  // Filter address contacts with coordinates
  List<Map<String, dynamic>> getAddressContactsWithCoordinates() {
    return contacts.where((contact) {
      return contact['type'] == 'address' &&
          contact['location'] != null &&
          contact['location']['latitude'] != null &&
          contact['location']['longitude'] != null;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final addressContactsWithCoordinates = getAddressContactsWithCoordinates();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Us'),
        backgroundColor: Colors.blue,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact Us',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (addressContactsWithCoordinates.isNotEmpty)
                    const SizedBox(height: 24),
                  if (addressContactsWithCoordinates.isNotEmpty)
                    const Text(
                      'Our Locations',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 12),
                  ...addressContactsWithCoordinates.map((contact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact['content'] ?? 'Location',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 300,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(
                                contact['location']['latitude'] ?? 0.0,
                                contact['location']['longitude'] ?? 0.0,
                              ),
                              initialZoom: 15,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                                subdomains: ['a', 'b', 'c'],
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(
                                      contact['location']['latitude'] ?? 0.0,
                                      contact['location']['longitude'] ?? 0.0,
                                    ),
                                    width: 80,
                                    height: 80,
                                    child: const Icon(
                                      Icons.location_pin,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
    );
  }
}
