class Apiary {
  final String id;
  final String name;
  final String userId;
  final String description;
  final String address;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Apiary({
    required this.id,
    required this.name,
    required this.userId,
    required this.description,
    required this.address,
    required this.createdAt,
    this.updatedAt,
  });

  factory Apiary.fromJson(String key, Map<String, dynamic> json, String userId) {
    return Apiary(
      id: key,
      name: key, // The key IS the apiary name in Firebase structure
      userId: userId,
      description: json['description'] as String? ?? '',
      address: json['address'] as String? ?? '',
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
      'description': description,
      'address': address,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  Apiary copyWith({
    String? id,
    String? name,
    String? userId,
    String? description,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Apiary(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      description: description ?? this.description,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Apiary && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Apiary{id: $id, name: $name, userId: $userId, description: $description, address: $address}';
  }
}