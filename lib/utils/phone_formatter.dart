class PhoneFormatter {
  /// Cleans and formats Kenyan phone number for display (+254 7XX XXXXXX)
  static String formatForDisplay(String? phone) {
    if (phone == null || phone.isEmpty) return '—';

    String p = phone.trim().replaceAll('+', '').replaceAll(' ', '');

    // Normalize to 254 format first
    if (p.startsWith('0')) {
      p = '254${p.substring(1)}';
    } else if (p.startsWith('254')) {
      // already normalized
    } else if (p.length == 9 && (p.startsWith('7') || p.startsWith('1'))) {
      p = '254$p';
    }

    // Apply nice display format
    // Handles 2547... and 2541... (Kenyan 07... and 01... numbers)
    if (p.length == 12 && p.startsWith('254')) {
      return '+254 ${p.substring(3, 6)} ${p.substring(6)}';
    }

    return p.startsWith('+') ? p : '+$p';
  }

  /// Converts any Kenyan number to international format (2547...)
  static String toInternational(String phone) {
    String p = phone.trim().replaceAll('+', '').replaceAll(' ', '').replaceAll(RegExp(r'\D'), '');

    if (p.startsWith('0')) {
      return '254${p.substring(1)}';
    }

    if (p.startsWith('254')) {
      return p;
    }

    // Handle 9 digit inputs starting with 7 or 1
    if (p.length == 9 && (p.startsWith('7') || p.startsWith('1'))) {
      return '254$p';
    }

    return p;
  }

  /// For saving to database or sending to API (usually 2547...)
  static String toDatabaseFormat(String phone) {
    return toInternational(phone);
  }
}
