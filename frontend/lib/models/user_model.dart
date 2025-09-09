class User {
  final String? id;
  final String? passphraseHash; // Never store plain passphrase
  final List<Map<String, String>> securityQuestions; // List of {'question': String, 'answerHash': String}
  final bool isFirstTime;

  User({
    this.id,
    this.passphraseHash,
    this.securityQuestions = const [],
    this.isFirstTime = true,
  });

  // Factory constructor from JSON (for API responses)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      passphraseHash: json['passphraseHash'], // Should not be sent over wire
      securityQuestions: List<Map<String, String>>.from(
        json['securityQuestions'] ?? []
      ),
      isFirstTime: json['isFirstTime'] ?? true,
    );
  }

  // toJson for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'passphraseHash': passphraseHash,
      'securityQuestions': securityQuestions,
      'isFirstTime': isFirstTime,
    };
  }

  // CopyWith for immutable updates
  User copyWith({
    String? id,
    String? passphraseHash,
    List<Map<String, String>>? securityQuestions,
    bool? isFirstTime,
  }) {
    return User(
      id: id ?? this.id,
      passphraseHash: passphraseHash ?? this.passphraseHash,
      securityQuestions: securityQuestions ?? this.securityQuestions,
      isFirstTime: isFirstTime ?? this.isFirstTime,
    );
  }
}