import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:esp32monitoring/auth/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Temp Monitor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const FirebaseInitScreen(),
    );
  }
}

class FirebaseInitScreen extends StatelessWidget {
  const FirebaseInitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(), // Ensure Firebase is initialized
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return AuthWrapper(); // Show login or home screen
        } else if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Firebase Init Error')),
          );
        } else {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
