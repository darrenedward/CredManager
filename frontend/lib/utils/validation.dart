bool validatePassphrase(String passphrase) {
  return passphrase.length >= 12 && RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(passphrase);
}

String? validatePassphraseError(String passphrase) {
  if (passphrase.isEmpty) return 'Passphrase is required';
  if (passphrase.length < 12) return 'Passphrase must be at least 12 characters long';
  if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(passphrase)) {
    return 'Passphrase must contain uppercase, lowercase, and number';
  }
  return null;
}

bool validateAnswer(String answer) {
  return answer.isNotEmpty && answer.trim().length >= 3;
}

String? validateAnswerError(String answer) {
  if (answer.isEmpty) return 'Answer is required';
  if (answer.trim().length < 3) return 'Answer must be at least 3 characters';
  return null;
}

// Case-insensitive answer validation for recovery
bool validateAnswerCaseInsensitive(String answer, String expectedAnswer) {
  return answer.trim().toLowerCase() == expectedAnswer.trim().toLowerCase();
}

bool validateConfirmPassphrase(String passphrase, String confirm) {
  return passphrase == confirm;
}

String? validateConfirmPassphraseError(String passphrase, String confirm) {
  if (passphrase != confirm) return 'Passphrases do not match';
  return null;
}