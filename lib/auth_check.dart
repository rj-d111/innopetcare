import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:innopetcare/views/pet_owners/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:innopetcare/innopetcare_screen.dart';

class AuthCheck extends StatelessWidget {
  const AuthCheck({Key? key}) : super(key: key);

  Future<String?> _getSavedProjectId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('projectId');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          final user = snapshot.data!;
          return FutureBuilder<String?>(
            future: _getSavedProjectId(),
            builder: (context, projectIdSnapshot) {
              if (projectIdSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              final projectId = projectIdSnapshot.data ?? '';
              return MainScreen(uid: user.uid, projectId: projectId);
            },
          );
        } else {
          return InnoPetCareScreen();
        }
      },
    );
  }
}
