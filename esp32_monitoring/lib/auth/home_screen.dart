import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../services/firebase_service.dart';
import '../models/measurement_data.dart';
import '../models/hive_constants.dart';
import '../widgets/graph_widget.dart';
import '../widgets/event_modal.dart';
import '../providers/hierarchy_provider.dart';
import '../models/hierarchy_context.dart' as hierarchy_context;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
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

  /// Calculate the actual data bounds for humidity
  (double min, double max) _getHumidityDataBounds() {
    final humidityValues = _measurements
        .where((m) => m.humidity != null)
        .map((m) => m.humidity!)
        .toList();

    if (humidityValues.isEmpty) return (0.0, 100.0);

    final min = humidityValues.reduce((a, b) => a < b ? a : b);
    final max = humidityValues.reduce((a, b) => a > b ? a : b);

    // Return actual data bounds without margin for limit calculations
    return (min, max);
  }

  /// Calculate the actual data bounds for temperature
  (double min, double max) _getTemperatureDataBounds() {
    final temperatureValues = _measurements
        .where((m) => m.temperature != null)
        .map((m) => m.temperature!)
        .toList();

    if (temperatureValues.isEmpty) return (-10.0, 60.0);

    final min = temperatureValues.reduce((a, b) => a < b ? a : b);
    final max = temperatureValues.reduce((a, b) => a > b ? a : b);

    // Return actual data bounds without margin for limit calculations
    return (min, max);
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final hierarchyProvider = context.read<HierarchyProvider>();
    if (!hierarchyProvider.isComplete) {
      setState(() {
        _measurements = [];
        _isLoading = false;
      });
      return;
    }

    try {
      final data = await _firebaseService
          .fetchHiveMeasurements(hierarchyProvider.context);
      setState(() {
        _measurements = data;
        _isLoading = false;
      });
    } catch (e) {
      // Error handling - measurement fetch failed
      setState(() {
        _measurements = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    // Clear the hierarchy provider state
    if (mounted) {
      final hierarchyProvider = context.read<HierarchyProvider>();
      hierarchyProvider.clearSelection();

      // Navigate to login and clear all navigation history
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/', // This will go back to the AuthWrapper which will show LoginScreen
        (route) => false, // Remove all previous routes
      );
    }
  }

  void _showThresholdModal(BuildContext context) {
    final hierarchyProvider = context.read<HierarchyProvider>();
    if (!hierarchyProvider.isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune ruche sélectionnée')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return HierarchicalThresholdModal(
          firebaseService: _firebaseService,
          context: hierarchyProvider.context,
        );
      },
    );
  }

  void _showEventsModal(BuildContext context, List<MeasurementData> events) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow the modal to expand based on content
      builder: (BuildContext context) {
        return EventModal(measurements: events); // Use the new EventModal
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HierarchyProvider>(
      builder: (context, hierarchyProvider, child) {
        if (!hierarchyProvider.isComplete) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Erreur"),
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Aucune ruche sélectionnée',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Veuillez sélectionner un rucher et une ruche'),
                ],
              ),
            ),
          );
        }

        final selectedApiary = hierarchyProvider.selectedApiary!;
        final selectedHive = hierarchyProvider.selectedHive!;
        final events = _measurements.where((m) => m.isEventType).toList();
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
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(selectedHive.name),
                Text(
                  selectedApiary.name,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.normal),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: "Recharger les données",
                onPressed: () async {
                  setState(() {
                    _isLoading = true;
                  });
                  await _fetchData();
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
                      ExpansionTile(
                        title: const Text("Options humidité"),
                        children: [
                          const Text(
                            "Ajuster la plage d'humidité",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: RangeSlider(
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
                                  final (dataMin, dataMax) =
                                      _getHumidityDataBounds();
                                  // Allow some margin around data points (5 units)
                                  final margin = 5.0;

                                  // Constrain minY: can't be higher than (dataMin - margin)
                                  // This prevents pushing data off the top of the graph
                                  final maxAllowedMinY =
                                      math.max(0.0, dataMin - margin);
                                  _humidityMinY =
                                      math.min(values.start, maxAllowedMinY);

                                  // Constrain maxY: can't be lower than (dataMax + margin)
                                  // This prevents pushing data off the bottom of the graph
                                  final minAllowedMaxY =
                                      math.min(100.0, dataMax + margin);
                                  _humidityMaxY =
                                      math.max(values.end, minAllowedMaxY);

                                  // Ensure values stay within slider bounds
                                  _humidityMinY = math.max(
                                      0.0, math.min(100.0, _humidityMinY));
                                  _humidityMaxY = math.max(
                                      0.0, math.min(100.0, _humidityMaxY));
                                });
                              },
                            ),
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
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: RangeSlider(
                              values: RangeValues(
                                  _temperatureMinY, _temperatureMaxY),
                              min: -10,
                              max: 60,
                              divisions: 10,
                              labels: RangeLabels(
                                _temperatureMinY.toInt().toString(),
                                _temperatureMaxY.toInt().toString(),
                              ),
                              onChanged: (values) {
                                setState(() {
                                  final (dataMin, dataMax) =
                                      _getTemperatureDataBounds();
                                  // Allow some margin around data points (3 degrees)
                                  final margin = 3.0;

                                  // Constrain minY: can't be higher than (dataMin - margin)
                                  // This prevents pushing data off the top of the graph
                                  final maxAllowedMinY =
                                      math.max(-10.0, dataMin - margin);
                                  _temperatureMinY =
                                      math.min(values.start, maxAllowedMinY);

                                  // Constrain maxY: can't be lower than (dataMax + margin)
                                  // This prevents pushing data off the bottom of the graph
                                  final minAllowedMaxY =
                                      math.min(60.0, dataMax + margin);
                                  _temperatureMaxY =
                                      math.max(values.end, minAllowedMaxY);

                                  // Ensure values stay within slider bounds
                                  _temperatureMinY = math.max(
                                      -10.0, math.min(60.0, _temperatureMinY));
                                  _temperatureMaxY = math.max(
                                      -10.0, math.min(60.0, _temperatureMaxY));
                                });
                              },
                            ),
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
      },
    );
  }
}

