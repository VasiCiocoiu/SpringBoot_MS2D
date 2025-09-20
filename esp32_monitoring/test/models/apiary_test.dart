import 'package:flutter_test/flutter_test.dart';
import 'package:esp32monitoring/models/apiary.dart';

void main() {
  group('Apiary Model Tests', () {
    test('should create Apiary from JSON correctly', () {
      // Arrange
      final json = {
        'description': 'Test description',
        'address': 'Test address',
        'createdAt': 1640995200000, // 2022-01-01 10:00:00 UTC in milliseconds
        'updatedAt': 1641081600000, // 2022-01-02 10:00:00 UTC in milliseconds
      };

      // Act
      final apiary = Apiary.fromJson('Test Apiary', json, 'user123');

      // Assert
      expect(apiary.id, equals('Test Apiary'));
      expect(apiary.name, equals('Test Apiary'));
      expect(apiary.userId, equals('user123'));
      expect(apiary.description, equals('Test description'));
      expect(apiary.address, equals('Test address'));
      expect(apiary.createdAt.millisecondsSinceEpoch, equals(1640995200000));
      expect(apiary.updatedAt?.millisecondsSinceEpoch, equals(1641081600000));
    });

    test('should create Apiary with default values when JSON is incomplete',
        () {
      // Arrange
      final json = <String, dynamic>{};

      // Act
      final apiary = Apiary.fromJson('Test Apiary', json, 'user123');

      // Assert
      expect(apiary.id, equals('Test Apiary'));
      expect(apiary.name, equals('Test Apiary'));
      expect(apiary.userId, equals('user123'));
      expect(apiary.description, isEmpty);
      expect(apiary.address, isEmpty);
      expect(apiary.createdAt, isA<DateTime>());
      expect(apiary.updatedAt, isA<DateTime>());
    });

    test('should convert Apiary to JSON correctly', () {
      // Arrange
      final createdAt = DateTime.fromMillisecondsSinceEpoch(1640995200000);
      final updatedAt = DateTime.fromMillisecondsSinceEpoch(1641081600000);
      final apiary = Apiary(
        id: 'test-id',
        name: 'Test Apiary',
        userId: 'user123',
        description: 'Test description',
        address: 'Test address',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      // Act
      final json = apiary.toJson();

      // Assert
      expect(json['description'], equals('Test description'));
      expect(json['address'], equals('Test address'));
      expect(json['createdAt'], equals(1640995200000));
      expect(json['updatedAt'], equals(1641081600000));
    });

    test('should create new Apiary with updated name using copyWith', () {
      // Arrange
      final original = Apiary(
        id: 'test-id',
        name: 'Original Name',
        userId: 'user123',
        description: 'Test description',
        address: 'Test address',
        createdAt: DateTime.now(),
      );

      // Act
      final updated = original.copyWith(name: 'Updated Name');

      // Assert
      expect(updated.name, equals('Updated Name'));
      expect(updated.description, equals('Test description'));
      expect(updated.address, equals('Test address'));
      expect(updated.createdAt, equals(original.createdAt));
      expect(updated.userId, equals(original.userId));
    });

    test('should not modify original when using copyWith', () {
      // Arrange
      final original = Apiary(
        id: 'test-id',
        name: 'Original Name',
        userId: 'user123',
        description: 'Test description',
        address: 'Test address',
        createdAt: DateTime.now(),
      );

      // Act
      final updated = original.copyWith(description: 'New description');

      // Assert
      expect(original.name, equals('Original Name'));
      expect(original.description, equals('Test description'));
      expect(updated.description, equals('New description'));
    });

    test('should correctly implement equality', () {
      // Arrange
      final apiary1 = Apiary(
        id: 'test-id',
        name: 'Test Apiary',
        userId: 'user123',
        description: 'Description',
        address: 'Address',
        createdAt: DateTime.now(),
      );

      final apiary2 = Apiary(
        id: 'test-id',
        name: 'Different Name',
        userId: 'user456',
        description: 'Different Description',
        address: 'Different Address',
        createdAt: DateTime.now(),
      );

      final apiary3 = Apiary(
        id: 'different-id',
        name: 'Test Apiary',
        userId: 'user123',
        description: 'Description',
        address: 'Address',
        createdAt: DateTime.now(),
      );

      // Assert
      expect(apiary1, equals(apiary2)); // Same ID
      expect(apiary1, isNot(equals(apiary3))); // Different ID
      expect(apiary1.hashCode, equals(apiary2.hashCode));
      expect(apiary1.hashCode, isNot(equals(apiary3.hashCode)));
    });
  });
}
