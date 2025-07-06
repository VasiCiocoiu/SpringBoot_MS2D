import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class ThresholdModal extends StatefulWidget {
  final FirebaseService firebaseService;

  const ThresholdModal({super.key, required this.firebaseService});

  @override
  _ThresholdModalState createState() => _ThresholdModalState();
}

class _ThresholdModalState extends State<ThresholdModal> {
  final TextEditingController _humidityController = TextEditingController();
  final TextEditingController _temperatureController = TextEditingController();
  final TextEditingController _intervalController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThresholds();
  }

  Future<void> _loadThresholds() async {
    try {
      final thresholds = await widget.firebaseService.fetchThresholds();
      if (thresholds != null) {
        _humidityController.text = thresholds['humidity'].toString();
        _temperatureController.text = thresholds['temperature'].toString();
        _intervalController.text = (thresholds['interval'] / 60000)
            .toStringAsFixed(1); // Convert ms to minutes
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors du chargement des seuils.")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Modifier les seuils",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _humidityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Seuil d'humidité (%)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _temperatureController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Seuil de température (°C)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _intervalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Intervalle d'enregistrement (minutes)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final double? humidityThreshold =
                        double.tryParse(_humidityController.text);
                    final double? temperatureThreshold =
                        double.tryParse(_temperatureController.text);
                    final double? intervalMinutes =
                        double.tryParse(_intervalController.text);

                    if (humidityThreshold != null &&
                        temperatureThreshold != null &&
                        intervalMinutes != null) {
                      final int intervalMs = (intervalMinutes * 60000).toInt();
                      if (intervalMs < 6000) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                "L'intervalle doit être d'au moins 6 secondes (0.1 minute)."),
                          ),
                        );
                        return;
                      }

                      await widget.firebaseService.updateThresholdsAndInterval(
                        humidityThreshold,
                        temperatureThreshold,
                        intervalMs,
                      );

                      Navigator.pop(context); // Close the modal
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              "Seuils et intervalle mis à jour avec succès !"),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Veuillez entrer des valeurs valides."),
                        ),
                      );
                    }
                  },
                  child: const Text("Enregistrer"),
                ),
              ],
            ),
    );
  }
}
