import 'phone_formatter.dart';

class PhoneUtils {
  /// Normalizes Kenyan phone numbers to 254XXXXXXXXX format using PhoneFormatter.
  static String normalize(String? phone) {
    if (phone == null || phone.isEmpty) return '';
    return PhoneFormatter.toInternational(phone);
  }
}
