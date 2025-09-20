class Hive {
  final String id;
  final String name;
  final String apiaryId;
  final String userId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Hive({
    required this.id,
    required this.name,
    required this.apiaryId,
    required this.userId,
    required this.createdAt,
    this.updatedAt,
  });

  factory Hive.fromJson(
      String key, Map<String, dynamic> json, String apiaryId, String userId) {
    return Hive(
      id: key,
      name: key, // The key IS the hive name in Firebase structure
      apiaryId: apiaryId,
      userId: userId,
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  Hive copyWith({
    String? id,
    String? name,
    String? apiaryId,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Hive(
      id: id ?? this.id,
      name: name ?? this.name,
      apiaryId: apiaryId ?? this.apiaryId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get measurementsPath => '$userId/$apiaryId/$id/measurements';

  String get constantsPath => '$userId/$apiaryId/$id/constants';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Hive && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Hive{id: $id, name: $name, apiaryId: $apiaryId, userId: $userId}';
  }
}
