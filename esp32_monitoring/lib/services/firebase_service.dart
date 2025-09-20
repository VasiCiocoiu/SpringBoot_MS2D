import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/measurement_data.dart';
import '../models/apiary.dart';
import '../models/hive.dart';
import '../models/hive_constants.dart';
import '../models/hierarchy_context.dart';

class FirebaseService {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  final User? user = FirebaseAuth.instance.currentUser;

  Future<List<MeasurementData>> fetchMeasurements() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return [];
    }

    try {
      // Fetch raw data from Firebase
      final snapshot =
          await _databaseRef.child('${user.uid}/measurements').get();

      if (snapshot.exists) {
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
        return [];
      }
    } catch (e) {
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

  // ===== NEW HIERARCHICAL METHODS =====

  /// Fetches all apiaries for the current user
  Future<List<Apiary>> fetchUserApiaries() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("No user is logged in");
    }

    try {
      // Fetch from user path (this works!)
      final userSnapshot = await _databaseRef.child(user.uid).get();

      if (!userSnapshot.exists) {
        return [];
      }

      final rawData = userSnapshot.value as Map;

      final List<Apiary> apiaries = [];

      for (final entry in rawData.entries) {
        final key = entry.key.toString();
        final value = entry.value;

        // Skip legacy flat structures (measurements, threshold)
        if (key == 'measurements' || key == 'threshold') {
          continue;
        }

        // Check if this is an apiary
        if (value is Map) {
          bool isApiary = false;

          // Check if it has apiary metadata (description, address, createdAt)
          if (value.containsKey('description') ||
              value.containsKey('address') ||
              value.containsKey('createdAt')) {
            isApiary = true;
          }
          // Check if it's an empty apiary (just an empty map)
          else if (value.isEmpty) {
            isApiary = true;
          }
          // Check if it contains hive-like structures
          else {
            for (final subEntry in value.entries) {
              final subValue = subEntry.value;
              if (subValue is Map &&
                  (subValue.containsKey('measurements') ||
                      subValue.containsKey('constants'))) {
                isApiary = true;
                break;
              }
            }
          }

          if (isApiary) {
            // Extract apiary metadata if available
            final description = value['description']?.toString() ?? '';
            final address = value['address']?.toString() ?? '';
            final createdAt = value['createdAt'] != null
                ? DateTime.fromMillisecondsSinceEpoch(value['createdAt'] as int)
                : DateTime.now();

            final apiary = Apiary(
              id: key,
              name: key,
              userId: user.uid,
              description: description,
              address: address,
              createdAt: createdAt,
            );
            apiaries.add(apiary);
          }
        }
      }

      return apiaries;
    } catch (e) {
      return [];
    }
  }

  /// Fetches all hives for a specific apiary
  Future<List<Hive>> fetchApiaryHives(String apiaryId) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("No user is logged in");
    }

    try {
      // Fetch from user-scoped path
      var snapshot = await _databaseRef.child('${user.uid}/$apiaryId').get();

      if (!snapshot.exists) {
        return [];
      }

      final rawData = snapshot.value as Map;

      final List<Hive> hives = [];

      for (final entry in rawData.entries) {
        final key = entry.key.toString();
        final value = entry.value;

        // Skip apiary-level fields (description, address)
        if (key == 'description' ||
            key == 'address' ||
            key == 'createdAt' ||
            key == 'updatedAt') {
          continue;
        }

        // Check if this entry contains hive data (has measurements or constants)
        if (value is Map) {
          bool isHive = false;

          // Check if it has hive metadata (createdAt, etc.)
          if (value.containsKey('createdAt') || value.containsKey('name')) {
            isHive = true;
          }
          // Check if it's an empty hive (just an empty map)
          else if (value.isEmpty) {
            isHive = true;
          }
          // Check if it contains measurements or constants (existing hives)
          else if (value.containsKey('measurements') ||
              value.containsKey('constants')) {
            isHive = true;
          }

          if (isHive) {
            // Extract hive metadata if available
            final createdAt = value['createdAt'] != null
                ? DateTime.fromMillisecondsSinceEpoch(value['createdAt'] as int)
                : DateTime.now();

            final hive = Hive(
              id: key,
              name: key,
              apiaryId: apiaryId,
              userId: user.uid,
              createdAt: createdAt,
            );

            hives.add(hive);
          } else {}
        }
      }

      return hives;
    } catch (e) {
      return [];
    }
  }

  /// Fetches measurements for a specific hive using HierarchyContext
  Future<List<MeasurementData>> fetchHiveMeasurements(
      HierarchyContext context) async {
    if (!context.isComplete) {
      throw Exception(
          "Complete hierarchy context required (user, apiary, hive)");
    }

    try {
      // Use user-scoped path
      var measurementsPath = context.measurementsPath;
      var snapshot = await _databaseRef.child(measurementsPath).get();

      if (!snapshot.exists) {
        return [];
      }

      final rawData = (snapshot.value as Map).map(
        (key, value) => MapEntry(
          key.toString(),
          Map<String, dynamic>.from(value as Map),
        ),
      );

      final measurements = rawData.entries.map((entry) {
        return MeasurementData.fromJson(
          entry.key,
          entry.value,
          hiveId: context.selectedHiveId,
          apiaryId: context.selectedApiaryId,
        );
      }).toList();

      measurements.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return measurements;
    } catch (e) {
      return [];
    }
  }

  /// Fetches constants for a specific hive using HierarchyContext
  Future<HiveConstants?> fetchHiveConstants(HierarchyContext context) async {
    if (!context.isComplete) {
      throw Exception(
          "Complete hierarchy context required (user, apiary, hive)");
    }

    try {
      // Use user-scoped path
      var constantsPath = context.constantsPath;
      var snapshot = await _databaseRef.child(constantsPath).get();

      if (!snapshot.exists) {
        return null;
      }

      final data = Map<String, dynamic>.from(snapshot.value as Map);

      return HiveConstants.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Updates constants for a specific hive using HierarchyContext
  Future<void> updateHiveConstants(
      HierarchyContext context, HiveConstants constants) async {
    if (!context.isComplete) {
      throw Exception(
          "Complete hierarchy context required (user, apiary, hive)");
    }

    try {
      await _databaseRef.child(context.constantsPath).set(constants.toJson());
    } catch (e) {
      rethrow;
    }
  }

  /// Creates a new apiary for the current user
  Future<void> createApiary(Apiary apiary) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("No user is logged in");
    }

    try {
      await _databaseRef.child('${user.uid}/${apiary.id}').set(apiary.toJson());
    } catch (e) {
      rethrow;
    }
  }

  /// Creates a new hive in the specified apiary
  Future<void> createHive(String apiaryId, Hive hive) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("No user is logged in");
    }

    try {
      // Create the hive with its metadata
      await _databaseRef
          .child('${user.uid}/$apiaryId/${hive.id}')
          .set(hive.toJson());

      // Create empty measurements structure
      await _databaseRef
          .child('${user.uid}/$apiaryId/${hive.id}/measurements')
          .set({});

      // Create default constants structure
      final defaultConstants = {
        'humidity': 80.0, // Default humidity threshold
        'temperature': 30.0, // Default temperature threshold
        'notify': true, // Enable notifications by default
        'interval': 60000, // Default interval 60 seconds (in ms)
      };

      await _databaseRef
          .child('${user.uid}/$apiaryId/${hive.id}/constants')
          .set(defaultConstants);
    } catch (e) {
      rethrow;
    }
  }

  /// Creates a new hive with custom constants in the specified apiary
  Future<void> createHiveWithConstants(
      String apiaryId, Hive hive, Map<String, dynamic> constants) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("No user is logged in");
    }

    try {
      // Create the hive with its metadata
      await _databaseRef
          .child('${user.uid}/$apiaryId/${hive.id}')
          .set(hive.toJson());

      // Create empty measurements structure
      await _databaseRef
          .child('${user.uid}/$apiaryId/${hive.id}/measurements')
          .set({});

      // Create constants structure with user-provided values
      await _databaseRef
          .child('${user.uid}/$apiaryId/${hive.id}/constants')
          .set(constants);
    } catch (e) {
      rethrow;
    }
  }

  /// Updates an existing apiary
  Future<void> updateApiary(Apiary apiary) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("No user is logged in");
    }

    try {
      final updatedApiary = apiary.copyWith(updatedAt: DateTime.now());

      // If the name (which is also the ID/key) hasn't changed, just update metadata
      if (apiary.id == apiary.name) {
        await _databaseRef
            .child('${user.uid}/${apiary.id}')
            .update(updatedApiary.toJson());
      } else {
        // If the name has changed, we need to move the entire apiary structure
        // 1. Get all existing data from the old location
        final oldSnapshot =
            await _databaseRef.child('${user.uid}/${apiary.id}').get();

        if (oldSnapshot.exists) {
          final existingData = oldSnapshot.value as Map;

          // 2. Create the apiary data with updated metadata
          final newApiaryData = Map<String, dynamic>.from(existingData);
          newApiaryData.addAll(updatedApiary.toJson());

          // 3. Set the data at the new location (new name)
          await _databaseRef
              .child('${user.uid}/${apiary.name}')
              .set(newApiaryData);

          // 4. Remove the old location
          await _databaseRef.child('${user.uid}/${apiary.id}').remove();
        } else {
          // If old data doesn't exist, just create new
          await _databaseRef
              .child('${user.uid}/${apiary.name}')
              .set(updatedApiary.toJson());
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Deletes an apiary and all its hives
  Future<void> deleteApiary(String apiaryId) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("No user is logged in");
    }

    try {
      await _databaseRef.child('${user.uid}/$apiaryId').remove();
    } catch (e) {
      rethrow;
    }
  }

  /// Deletes a specific hive
  Future<void> deleteHive(String apiaryId, String hiveId) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("No user is logged in");
    }

    try {
      await _databaseRef.child('${user.uid}/$apiaryId/$hiveId').remove();
    } catch (e) {
      rethrow;
    }
  }
}
