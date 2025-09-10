class AiService {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AiServiceKey> keys;

  AiService({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.keys = const [],
  });

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Create from database Map
  factory AiService.fromMap(Map<String, dynamic> map, {List<AiServiceKey>? keys}) {
    return AiService(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      keys: keys ?? [],
    );
  }

  // Create copy with updated fields
  AiService copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<AiServiceKey>? keys,
  }) {
    return AiService(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      keys: keys ?? this.keys,
    );
  }

  // Convert to JSON for export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'keys': keys.map((k) => k.toJson()).toList(),
    };
  }

  // Create from JSON for import
  factory AiService.fromJson(Map<String, dynamic> json) {
    return AiService(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      keys: (json['keys'] as List<dynamic>?)
          ?.map((k) => AiServiceKey.fromJson(k as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  @override
  String toString() {
    return 'AiService{id: $id, name: $name, keys: ${keys.length}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AiService && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class AiServiceKey {
  final String id;
  final String serviceId;
  final String name;
  final String value; // This will be encrypted in storage
  final AiKeyType type;
  final DateTime createdAt;
  final DateTime updatedAt;

  AiServiceKey({
    required this.id,
    required this.serviceId,
    required this.name,
    required this.value,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to Map for database storage (value will be encrypted)
  Map<String, dynamic> toMap({String? encryptedValue}) {
    return {
      'id': id,
      'service_id': serviceId,
      'name': name,
      'encrypted_value': encryptedValue ?? value, // Use encrypted value if provided
      'key_type': type.name,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Create from database Map (value will be decrypted)
  factory AiServiceKey.fromMap(Map<String, dynamic> map, {String? decryptedValue}) {
    return AiServiceKey(
      id: map['id'] as String,
      serviceId: map['service_id'] as String,
      name: map['name'] as String,
      value: decryptedValue ?? map['encrypted_value'] as String, // Use decrypted value if provided
      type: AiKeyType.fromString(map['key_type'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  // Create copy with updated fields
  AiServiceKey copyWith({
    String? id,
    String? serviceId,
    String? name,
    String? value,
    AiKeyType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AiServiceKey(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      name: name ?? this.name,
      value: value ?? this.value,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to JSON for export (value will be encrypted)
  Map<String, dynamic> toJson({bool includeValue = false}) {
    return {
      'id': id,
      'service_id': serviceId,
      'name': name,
      if (includeValue) 'value': value, // Only include if explicitly requested
      'type': type.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create from JSON for import
  factory AiServiceKey.fromJson(Map<String, dynamic> json) {
    return AiServiceKey(
      id: json['id'] as String,
      serviceId: json['service_id'] as String,
      name: json['name'] as String,
      value: json['value'] as String? ?? '', // Handle missing value
      type: AiKeyType.fromString(json['type'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  String toString() {
    return 'AiServiceKey{id: $id, name: $name, type: ${type.name}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AiServiceKey && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum AiKeyType {
  apiKey('api_key'),
  token('token'),
  secret('secret'),
  other('other');

  const AiKeyType(this.value);
  final String value;

  String get name => value;

  static AiKeyType fromString(String value) {
    return AiKeyType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => AiKeyType.other,
    );
  }

  String get displayName {
    switch (this) {
      case AiKeyType.apiKey:
        return 'API Key';
      case AiKeyType.token:
        return 'Token';
      case AiKeyType.secret:
        return 'Secret';
      case AiKeyType.other:
        return 'Other';
    }
  }
}
