/// Shows a Korean mobile or landline number as 010-1234-5678 (11 digits) or 02-123-4567 style
/// (10 digits). Anything else is returned unchanged so no digits are ever lost.
String formatPhone(String raw) {
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('82') && digits.length == 12)
    digits = '0${digits.substring(2)}';
  if (digits.length == 11) {
    return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
  }
  if (digits.length == 10) {
    return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
  }
  return raw;
}
