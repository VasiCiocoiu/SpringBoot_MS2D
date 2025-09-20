class HiveConstants {
  final double humidity;
  final double temperature;
  final bool notify;
  final int interval;

  HiveConstants({
    required this.humidity,
    required this.temperature,
    required this.notify,
    required this.interval,
  });

  factory HiveConstants.fromJson(Map<String, dynamic> json) {
    return HiveConstants(
      humidity: (json['humidity'] as num?)?.toDouble() ?? 80.0,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 30.0,
      notify: json['notify'] as bool? ?? true,
      interval: json['interval'] as int? ?? 60000,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'humidity': humidity,
      'temperature': temperature,
      'notify': notify,
      'interval': interval,
    };
  }

  HiveConstants copyWith({
    double? humidity,
    double? temperature,
    bool? notify,
    int? interval,
  }) {
    return HiveConstants(
      humidity: humidity ?? this.humidity,
      temperature: temperature ?? this.temperature,
      notify: notify ?? this.notify,
      interval: interval ?? this.interval,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveConstants &&
          runtimeType == other.runtimeType &&
          humidity == other.humidity &&
          temperature == other.temperature &&
          notify == other.notify &&
          interval == other.interval;

  @override
  int get hashCode =>
      humidity.hashCode ^ temperature.hashCode ^ notify.hashCode ^ interval.hashCode;

  @override
  String toString() {
    return 'HiveConstants{humidity: $humidity, temperature: $temperature, notify: $notify, interval: $interval}';
  }
}