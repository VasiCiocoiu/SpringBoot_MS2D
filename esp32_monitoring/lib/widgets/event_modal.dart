import 'package:flutter/material.dart';
import '../models/measurement_data.dart';

class EventModal extends StatelessWidget {
  final List<MeasurementData> events;

  const EventModal({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final recentEvents =
        events.reversed.take(20).toList(); // Limit to the last 20 events

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        height: MediaQuery.of(context).size.height *
            0.6, // Set modal height to 60% of the screen
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Liste des derniers événements",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: recentEvents.length,
                itemBuilder: (context, index) {
                  final event = recentEvents[index];
                  return ListTile(
                    title: Text(event.messageEvent ?? "Aucun message"),
                    subtitle: Text(event.timestamp.toString()),
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
