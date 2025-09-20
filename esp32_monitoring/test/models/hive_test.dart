import 'package:flutter_test/flutter_test.dart';
import 'package:esp32monitoring/models/hive.dart';

void main() {
  group('Hive Model Tests', () {
    test('should create Hive from JSON correctly', () {
      // Arrange
      final json = {
        'createdAt': 1640995200000, // 2022-01-01 10:00:00 UTC in milliseconds
        'updatedAt': 1641081600000, // 2022-01-02 10:00:00 UTC in milliseconds
      };

      // Act
      final hive = Hive.fromJson('Test Hive', json, 'apiary123', 'user123');

      // Assert
      expect(hive.id, equals('Test Hive'));
      expect(hive.name, equals('Test Hive'));
      expect(hive.apiaryId, equals('apiary123'));
      expect(hive.userId, equals('user123'));
      expect(hive.createdAt.millisecondsSinceEpoch, equals(1640995200000));
      expect(hive.updatedAt?.millisecondsSinceEpoch, equals(1641081600000));
    });

    test('should create Hive with default values when JSON is incomplete', () {
      // Arrange
      final json = <String, dynamic>{};

      // Act
      final hive = Hive.fromJson('Test Hive', json, 'apiary123', 'user123');

      // Assert
      expect(hive.id, equals('Test Hive'));
      expect(hive.name, equals('Test Hive'));
      expect(hive.apiaryId, equals('apiary123'));
      expect(hive.userId, equals('user123'));
      expect(hive.createdAt, isA<DateTime>());
      expect(hive.updatedAt, isA<DateTime>());
    });

    test('should convert Hive to JSON correctly', () {
      // Arrange
      final createdAt = DateTime.fromMillisecondsSinceEpoch(1640995200000);
      final updatedAt = DateTime.fromMillisecondsSinceEpoch(1641081600000);
      final hive = Hive(
        id: 'test-id',
        name: 'Test Hive',
        apiaryId: 'apiary123',
        userId: 'user123',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      // Act
      final json = hive.toJson();

      // Assert
      expect(json['createdAt'], equals(1640995200000));
      expect(json['updatedAt'], equals(1641081600000));
    });

    test('should create new Hive with updated name using copyWith', () {
      // Arrange
      final original = Hive(
        id: 'test-id',
        name: 'Original Name',
        apiaryId: 'apiary123',
        userId: 'user123',
        createdAt: DateTime.now(),
      );

      // Act
      final updated = original.copyWith(name: 'Updated Name');

      // Assert
      expect(updated.name, equals('Updated Name'));
      expect(updated.apiaryId, equals('apiary123'));
      expect(updated.userId, equals('user123'));
      expect(updated.createdAt, equals(original.createdAt));
    });

    test('should not modify original when using copyWith', () {
      // Arrange
      final original = Hive(
        id: 'test-id',
        name: 'Original Name',
        apiaryId: 'apiary123',
        userId: 'user123',
        createdAt: DateTime.now(),
      );

      // Act
      final updated = original.copyWith(apiaryId: 'newApiaryId');

      // Assert
      expect(original.name, equals('Original Name'));
      expect(original.apiaryId, equals('apiary123'));
      expect(updated.apiaryId, equals('newApiaryId'));
    });

    test('should correctly implement equality', () {
      // Arrange
      final hive1 = Hive(
        id: 'test-id',
        name: 'Test Hive',
        apiaryId: 'apiary123',
        userId: 'user123',
        createdAt: DateTime.now(),
      );

      final hive2 = Hive(
        id: 'test-id',
        name: 'Different Name',
        apiaryId: 'different-apiary',
        userId: 'user456',
        createdAt: DateTime.now(),
      );

      final hive3 = Hive(
        id: 'different-id',
        name: 'Test Hive',
        apiaryId: 'apiary123',
        userId: 'user123',
        createdAt: DateTime.now(),
      );

      // Assert
      expect(hive1, equals(hive2)); // Same ID
      expect(hive1, isNot(equals(hive3))); // Different ID
      expect(hive1.hashCode, equals(hive2.hashCode));
      expect(hive1.hashCode, isNot(equals(hive3.hashCode)));
    });
  });
}
