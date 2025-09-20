import 'package:flutter_test/flutter_test.dart';
import 'package:esp32monitoring/models/hierarchy_context.dart';
import 'package:esp32monitoring/models/apiary.dart';
import 'package:esp32monitoring/models/hive.dart';

void main() {
  group('HierarchyContext Model Tests', () {
    final testApiary = Apiary(
      id: 'test-apiary',
      name: 'Test Apiary',
      userId: 'user123',
      description: 'Test description',
      address: 'Test address',
      createdAt: DateTime.now(),
    );

    final testHive = Hive(
      id: 'test-hive',
      name: 'Test Hive',
      apiaryId: 'test-apiary',
      userId: 'user123',
      createdAt: DateTime.now(),
    );

    test('should create HierarchyContext with user only', () {
      // Act
      final context = HierarchyContext(userId: 'user123');

      // Assert
      expect(context.userId, equals('user123'));
      expect(context.selectedApiaryId, isNull);
      expect(context.selectedHiveId, isNull);
      expect(context.selectedApiary, isNull);
      expect(context.selectedHive, isNull);
      expect(context.hasSelectedApiary, isFalse);
      expect(context.hasSelectedHive, isFalse);
      expect(context.isComplete, isFalse);
    });

    test('should create HierarchyContext with apiary selected', () {
      // Act
      final context = HierarchyContext(
        userId: 'user123',
        selectedApiaryId: 'test-apiary',
        selectedApiary: testApiary,
      );

      // Assert
      expect(context.hasSelectedApiary, isTrue);
      expect(context.hasSelectedHive, isFalse);
      expect(context.isComplete, isFalse);
      expect(context.selectedApiary, equals(testApiary));
    });

    test('should create complete HierarchyContext', () {
      // Act
      final context = HierarchyContext(
        userId: 'user123',
        selectedApiaryId: 'test-apiary',
        selectedHiveId: 'test-hive',
        selectedApiary: testApiary,
        selectedHive: testHive,
      );

      // Assert
      expect(context.hasSelectedApiary, isTrue);
      expect(context.hasSelectedHive, isTrue);
      expect(context.isComplete, isTrue);
    });

    test('should generate correct user root path', () {
      // Arrange
      final context = HierarchyContext(userId: 'user123');

      // Act & Assert
      expect(context.userRootPath, equals('user123'));
    });

    test('should generate correct apiary path when apiary is selected', () {
      // Arrange
      final context = HierarchyContext(
        userId: 'user123',
        selectedApiaryId: 'test-apiary',
      );

      // Act & Assert
      expect(context.selectedApiaryPath, equals('user123/test-apiary'));
    });

    test(
        'should throw StateError when generating apiary path without selection',
        () {
      // Arrange
      final context = HierarchyContext(userId: 'user123');

      // Act & Assert
      expect(
        () => context.selectedApiaryPath,
        throwsA(isA<StateError>()),
      );
    });

    test('should generate correct hive path when complete', () {
      // Arrange
      final context = HierarchyContext(
        userId: 'user123',
        selectedApiaryId: 'test-apiary',
        selectedHiveId: 'test-hive',
      );

      // Act & Assert
      expect(context.selectedHivePath, equals('user123/test-apiary/test-hive'));
    });

    test('should throw StateError when generating hive path incomplete', () {
      // Arrange
      final context = HierarchyContext(
        userId: 'user123',
        selectedApiaryId: 'test-apiary',
      );

      // Act & Assert
      expect(
        () => context.selectedHivePath,
        throwsA(isA<StateError>()),
      );
    });

    test('should generate correct measurements path when complete', () {
      // Arrange
      final context = HierarchyContext(
        userId: 'user123',
        selectedApiaryId: 'test-apiary',
        selectedHiveId: 'test-hive',
      );

      // Act & Assert
      expect(
        context.measurementsPath,
        equals('user123/test-apiary/test-hive/measurements'),
      );
    });

    test('should throw StateError when generating measurements path incomplete',
        () {
      // Arrange
      final context = HierarchyContext(
        userId: 'user123',
        selectedApiaryId: 'test-apiary',
      );

      // Act & Assert
      expect(
        () => context.measurementsPath,
        throwsA(isA<StateError>()),
      );
    });

    test('should generate correct constants path when complete', () {
      // Arrange
      final context = HierarchyContext(
        userId: 'user123',
        selectedApiaryId: 'test-apiary',
        selectedHiveId: 'test-hive',
      );

      // Act & Assert
      expect(
        context.constantsPath,
        equals('user123/test-apiary/test-hive/constants'),
      );
    });

    test('should throw StateError when generating constants path incomplete',
        () {
      // Arrange
      final context = HierarchyContext(
        userId: 'user123',
        selectedApiaryId: 'test-apiary',
      );

      // Act & Assert
      expect(
        () => context.constantsPath,
        throwsA(isA<StateError>()),
      );
    });

    test('should create copy with updated apiary using copyWith', () {
      // Arrange
      final original = HierarchyContext(userId: 'user123');

      // Act
      final updated = original.copyWith(
        selectedApiaryId: 'new-apiary',
        selectedApiary: testApiary,
      );

      // Assert
      expect(updated.userId, equals('user123'));
      expect(updated.selectedApiaryId, equals('new-apiary'));
      expect(updated.selectedApiary, equals(testApiary));
      expect(updated.selectedHiveId, isNull);
      expect(updated.selectedHive, isNull);
    });

    test('should clear hive selection when apiary changes using selectApiary',
        () {
      // Arrange
      final original = HierarchyContext(
        userId: 'user123',
        selectedApiaryId: 'old-apiary',
        selectedHiveId: 'old-hive',
        selectedApiary: testApiary,
        selectedHive: testHive,
      );

      final newApiary = Apiary(
        id: 'new-apiary',
        name: 'New Apiary',
        userId: 'user123',
        description: 'New description',
        address: 'New address',
        createdAt: DateTime.now(),
      );

      // Act
      final updated = original.selectApiary(newApiary);

      // Assert
      expect(updated.selectedApiaryId, equals('new-apiary'));
      expect(updated.selectedApiary, equals(newApiary));
      expect(updated.selectedHiveId, isNull);
      expect(updated.selectedHive, isNull);
    });

    test('should preserve apiary when updating hive using copyWith', () {
      // Arrange
      final original = HierarchyContext(
        userId: 'user123',
        selectedApiaryId: 'test-apiary',
        selectedApiary: testApiary,
      );

      // Act
      final updated = original.copyWith(
        selectedHiveId: 'test-hive',
        selectedHive: testHive,
      );

      // Assert
      expect(updated.selectedApiaryId, equals('test-apiary'));
      expect(updated.selectedApiary, equals(testApiary));
      expect(updated.selectedHiveId, equals('test-hive'));
      expect(updated.selectedHive, equals(testHive));
    });

    test('should not modify original when using copyWith', () {
      // Arrange
      final original = HierarchyContext(userId: 'user123');

      // Act
      final updated = original.copyWith(selectedApiaryId: 'new-apiary');

      // Assert
      expect(original.selectedApiaryId, isNull);
      expect(updated.selectedApiaryId, equals('new-apiary'));
    });

    test('should use selectHive method correctly', () {
      // Arrange
      final context = HierarchyContext(
        userId: 'user123',
        selectedApiaryId: 'test-apiary',
        selectedApiary: testApiary,
      );

      // Act
      final updated = context.selectHive(testHive);

      // Assert
      expect(updated.selectedHiveId, equals('test-hive'));
      expect(updated.selectedHive, equals(testHive));
      expect(updated.selectedApiaryId, equals('test-apiary')); // Preserved
      expect(updated.selectedApiary, equals(testApiary)); // Preserved
    });

    test('should use clearSelection method correctly', () {
      // Arrange
      final context = HierarchyContext(
        userId: 'user123',
        selectedApiaryId: 'test-apiary',
        selectedHiveId: 'test-hive',
        selectedApiary: testApiary,
        selectedHive: testHive,
      );

      // Act
      final cleared = context.clearSelection();

      // Assert
      expect(cleared.userId, equals('user123'));
      expect(cleared.selectedApiaryId, isNull);
      expect(cleared.selectedHiveId, isNull);
      expect(cleared.selectedApiary, isNull);
      expect(cleared.selectedHive, isNull);
    });

    test('should use clearHiveSelection method correctly', () {
      // Arrange
      final context = HierarchyContext(
        userId: 'user123',
        selectedApiaryId: 'test-apiary',
        selectedHiveId: 'test-hive',
        selectedApiary: testApiary,
        selectedHive: testHive,
      );

      // Act
      final updated = context.clearHiveSelection();

      // Assert
      expect(updated.selectedApiaryId, equals('test-apiary')); // Preserved
      expect(updated.selectedApiary, equals(testApiary)); // Preserved
      expect(updated.selectedHiveId, isNull);
      expect(updated.selectedHive, isNull);
    });

    test('should implement equality correctly', () {
      // Arrange
      final context1 = HierarchyContext(
        userId: 'user123',
        selectedApiaryId: 'test-apiary',
        selectedHiveId: 'test-hive',
      );

      final context2 = HierarchyContext(
        userId: 'user123',
        selectedApiaryId: 'test-apiary',
        selectedHiveId: 'test-hive',
      );

      final context3 = HierarchyContext(
        userId: 'user123',
        selectedApiaryId: 'different-apiary',
        selectedHiveId: 'test-hive',
      );

      // Assert
      expect(context1, equals(context2));
      expect(context1, isNot(equals(context3)));
      expect(context1.hashCode, equals(context2.hashCode));
      expect(context1.hashCode, isNot(equals(context3.hashCode)));
    });
  });
}
