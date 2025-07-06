import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:esp32monitoring/auth/home_screen.dart';
import 'package:esp32monitoring/auth/login_screen.dart';

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
            return const HomeScreen(); // Logged in
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
