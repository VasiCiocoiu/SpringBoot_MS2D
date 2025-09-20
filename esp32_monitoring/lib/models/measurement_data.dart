import 'package:intl/intl.dart';

class MeasurementData {
  final DateTime timestamp;
  final double? humidity;
  final double? temperature;
  final String? messageEvent;
  final String type;
  final String? hiveId;
  final String? apiaryId;

  MeasurementData({
    required this.timestamp,
    this.humidity,
    this.temperature,
    this.messageEvent,
    required this.type,
    this.hiveId,
    this.apiaryId,
  });

  factory MeasurementData.fromJson(String key, Map<String, dynamic> json, {String? hiveId, String? apiaryId}) {
    // Parse the timestamp in the format DD-MM-YYYY_HH:MM
    final dateTime = DateFormat('dd-MM-yyyy_HH:mm').parse(key);
    return MeasurementData(
      timestamp: dateTime,
      humidity: (json['data_package']?['humidity'] as num?)?.toDouble(),
      temperature: (json['data_package']?['temperature'] as num?)?.toDouble(),
      messageEvent: json['message_event'] as String?,
      type: json['type'] as String? ?? "data",
      hiveId: hiveId,
      apiaryId: apiaryId,
    );
  }

  bool get isEventType => type != "data";

  bool get isTemperatureEvent => type == "temp_event" || type == "both_event";

  bool get isHumidityEvent => type == "hum_event" || type == "both_event";

  bool get isCoverEvent => type == "cover_opened";

  bool get hasValidSensorData => humidity != null && temperature != null;

  MeasurementData copyWith({
    DateTime? timestamp,
    double? humidity,
    double? temperature,
    String? messageEvent,
    String? type,
    String? hiveId,
    String? apiaryId,
  }) {
    return MeasurementData(
      timestamp: timestamp ?? this.timestamp,
      humidity: humidity ?? this.humidity,
      temperature: temperature ?? this.temperature,
      messageEvent: messageEvent ?? this.messageEvent,
      type: type ?? this.type,
      hiveId: hiveId ?? this.hiveId,
      apiaryId: apiaryId ?? this.apiaryId,
    );
  }

  @override
  String toString() {
    return 'MeasurementData{timestamp: $timestamp, humidity: $humidity, temperature: $temperature, type: $type, hiveId: $hiveId, apiaryId: $apiaryId}';
  }
}
