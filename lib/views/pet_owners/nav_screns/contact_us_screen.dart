import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatefulWidget {
  final String projectId;
  final String uid;
  final Color colorTheme;

  const ContactUsScreen(
      {Key? key,
      required this.uid,
      required this.projectId,
      required this.colorTheme})
      : super(key: key);

  @override
  _ContactUsScreenState createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  List<Map<String, dynamic>> contacts = [];
  bool loading = true;
  Map<String, IconData> iconMap = {
    "phone": Icons.phone,
    "landline": Icons.phone_in_talk,
    "email": Icons.email,
    "address": Icons.location_on,
    "facebook": Icons.facebook,
    "messenger": Icons.message,
    "youtube": Icons.video_library,
    "instagram": Icons.camera_alt,
    "linkedin": Icons.business,
    "whatsapp": Icons.phone,
    "telegram": Icons.send,
    "viber": Icons.chat,
    "others": Icons.help,
  };

  @override
  void initState() {
    super.initState();
    fetchContacts();
  }

  // Fetch contacts from Firestore
  Future<void> fetchContacts() async {
    setState(() => loading = true);
    try {
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

  // Filter contacts by type
  Map<String, List<Map<String, dynamic>>> groupContactsByType() {
    Map<String, List<Map<String, dynamic>>> groupedContacts = {};
    for (var contact in contacts) {
      String type = contact['type'] ?? 'others';
      if (!groupedContacts.containsKey(type)) {
        groupedContacts[type] = [];
      }
      groupedContacts[type]!.add(contact);
    }
    return groupedContacts;
  }

  // Fetch contacts with coordinates for the map
  List<Map<String, dynamic>> getContactsWithCoordinates() {
    return contacts.where((contact) {
      return contact['type'] == 'address' &&
          contact['location'] != null &&
          contact['location']['latitude'] != null &&
          contact['location']['longitude'] != null;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final groupedContacts = groupContactsByType();
    final addressContactsWithCoordinates = getContactsWithCoordinates();

    return Scaffold(
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: widget.colorTheme),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: SelectableText(
                      'Contact Us',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: widget.colorTheme,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Display grouped contacts
                  ...groupedContacts.keys.map((type) {
                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      child: ListTile(
                        leading: Icon(
                          iconMap[type] ?? Icons.help,
                          color: widget.colorTheme,
                          size: 30,
                        ),
                        title: SelectableText(
                          type[0].toUpperCase() + type.substring(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: groupedContacts[type]!
                              .map((contact) => SelectableText(contact['content'] ?? ''))
                              .toList(),
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 24),
                  // Display map for addresses with coordinates
                  if (addressContactsWithCoordinates.isNotEmpty)
                    const SelectableText(
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
                        SelectableText(contact['content'] ?? 'Location'),
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
                                    child: Icon(
                                      Icons.location_pin,
                                      color: widget.colorTheme,
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
