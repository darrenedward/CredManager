class Project {
  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Credential> credentials;

  Project({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.credentials = const [],
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
  factory Project.fromMap(Map<String, dynamic> map, {List<Credential>? credentials}) {
    return Project(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      credentials: credentials ?? [],
    );
  }

  // Create copy with updated fields
  Project copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Credential>? credentials,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      credentials: credentials ?? this.credentials,
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
      'credentials': credentials.map((c) => c.toJson()).toList(),
    };
  }

  // Create from JSON for import
  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      credentials: (json['credentials'] as List<dynamic>?)
          ?.map((c) => Credential.fromJson(c as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  @override
  String toString() {
    return 'Project{id: $id, name: $name, credentials: ${credentials.length}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Project && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class Credential {
  final String id;
  final String projectId;
  final String name;
  final String value; // This will be encrypted in storage
  final CredentialType type;
  final DateTime createdAt;
  final DateTime updatedAt;

  Credential({
    required this.id,
    required this.projectId,
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
      'project_id': projectId,
      'name': name,
      'encrypted_value': encryptedValue ?? value, // Use encrypted value if provided
      'credential_type': type.name,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Create from database Map (value will be decrypted)
  factory Credential.fromMap(Map<String, dynamic> map, {String? decryptedValue}) {
    return Credential(
      id: map['id'] as String,
      projectId: map['project_id'] as String,
      name: map['name'] as String,
      value: decryptedValue ?? map['encrypted_value'] as String, // Use decrypted value if provided
      type: CredentialType.fromString(map['credential_type'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  // Create copy with updated fields
  Credential copyWith({
    String? id,
    String? projectId,
    String? name,
    String? value,
    CredentialType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Credential(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
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
      'project_id': projectId,
      'name': name,
      if (includeValue) 'value': value, // Only include if explicitly requested
      'type': type.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create from JSON for import
  factory Credential.fromJson(Map<String, dynamic> json) {
    return Credential(
      id: json['id'] as String,
      projectId: json['project_id'] as String,
      name: json['name'] as String,
      value: json['value'] as String? ?? '', // Handle missing value
      type: CredentialType.fromString(json['type'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  String toString() {
    return 'Credential{id: $id, name: $name, type: ${type.name}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Credential && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum CredentialType {
  apiKey('api_key'),
  password('password'),
  connectionString('connection_string'),
  url('url'),
  token('token'),
  certificate('certificate'),
  other('other');

  const CredentialType(this.value);
  final String value;

  String get name => value;

  static CredentialType fromString(String value) {
    return CredentialType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => CredentialType.other,
    );
  }

  String get displayName {
    switch (this) {
      case CredentialType.apiKey:
        return 'API Key';
      case CredentialType.password:
        return 'Password';
      case CredentialType.connectionString:
        return 'Connection String';
      case CredentialType.url:
        return 'URL';
      case CredentialType.token:
        return 'Token';
      case CredentialType.certificate:
        return 'Certificate';
      case CredentialType.other:
        return 'Other';
    }
  }
}
