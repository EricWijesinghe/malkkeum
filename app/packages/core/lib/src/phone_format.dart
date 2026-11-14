/// Shows a Korean phone number in its usual grouping: 010-1234-5678 (mobile, 11 digits),
/// 02-1234-5678 (Seoul, 2-digit area code) or 031-123-4567 (other landlines, 10 digits).
/// A +82 prefix is converted to the domestic form. Anything else is returned unchanged so no
/// digits are ever lost.
String formatPhone(String raw) {
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('82') && (digits.length == 11 || digits.length == 12)) {
    digits = '0${digits.substring(2)}';
  }
  final grouped = _group(digits, digits.startsWith('02') ? 2 : 3);
  return grouped ?? raw;
}

/// Groups [digits] as area-code-middle-last with an [areaLen]-digit area code. Returns null for
/// lengths that are not a 9-11 digit number.
String? _group(String digits, int areaLen) {
  final n = digits.length;
  if (n < 9 || n > 11) return null;
  final midLen = n <= 10 ? (n - areaLen) ~/ 2 : n - areaLen - 4;
  final mid = areaLen + midLen;
  return '${digits.substring(0, areaLen)}-${digits.substring(areaLen, mid)}-${digits.substring(mid)}';
}
