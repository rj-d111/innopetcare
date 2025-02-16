import 'package:flutter/material.dart';
import 'package:innopetcare/innopetcare_options_screen.dart';

class InnoPetCareScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 40), // To push content a bit lower
              SizedBox(height: 16),
              Text(
                'Welcome to',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[700],
                ),
              ),
              SizedBox(height: 8),
              Image.asset(
                'assets/img/innopetcare-brown.png',
                height: 40,
              ),
              SizedBox(height: 16),
              Text(
                'InnoPetCare is your ultimate\nsolution for transforming veterinary\nclinics and animal shelters into\nthriving centers of pet care.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.brown[500],
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => InnopetcareOptionsScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[700],
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  'Next >>',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              SizedBox(height: 40), // For spacing at the bottom
            ],
          ),
        ),
      ),
    );
  }
}
