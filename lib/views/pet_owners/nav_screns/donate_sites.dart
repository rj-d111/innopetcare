import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DonateSites extends StatefulWidget {
  final String uid;
  final String projectId;

  const DonateSites({Key? key, required this.uid, required this.projectId})
      : super(key: key);

  @override
  State<DonateSites> createState() => _DonateSitesState();
}

class _DonateSitesState extends State<DonateSites> {
  List<Map<String, dynamic>> donations = [];
  bool loading = true;

  // Map for storing the bank logos
  final Map<String, String> iconMap = {
    "Metropolitan Bank and Trust Company (METROBANK)": 'assets/donate/metrobank.png',
    "UnionBank of the Philippines (UBP)": 'assets/donate/unionbank.png',
    "Land Bank of the Philippines": 'assets/donate/landbank.png',
    "Philippine National Bank (PNB)": 'assets/donate/pnb.png',
    "Banco de Oro (BDO)": 'assets/donate/bdo.jpg',
    "Bank of Commerce": 'assets/donate/bankofcommerce.png',
    "GCash": 'assets/donate/gcash.png',
    "PayMaya": 'assets/donate/paymaya.png',
  };

  @override
  void initState() {
    super.initState();
    fetchDonations();
  }

  // Fetch donations from Firestore
  Future<void> fetchDonations() async {
    setState(() {
      loading = true;
    });

    try {
      FirebaseFirestore db = FirebaseFirestore.instance;
      final donationsRef = db.collection('donations-section/${widget.projectId}/donations');
      final snapshot = await donationsRef.get();

      setState(() {
        donations = snapshot.docs.map((doc) {
          return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
        }).toList();
      });
    } catch (error) {
      print("Error fetching donations: $error");
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  // Group donations by site
  Map<String, List<Map<String, dynamic>>> groupDonations() {
    Map<String, List<Map<String, dynamic>>> groupedDonations = {};
    for (var donation in donations) {
      String site = donation['donationSite'] ?? 'Others';
      if (!groupedDonations.containsKey(site)) {
        groupedDonations[site] = [];
      }
      groupedDonations[site]!.add(donation);
    }
    return groupedDonations;
  }

  @override
  Widget build(BuildContext context) {
    final groupedDonations = groupDonations();

    return loading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var site in groupedDonations.keys) ...[
                  Card(
                    elevation: 5,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Display bank icon or fallback to a default icon
                              iconMap.containsKey(site)
                                  ? Image.asset(
                                      iconMap[site]!,
                                      width: 50,
                                      height: 50,
                                    )
                                  : const Icon(
                                      Icons.monetization_on,
                                      size: 50,
                                      color: Colors.blue,
                                    ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  site,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          for (var donation in groupedDonations[site]!) ...[
                            Text(
                              'Account Name: ${donation['accountName']}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            Text(
                              'Account Number: ${donation['accountNumber']}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
  }
}
