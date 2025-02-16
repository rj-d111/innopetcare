import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BannerWidget extends StatefulWidget {
  @override
  State<BannerWidget> createState() => _BannerWidgetState();
}

class _BannerWidgetState extends State<BannerWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> _bannerImage = [];

  Future<void> getBanners() async {
    QuerySnapshot querySnapshot = await _firestore.collection('banners').get();
    List<String> bannerImages = [];
    for (var doc in querySnapshot.docs) {
      bannerImages.add(doc['image']);
    }
    setState(() {
      _bannerImage.addAll(bannerImages);
    });
  }

  @override
  void initState() {
    super.initState();
    getBanners();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.blue.shade900,
          borderRadius: BorderRadius.circular(10),
        ),
        child: _bannerImage.isEmpty
            ? Center(child: CircularProgressIndicator())
            : PageView.builder(
                itemCount: _bannerImage.length,
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      _bannerImage[index],
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
      ),
    );
  }
}
