import 'dart:convert';

/// Represents a password vault (container for password entries)
class PasswordVault {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PasswordEntry> entries;

  PasswordVault({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    required this.createdAt,
    required this.updatedAt,
    this.entries = const [],
  });

  /// Create a PasswordVault from a map (database row)
  factory PasswordVault.fromMap(Map<String, dynamic> map, {List<PasswordEntry>? entries}) {
    return PasswordVault(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      icon: map['icon'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      entries: entries ?? const [],
    );
  }

  /// Convert to a map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Create a copy with updated fields
  PasswordVault copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<PasswordEntry>? entries,
  }) {
    return PasswordVault(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      entries: entries ?? this.entries,
    );
  }

  /// Convert to JSON
  String toJson() => jsonEncode(toMap());

  /// Create from JSON
  factory PasswordVault.fromJson(String json) {
    return PasswordVault.fromMap(jsonDecode(json) as Map<String, dynamic>);
  }

  /// Get entry count
  int get entryCount => entries.length;

  @override
  String toString() {
    return 'PasswordVault(id: $id, name: $name, entries: ${entries.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PasswordVault && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Represents an individual password entry
class PasswordEntry {
  final String id;
  final String vaultId;
  final String name;
  final String value; // decrypted value; stored encrypted in database
  final String? username;
  final String? email;
  final String? url;
  final String? notes;
  final String? tags; // comma-separated tags
  final DateTime createdAt;
  final DateTime updatedAt;

  PasswordEntry({
    required this.id,
    required this.vaultId,
    required this.name,
    required this.value,
    this.username,
    this.email,
    this.url,
    this.notes,
    this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a PasswordEntry from a map (database row)
  factory PasswordEntry.fromMap(Map<String, dynamic> map) {
    return PasswordEntry(
      id: map['id'] as String,
      vaultId: map['vault_id'] as String,
      name: map['name'] as String,
      value: map['value'] as String? ?? '', // Should be decrypted before creating; default to empty if missing
      username: map['username'] as String?,
      email: map['email'] as String?,
      url: map['url'] as String?,
      notes: map['notes'] as String?,
      tags: map['tags'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  /// Convert to a map for database storage (value should be encrypted separately)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vault_id': vaultId,
      'name': name,
      'username': username,
      'email': email,
      'url': url,
      'notes': notes,
      'tags': tags,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Create a copy with updated fields
  PasswordEntry copyWith({
    String? id,
    String? vaultId,
    String? name,
    String? value,
    String? username,
    String? email,
    String? url,
    String? notes,
    String? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PasswordEntry(
      id: id ?? this.id,
      vaultId: vaultId ?? this.vaultId,
      name: name ?? this.name,
      value: value ?? this.value,
      username: username ?? this.username,
      email: email ?? this.email,
      url: url ?? this.url,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Parse tags into a list
  List<String> get tagList {
    if (tags == null || tags!.isEmpty) return [];
    return tags!.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
  }

  /// Convert tag list to comma-separated string
  static String? tagsToString(List<String>? tags) {
    if (tags == null || tags.isEmpty) return null;
    return tags.join(',');
  }

  /// Convert to JSON
  String toJson() => jsonEncode(toMap());

  /// Create from JSON
  factory PasswordEntry.fromJson(String json) {
    return PasswordEntry.fromMap(jsonDecode(json) as Map<String, dynamic>);
  }

  @override
  String toString() {
    return 'PasswordEntry(id: $id, name: $name, username: $username)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PasswordEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
