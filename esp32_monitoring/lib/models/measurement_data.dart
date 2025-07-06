import 'package:intl/intl.dart';

class MeasurementData {
  final DateTime timestamp;
  final double? humidity;
  final double? temperature;
  final String? messageEvent;
  final String type;

  MeasurementData({
    required this.timestamp,
    this.humidity,
    this.temperature,
    this.messageEvent,
    required this.type,
  });

  factory MeasurementData.fromJson(String key, Map<String, dynamic> json) {
    // Parse the timestamp in the format DD-MM-YYYY_HH:MM
    final dateTime = DateFormat('dd-MM-yyyy_HH:mm').parse(key);
    return MeasurementData(
      timestamp: dateTime,
      humidity: (json['data_package']?['humidity'] as num?)?.toDouble(),
      temperature: (json['data_package']?['temperature'] as num?)?.toDouble(),
      messageEvent: json['message_event'] as String?,
      type: json['type'] as String? ?? "data",
    );
  }
}
