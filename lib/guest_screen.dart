import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:innopetcare/sites_screen.dart';
import 'package:innopetcare/innopetcare_options_screen.dart';


class GuestScreen extends StatefulWidget {
  const GuestScreen({Key? key}) : super(key: key);

  @override
  _GuestScreenState createState() => _GuestScreenState();
}

class _GuestScreenState extends State<GuestScreen> {
  int _currentIndex = 0;
  final List<Widget> _slides = [];
  bool isEnabled = true;

  void _launchInnopetcareWebsite() async {
    final Uri url = Uri.parse('https://innopetcare.com');
    launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _fetchIsEnabled() async {
    try {
      final sectionsSnapshot = await FirebaseFirestore.instance
          .collection('button')
          .doc('button')
          .get();

      setState(() {
        // Use null-aware access to prevent potential errors
        isEnabled = sectionsSnapshot.data()?['isEnabled'] ?? true;
        print(isEnabled ? "The button is Enabled" : "The button is Disabled");
        _initializeSlides(); // Rebuild slides after isEnabled is updated
      });
    } catch (error) {
      print('Error fetching sections: $error');
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeSlides();
    _fetchIsEnabled();
  }

  void _initializeSlides() {
    _slides.addAll([
      _buildSlide(
        'assets/img/cats-dogs.png',
        'Discover the future of pet care with InnoPetCare',
        'InnoPetCare is a platform that empowers veterinary clinics and animal shelters to create their own sites. '
            'Our goal is to make it easier for pet owners to find the resources and care they need, and for those who care '
            'for pets in shelters to find ways to get involved, such as volunteering, donating, or adopting.',
      ),
      _buildSlideWithButton(
        'assets/img/veterinary-guest.jpg',
        'Veterinary Clinic Owner',
        'With InnoPetCare, you can create your own site to promote your clinic, showcase services, attract new clients, '
            'efficiently manage appointments, patient records, and communications, and support animal shelters with our unique feature tailored for animal welfare.',
        isEnabled
            ? ElevatedButton(
                onPressed: _launchInnopetcareWebsite,
                child: const Text("Visit InnoPetCare Website",
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[400],
                ),
              )
            : const SizedBox.shrink(),
      ),
      _buildSlideWithButton(
        'assets/img/adopt-pet.png',
        'Adopt, Volunteer, or Donate',
        'If you want to adopt a pet, donate, or volunteer, InnoPetCare makes it easy to find animal shelters. '
            'You can browse shelter sites, learn about their history, and even set up visit appointments if you have an account.',
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SitesScreen()),
            );
          },
          child: const Text("View list of Veterinary Clinics & Shelter",
              style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.brown[400],
          ),
        ),
      ),
      _buildSlideWithButton(
        'assets/img/future-pet-owner.jpg',
        'Future Pet Owners',
        'If you are a pet owner with InnoPetCare, you can easily find veterinary clinics and animal shelters. '
            'Once you have an account, you can book appointments, view medical records, and communicate with clinics.',
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SitesScreen()),
            );
          },
          child: const Text("View list of Veterinary Clinics & Shelter",
              style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.brown[400],
          ),
        ),
      ),
    ]);
  }

  Widget _buildSlide(String imagePath, String title, String description) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(imagePath, height: 150),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.brown[600]),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.justify,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSlideWithButton(
      String imagePath, String title, String description, Widget button) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(imagePath, height: 150),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style:  TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown[600]),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            textAlign: TextAlign.justify,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: button,
          ),
        ],
      ),
    );
  }

  void _nextSlide() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _slides.length;
    });
  }

  void _previousSlide() {
    setState(() {
      _currentIndex = (_currentIndex - 1 + _slides.length) % _slides.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Guest View"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => InnopetcareOptionsScreen()),
            );
          },
        ),
      ),
      body: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 36),
            onPressed: _previousSlide,
          ),
          Expanded(
            child: Center(
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: _slides[_currentIndex],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward, size: 36),
            onPressed: _nextSlide,
          ),
        ],
      ),
    );
  }
}
