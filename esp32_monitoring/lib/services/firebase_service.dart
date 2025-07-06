import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/measurement_data.dart';

class FirebaseService {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  final User? user = FirebaseAuth.instance.currentUser;

  Future<List<MeasurementData>> fetchMeasurements() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user is logged in');
      return [];
    }

    try {
      // Fetch raw data from Firebase
      final snapshot =
          await _databaseRef.child('${user.uid}/measurements').get();

      if (snapshot.exists) {
        print('Data fetched: ${snapshot.value}');

        // Convert the raw data to a Map<String, dynamic>
        final rawData = (snapshot.value as Map).map(
          (key, value) => MapEntry(
            key.toString(),
            Map<String, dynamic>.from(value as Map),
          ),
        );

        // Convert the raw data to a list of MeasurementData objects
        final measurements = rawData.entries.map((entry) {
          return MeasurementData.fromJson(entry.key, entry.value);
        }).toList();

        // Sort the measurements by timestamp
        measurements.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        return measurements;
      } else {
        print('No data available for UID: ${user.uid}');
        return [];
      }
    } catch (e) {
      print('Error fetching data: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> fetchThresholds() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("No user is logged in");
    }

    final snapshot = await _databaseRef.child('${user.uid}/threshold').get();
    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return null; // Return null if no thresholds exist
  }

  Future<void> updateThresholds(double humidity, double temperature) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("No user is logged in");
    }

    await _databaseRef.child('${user.uid}/threshold').set({
      'humidity': humidity,
      'temperature': temperature,
    });
  }

  Future<void> updateThresholdsAndInterval(
      double humidity, double temperature, int interval) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("No user is logged in");
    }

    await _databaseRef.child('${user.uid}/threshold').set({
      'humidity': humidity,
      'temperature': temperature,
      'interval': interval, // Save interval in milliseconds
    });
  }
}
