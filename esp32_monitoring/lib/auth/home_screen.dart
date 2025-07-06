import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../models/measurement_data.dart';
import '../widgets/graph_widget.dart';
import '../widgets/threshold_modal.dart';
import '../widgets/event_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<MeasurementData> _measurements = [];
  bool _isLoading = true;

  // Initial Y-axis ranges for humidity and temperature
  double _humidityMinY = 0;
  double _humidityMaxY = 100;
  double _temperatureMinY = -10;
  double _temperatureMaxY = 60;

  // Limits for the number of data points to display
  int _humidityLimit = 10;
  int _temperatureLimit = 10;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final data = await _firebaseService.fetchMeasurements();
    setState(() {
      _measurements = data;
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  void _showThresholdModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return ThresholdModal(firebaseService: _firebaseService);
      },
    );
  }

  void _showEventsModal(BuildContext context, List<MeasurementData> events) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow the modal to expand based on content
      builder: (BuildContext context) {
        return EventModal(events: events); // Use the new EventModal
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String uid = user?.uid ?? "Aucun ID utilisateur";

    final events = _measurements.where((m) => m.type == "event").toList();
    final humidityData = _measurements
        .where((m) => m.humidity != null)
        .toList()
        .reversed
        .take(_humidityLimit)
        .toList()
        .reversed
        .toList();

    final temperatureData = _measurements
        .where((m) => m.temperature != null)
        .toList()
        .reversed
        .take(_temperatureLimit)
        .toList()
        .reversed
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Accueil"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Recharger les données",
            onPressed: () async {
              setState(() {
                _isLoading = true; // Show loading indicator while fetching data
              });
              await _fetchData(); // Reload data
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: "Modifier les seuils",
            onPressed: () => _showThresholdModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.notification_important),
            tooltip: "Voir les événements",
            onPressed: () => _showEventsModal(context, events),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Se déconnecter",
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      "ID : $uid",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ExpansionTile(
                    title: const Text("Options humidité"),
                    children: [
                      const Text(
                        "Ajuster la plage d'humidité",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      RangeSlider(
                        values: RangeValues(_humidityMinY, _humidityMaxY),
                        min: 0,
                        max: 100,
                        divisions: 10,
                        labels: RangeLabels(
                          _humidityMinY.toInt().toString(),
                          _humidityMaxY.toInt().toString(),
                        ),
                        onChanged: (values) {
                          setState(() {
                            _humidityMinY = values.start;
                            _humidityMaxY = values.end;
                          });
                        },
                      ),
                      const Text(
                        "Limiter les points de données",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      DropdownButton<int>(
                        value: _humidityLimit,
                        items: [10, 20, 50, 100]
                            .map((limit) => DropdownMenuItem<int>(
                                  value: limit,
                                  child: Text("$limit points"),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _humidityLimit = value!;
                          });
                        },
                      ),
                    ],
                  ),
                  GraphWidget(
                    data: humidityData,
                    title: "Humidité",
                    yAxisLabel: "Humidité (%)",
                    valueSelector: (m) => m.humidity,
                    minY: _humidityMinY, // Dynamic humidity range
                    maxY: _humidityMaxY,
                  ),
                  ExpansionTile(
                    title: const Text("Options température"),
                    children: [
                      const Text(
                        "Ajuster la plage de température",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      RangeSlider(
                        values: RangeValues(_temperatureMinY, _temperatureMaxY),
                        min: -10,
                        max: 60,
                        divisions: 10,
                        labels: RangeLabels(
                          _temperatureMinY.toInt().toString(),
                          _temperatureMaxY.toInt().toString(),
                        ),
                        onChanged: (values) {
                          setState(() {
                            _temperatureMinY = values.start;
                            _temperatureMaxY = values.end;
                          });
                        },
                      ),
                      const Text(
                        "Limiter les points de données",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      DropdownButton<int>(
                        value: _temperatureLimit,
                        items: [10, 20, 50, 100]
                            .map((limit) => DropdownMenuItem<int>(
                                  value: limit,
                                  child: Text("$limit points"),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _temperatureLimit = value!;
                          });
                        },
                      ),
                    ],
                  ),
                  GraphWidget(
                    data: temperatureData,
                    title: "Température",
                    yAxisLabel: "Température (°C)",
                    valueSelector: (m) => m.temperature,
                    minY: _temperatureMinY, // Dynamic temperature range
                    maxY: _temperatureMaxY,
                  ),
                ],
              ),
            ),
    );
  }
}
