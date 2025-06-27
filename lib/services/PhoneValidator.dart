class PhoneValidator {
  static String? validatePhoneNumber(String? value) {
    if (value == null || value
        .trim()
        .isEmpty) {
      return 'Please enter a phone number';
    }

    final input = value.trim();

    // Check for invalid characters (only digits, spaces, and + at the start allowed)
    if (!RegExp(r'^\+?[0-9\s]+$').hasMatch(input)) {
      return 'Phone number contains invalid characters';
    }

    // Remove all spaces and normalize
    String cleaned = input.replaceAll(RegExp(r'\s+'), '');

    // Normalize Egyptian numbers to local format
    if (cleaned.startsWith('+20')) {
      cleaned = '0' + cleaned.substring(3);
    } else if (cleaned.startsWith('0020')) {
      cleaned = '0' + cleaned.substring(4);
    } else if (cleaned.startsWith('20')) {
      cleaned = '0' + cleaned.substring(2);
    }

    // Accept Egyptian format (01xxxxxxxxx)
    if (RegExp(r'^01[0-9]{9}$').hasMatch(cleaned)) {
      return null; // Valid Egyptian number
    }

    // Accept international numbers starting with +
    if (RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(value.replaceAll(' ', ''))) {
      return null; // Valid international number
    }

    return 'Enter a valid phone number';
  }
}