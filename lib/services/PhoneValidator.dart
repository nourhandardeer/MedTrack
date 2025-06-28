class PhoneValidator {
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a phone number';
    }

    final input = value.trim();

    // Allow only digits, spaces, and an optional leading +
    if (!RegExp(r'^\+?[0-9\s]+$').hasMatch(input)) {
      return 'Phone number contains invalid characters';
    }

    final normalized = normalizePhone(input);

    // Egyptian format (01xxxxxxxxx)
    if (RegExp(r'^01[0-9]{9}$').hasMatch(normalized)) {
      return null;
    }

    // International format (+XXXXXXXX...)
    if (RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(input.replaceAll(' ', ''))) {
      return null;
    }

    return 'Enter a valid phone number';
  }

  static String normalizePhone(String input) {
    String cleaned = input.replaceAll(RegExp(r'\s+'), '');

    // Normalize Egyptian formats to local
    if (cleaned.startsWith('+20')) {
      cleaned = '0' + cleaned.substring(3);
    } else if (cleaned.startsWith('0020')) {
      cleaned = '0' + cleaned.substring(4);
    } else if (cleaned.startsWith('20')) {
      cleaned = '0' + cleaned.substring(2);
    }

    return cleaned;
  }
}
