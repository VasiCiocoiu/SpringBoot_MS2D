import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:esp32monitoring/auth/login_screen.dart';
import 'package:esp32monitoring/screens/apiary_list_screen.dart';
import 'package:esp32monitoring/providers/hierarchy_provider.dart';
import 'package:esp32monitoring/services/firebase_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user == null) {
            return const LoginScreen(); // Not logged in
          } else {
            // User is logged in, provide hierarchy management
            return ChangeNotifierProvider(
              create: (context) => HierarchyProvider(
                userId: user.uid,
                firebaseService: FirebaseService(),
              ),
              child: const ApiaryListScreen(), // Start with apiary selection
            );
          }
        } else {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
