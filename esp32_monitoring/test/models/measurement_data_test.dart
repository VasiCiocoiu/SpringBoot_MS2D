import 'package:flutter_test/flutter_test.dart';
import 'package:esp32monitoring/models/measurement_data.dart';

void main() {
  group('MeasurementData Model Tests', () {
    test('should create MeasurementData from JSON with sensor data correctly',
        () {
      // Arrange
      final json = {
        'data_package': {
          'humidity': 65.5,
          'temperature': 25.3,
        },
        'type': 'data',
      };

      // Act
      final measurement = MeasurementData.fromJson(
        '01-01-2024_10:30',
        json,
        hiveId: 'hive123',
        apiaryId: 'apiary123',
      );

      // Assert
      expect(measurement.humidity, equals(65.5));
      expect(measurement.temperature, equals(25.3));
      expect(measurement.type, equals('data'));
      expect(measurement.hiveId, equals('hive123'));
      expect(measurement.apiaryId, equals('apiary123'));
      expect(measurement.timestamp.day, equals(1));
      expect(measurement.timestamp.month, equals(1));
      expect(measurement.timestamp.year, equals(2024));
      expect(measurement.timestamp.hour, equals(10));
      expect(measurement.timestamp.minute, equals(30));
    });

    test('should create MeasurementData with event type correctly', () {
      // Arrange
      final json = {
        'message_event': 'Temperature threshold exceeded',
        'type': 'temp_event',
      };

      // Act
      final measurement = MeasurementData.fromJson(
        '15-06-2024_14:45',
        json,
        hiveId: 'hive123',
        apiaryId: 'apiary123',
      );

      // Assert
      expect(
          measurement.messageEvent, equals('Temperature threshold exceeded'));
      expect(measurement.type, equals('temp_event'));
      expect(measurement.humidity, isNull);
      expect(measurement.temperature, isNull);
    });

    test('should default to data type when type is missing', () {
      // Arrange
      final json = {
        'data_package': {
          'humidity': 60.0,
          'temperature': 23.0,
        },
      };

      // Act
      final measurement = MeasurementData.fromJson('01-01-2024_12:00', json);

      // Assert
      expect(measurement.type, equals('data'));
    });

    test('should correctly identify event types', () {
      // Arrange
      final dataType = MeasurementData(
        timestamp: DateTime.now(),
        type: 'data',
        humidity: 60.0,
        temperature: 23.0,
      );

      final tempEvent = MeasurementData(
        timestamp: DateTime.now(),
        type: 'temp_event',
      );

      final humEvent = MeasurementData(
        timestamp: DateTime.now(),
        type: 'hum_event',
      );

      final bothEvent = MeasurementData(
        timestamp: DateTime.now(),
        type: 'both_event',
      );

      final coverEvent = MeasurementData(
        timestamp: DateTime.now(),
        type: 'cover_opened',
      );

      // Assert
      expect(dataType.isEventType, isFalse);
      expect(tempEvent.isEventType, isTrue);
      expect(humEvent.isEventType, isTrue);
      expect(bothEvent.isEventType, isTrue);
      expect(coverEvent.isEventType, isTrue);

      expect(tempEvent.isTemperatureEvent, isTrue);
      expect(humEvent.isTemperatureEvent, isFalse);
      expect(bothEvent.isTemperatureEvent, isTrue);

      expect(tempEvent.isHumidityEvent, isFalse);
      expect(humEvent.isHumidityEvent, isTrue);
      expect(bothEvent.isHumidityEvent, isTrue);

      expect(coverEvent.isCoverEvent, isTrue);
      expect(tempEvent.isCoverEvent, isFalse);
    });

    test('should correctly identify valid sensor data', () {
      // Arrange
      final withData = MeasurementData(
        timestamp: DateTime.now(),
        type: 'data',
        humidity: 60.0,
        temperature: 23.0,
      );

      final withoutData = MeasurementData(
        timestamp: DateTime.now(),
        type: 'temp_event',
      );

      final partialData = MeasurementData(
        timestamp: DateTime.now(),
        type: 'data',
        humidity: 60.0,
      );

      // Assert
      expect(withData.hasValidSensorData, isTrue);
      expect(withoutData.hasValidSensorData, isFalse);
      expect(partialData.hasValidSensorData, isFalse);
    });

    test('should create copy with updated values using copyWith', () {
      // Arrange
      final original = MeasurementData(
        timestamp: DateTime.now(),
        type: 'data',
        humidity: 60.0,
        temperature: 23.0,
        hiveId: 'hive123',
      );

      // Act
      final updated = original.copyWith(
        humidity: 65.0,
        temperature: 25.0,
      );

      // Assert
      expect(updated.humidity, equals(65.0));
      expect(updated.temperature, equals(25.0));
      expect(updated.timestamp, equals(original.timestamp));
      expect(updated.type, equals(original.type));
      expect(updated.hiveId, equals(original.hiveId));
    });

    test('should not modify original when using copyWith', () {
      // Arrange
      final original = MeasurementData(
        timestamp: DateTime.now(),
        type: 'data',
        humidity: 60.0,
        temperature: 23.0,
      );

      // Act
      final updated = original.copyWith(humidity: 65.0);

      // Assert
      expect(original.humidity, equals(60.0));
      expect(updated.humidity, equals(65.0));
    });

    test('should handle complex timestamp parsing correctly', () {
      // Arrange
      final testCases = [
        '01-01-2024_00:00',
        '31-12-2024_23:59',
        '15-06-2024_12:30',
        '29-02-2024_06:15', // Leap year
      ];

      for (final testCase in testCases) {
        // Act
        final measurement =
            MeasurementData.fromJson(testCase, {'type': 'data'});

        // Assert
        expect(measurement.timestamp, isA<DateTime>());
        // Verify the parsing worked by converting back
        final parts = testCase.split('_');
        final datePart = parts[0].split('-');
        final timePart = parts[1].split(':');

        expect(measurement.timestamp.day, equals(int.parse(datePart[0])));
        expect(measurement.timestamp.month, equals(int.parse(datePart[1])));
        expect(measurement.timestamp.year, equals(int.parse(datePart[2])));
        expect(measurement.timestamp.hour, equals(int.parse(timePart[0])));
        expect(measurement.timestamp.minute, equals(int.parse(timePart[1])));
      }
    });
  });
}