// Hierarchical Threshold Modal that uses HierarchyContext
class HierarchicalThresholdModal extends StatefulWidget {
  final FirebaseService firebaseService;
  final hierarchy_context.HierarchyContext context;

  const HierarchicalThresholdModal({
    super.key,
    required this.firebaseService,
    required this.context,
  });

  @override
  State<HierarchicalThresholdModal> createState() =>
      _HierarchicalThresholdModalState();
}

class _HierarchicalThresholdModalState
    extends State<HierarchicalThresholdModal> {
  final _formKey = GlobalKey<FormState>();
  double _humidity = 80;
  double _temperature = 30;
  bool _notify = true;
  int _interval = 60000;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentConstants();
  }

  Future<void> _loadCurrentConstants() async {
    try {
      final constants =
          await widget.firebaseService.fetchHiveConstants(widget.context);
      if (constants != null && mounted) {
        setState(() {
          _humidity = constants.humidity;
          _temperature = constants.temperature;
          _notify = constants.notify;
          _interval = constants.interval;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Paramètres de la ruche',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const CircularProgressIndicator()
          else
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    initialValue: _humidity.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Seuil d\'humidité (%)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Requis';
                      final parsed = double.tryParse(value);
                      if (parsed == null || parsed < 0 || parsed > 100) {
                        return 'Valeur entre 0 et 100';
                      }
                      return null;
                    },
                    onSaved: (value) => _humidity = double.parse(value!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _temperature.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Seuil de température (°C)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Requis';
                      final parsed = double.tryParse(value);
                      if (parsed == null) return 'Nombre invalide';
                      return null;
                    },
                    onSaved: (value) => _temperature = double.parse(value!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: (_interval / 1000).toString(),
                    decoration: const InputDecoration(
                      labelText: 'Intervalle de mesure (secondes)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Requis';
                      final parsed = int.tryParse(value);
                      if (parsed == null || parsed < 10) {
                        return 'Minimum 10 secondes';
                      }
                      return null;
                    },
                    onSaved: (value) => _interval = int.parse(value!) * 1000,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Notifications activées'),
                    value: _notify,
                    onChanged: (value) => setState(() => _notify = value),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuler'),
                      ),
                      ElevatedButton(
                        onPressed: _saveConstants,
                        child: const Text('Enregistrer'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _saveConstants() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final constants = HiveConstants(
        humidity: _humidity,
        temperature: _temperature,
        notify: _notify,
        interval: _interval,
      );

      try {
        await widget.firebaseService
            .updateHiveConstants(widget.context, constants);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paramètres enregistrés')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }
}
