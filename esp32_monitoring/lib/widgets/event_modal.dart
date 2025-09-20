import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/measurement_data.dart';

class EventModal extends StatelessWidget {
  final List<MeasurementData> measurements;

  const EventModal({super.key, required this.measurements});

  /// Generates a descriptive message based on the event type and sensor data
  String _generateEventMessage(MeasurementData event) {
    switch (event.type) {
      case "temp_event":
        return "Alerte température : ${event.temperature?.toStringAsFixed(1) ?? 'N/A'}°C détectée";

      case "hum_event":
        return "Alerte humidité : ${event.humidity?.toStringAsFixed(1) ?? 'N/A'}% détectée";

      case "both_event":
        return "Alerte double : Température ${event.temperature?.toStringAsFixed(1) ?? 'N/A'}°C et humidité ${event.humidity?.toStringAsFixed(1) ?? 'N/A'}% dépassées";

      case "cover_opened":
        return "Ouverture de la ruche";

      default:
        return "Événement ${event.type} détecté";
    }
  }

  /// Returns an icon based on the event type
  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case "temp_event":
        return Icons.thermostat;
      case "hum_event":
        return Icons.water_drop;
      case "both_event":
        return Icons.warning;
      case "cover_opened":
        return Icons.home_outlined;
      default:
        return Icons.notification_important;
    }
  }

  /// Returns a color based on the event severity
  Color _getEventColor(String eventType) {
    switch (eventType) {
      case "temp_event":
        return Colors.orange;
      case "hum_event":
        return Colors.blue;
      case "both_event":
        return Colors.red;
      case "cover_opened":
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter to only show events (non-data measurements)
    final events = measurements.where((m) => m.isEventType).toList();
    final recentEvents = events.reversed.take(20).toList(); // Last 20 events

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event_note, size: 24),
                const SizedBox(width: 8),
                const Text(
                  "Événements récents",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "${recentEvents.length} événement(s) sur ${events.length} total",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 16),
            if (recentEvents.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.green.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Aucun événement récent",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Toutes les mesures sont dans les seuils normaux",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: recentEvents.length,
                  itemBuilder: (context, index) {
                    final event = recentEvents[index];
                    final eventColor = _getEventColor(event.type);
                    final eventIcon = _getEventIcon(event.type);
                    final message = _generateEventMessage(event);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: eventColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            eventIcon,
                            color: eventColor,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          message,
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: event.hasValidSensorData
                            ? Text(
                                "T: ${event.temperature?.toStringAsFixed(1)}°C | H: ${event.humidity?.toStringAsFixed(1)}%",
                                style: Theme.of(context).textTheme.bodySmall,
                              )
                            : null,
                        trailing: Text(
                          DateFormat('dd/MM HH:mm').format(event.timestamp),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
