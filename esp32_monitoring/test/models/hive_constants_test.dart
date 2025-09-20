import 'package:flutter_test/flutter_test.dart';
import 'package:esp32monitoring/models/hive_constants.dart';

void main() {
  group('HiveConstants Model Tests', () {
    test('should create HiveConstants from JSON correctly', () {
      // Arrange
      final json = {
        'humidity': 75.5,
        'temperature': 28.0,
        'notify': false,
        'interval': 30000,
      };

      // Act
      final constants = HiveConstants.fromJson(json);

      // Assert
      expect(constants.humidity, equals(75.5));
      expect(constants.temperature, equals(28.0));
      expect(constants.notify, isFalse);
      expect(constants.interval, equals(30000));
    });

    test(
        'should create HiveConstants with default values when JSON is incomplete',
        () {
      // Arrange
      final json = <String, dynamic>{};

      // Act
      final constants = HiveConstants.fromJson(json);

      // Assert
      expect(constants.humidity, equals(80.0));
      expect(constants.temperature, equals(30.0));
      expect(constants.notify, isTrue);
      expect(constants.interval, equals(60000));
    });

    test('should create HiveConstants with partial JSON data', () {
      // Arrange
      final json = {
        'humidity': 65.0,
        'notify': false,
      };

      // Act
      final constants = HiveConstants.fromJson(json);

      // Assert
      expect(constants.humidity, equals(65.0));
      expect(constants.temperature, equals(30.0)); // Default
      expect(constants.notify, isFalse);
      expect(constants.interval, equals(60000)); // Default
    });

    test('should convert HiveConstants to JSON correctly', () {
      // Arrange
      final constants = HiveConstants(
        humidity: 70.0,
        temperature: 25.5,
        notify: true,
        interval: 45000,
      );

      // Act
      final json = constants.toJson();

      // Assert
      expect(json['humidity'], equals(70.0));
      expect(json['temperature'], equals(25.5));
      expect(json['notify'], isTrue);
      expect(json['interval'], equals(45000));
    });

    test('should create copy with updated values using copyWith', () {
      // Arrange
      final original = HiveConstants(
        humidity: 70.0,
        temperature: 25.0,
        notify: true,
        interval: 60000,
      );

      // Act
      final updated = original.copyWith(
        humidity: 75.0,
        notify: false,
      );

      // Assert
      expect(updated.humidity, equals(75.0));
      expect(updated.temperature, equals(25.0)); // Unchanged
      expect(updated.notify, isFalse);
      expect(updated.interval, equals(60000)); // Unchanged
    });

    test('should not modify original when using copyWith', () {
      // Arrange
      final original = HiveConstants(
        humidity: 70.0,
        temperature: 25.0,
        notify: true,
        interval: 60000,
      );

      // Act
      final updated = original.copyWith(humidity: 75.0);

      // Assert
      expect(original.humidity, equals(70.0));
      expect(updated.humidity, equals(75.0));
    });

    test('should correctly implement equality', () {
      // Arrange
      final constants1 = HiveConstants(
        humidity: 70.0,
        temperature: 25.0,
        notify: true,
        interval: 60000,
      );

      final constants2 = HiveConstants(
        humidity: 70.0,
        temperature: 25.0,
        notify: true,
        interval: 60000,
      );

      final constants3 = HiveConstants(
        humidity: 75.0,
        temperature: 25.0,
        notify: true,
        interval: 60000,
      );

      // Assert
      expect(constants1, equals(constants2));
      expect(constants1, isNot(equals(constants3)));
      expect(constants1.hashCode, equals(constants2.hashCode));
      expect(constants1.hashCode, isNot(equals(constants3.hashCode)));
    });

    test('should handle integer and double conversions correctly', () {
      // Arrange
      final json = {
        'humidity': 70, // int
        'temperature': 25.5, // double
        'notify': true,
        'interval': 60000,
      };

      // Act
      final constants = HiveConstants.fromJson(json);

      // Assert
      expect(constants.humidity, equals(70.0));
      expect(constants.temperature, equals(25.5));
      expect(constants.humidity, isA<double>());
      expect(constants.temperature, isA<double>());
    });

    test('should validate reasonable threshold values', () {
      // Arrange & Act
      final constants = HiveConstants(
        humidity: 85.0,
        temperature: 35.0,
        notify: true,
        interval: 30000,
      );

      // Assert - These are reasonable values for beehive monitoring
      expect(constants.humidity, greaterThan(0.0));
      expect(constants.humidity, lessThanOrEqualTo(100.0));
      expect(constants.temperature, greaterThan(-50.0));
      expect(constants.temperature, lessThan(100.0));
      expect(constants.interval, greaterThan(0));
    });
  });
}
