import 'package:flutter/material.dart';
import 'package:innopetcare/innopetcare_screen.dart';
import 'package:innopetcare/sites_screen.dart';
import 'package:innopetcare/guest_screen.dart'; // Import GuestScreen

class InnopetcareOptionsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 255, 230, 7),
        ),
        child: Stack(
          children: [
            // Background image positioned at the top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                'assets/img/holding-paw.png',
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
                height: 200, // Set the height of the image
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  top: 200), // Push ListView below the image
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  SizedBox(height: 20), // Spacer for margin below the image
                  Text(
                    'Your furry friends\ndeserve the best.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 5,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 40),
                  _buildCard(
                    'For Customer',
                    'Browse available pets, schedule appointments, and interact with shelters. Your one-stop solution for pet adoption and care.',
                    () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => SitesScreen()),
                      );
                    },
                    'Proceed to Content Listing',
                  ),
                  SizedBox(height: 20),
                  _buildCard(
                    'For Guest',
                    'Explore available pets and resources. Sign up to access more features and keep track of your activities.',
                    () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => GuestScreen()),
                      );
                    },
                    'Explore as Guest',
                  ),
                  SizedBox(height: 40),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => InnoPetCareScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown[600],
                        padding:
                            EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        '<< Back',
                        style: TextStyle(fontSize: 18, color: Colors.white),
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

  Widget _buildCard(String title, String subtitle, VoidCallback onPressed,
      String buttonText) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.brown[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[400],
              ),
              child: Text(buttonText, style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
