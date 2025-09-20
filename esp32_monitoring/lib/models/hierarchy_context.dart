import 'apiary.dart';
import 'hive.dart';

class HierarchyContext {
  final String userId;
  final String? selectedApiaryId;
  final String? selectedHiveId;
  final Apiary? selectedApiary;
  final Hive? selectedHive;

  HierarchyContext({
    required this.userId,
    this.selectedApiaryId,
    this.selectedHiveId,
    this.selectedApiary,
    this.selectedHive,
  });

  bool get hasSelectedApiary => selectedApiaryId != null;

  bool get hasSelectedHive => selectedHiveId != null;

  bool get isComplete => hasSelectedApiary && hasSelectedHive;

  String get measurementsPath {
    if (!isComplete) {
      throw StateError('Cannot generate path without complete hierarchy selection');
    }
    return '$userId/$selectedApiaryId/$selectedHiveId/measurements';
  }

  String get constantsPath {
    if (!isComplete) {
      throw StateError('Cannot generate path without complete hierarchy selection');
    }
    return '$userId/$selectedApiaryId/$selectedHiveId/constants';
  }

  String get userRootPath => userId;

  String get selectedApiaryPath {
    if (!hasSelectedApiary) {
      throw StateError('Cannot generate apiary path without selected apiary');
    }
    return '$userId/$selectedApiaryId';
  }

  String get selectedHivePath {
    if (!isComplete) {
      throw StateError('Cannot generate hive path without complete hierarchy selection');
    }
    return '$userId/$selectedApiaryId/$selectedHiveId';
  }

  HierarchyContext copyWith({
    String? userId,
    String? selectedApiaryId,
    String? selectedHiveId,
    Apiary? selectedApiary,
    Hive? selectedHive,
  }) {
    return HierarchyContext(
      userId: userId ?? this.userId,
      selectedApiaryId: selectedApiaryId ?? this.selectedApiaryId,
      selectedHiveId: selectedHiveId ?? this.selectedHiveId,
      selectedApiary: selectedApiary ?? this.selectedApiary,
      selectedHive: selectedHive ?? this.selectedHive,
    );
  }

  HierarchyContext selectApiary(Apiary apiary) {
    return copyWith(
      selectedApiaryId: apiary.id,
      selectedApiary: apiary,
      selectedHiveId: null,
      selectedHive: null,
    );
  }

  HierarchyContext selectHive(Hive hive) {
    return copyWith(
      selectedHiveId: hive.id,
      selectedHive: hive,
    );
  }

  HierarchyContext clearSelection() {
    return HierarchyContext(userId: userId);
  }

  HierarchyContext clearHiveSelection() {
    return copyWith(
      selectedHiveId: null,
      selectedHive: null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HierarchyContext &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          selectedApiaryId == other.selectedApiaryId &&
          selectedHiveId == other.selectedHiveId;

  @override
  int get hashCode =>
      userId.hashCode ^ selectedApiaryId.hashCode ^ selectedHiveId.hashCode;

  @override
  String toString() {
    return 'HierarchyContext{userId: $userId, selectedApiaryId: $selectedApiaryId, selectedHiveId: $selectedHiveId}';
  }
}