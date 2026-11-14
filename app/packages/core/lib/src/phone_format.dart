/// Shows a Korean mobile/landline number as 010-1234-5678. Non-digits are dropped first, so a
/// typed or stored value formats the same way. Partial input formats as far as it can.
String formatKoreanPhone(String raw) {
  final d = raw.replaceAll(RegExp(r'\D'), '');
  if (d.length < 4) return d;
  if (d.length < 8) return '${d.substring(0, 3)}-${d.substring(3)}';
  final mid = d.length == 11 ? 7 : 6;
  return '${d.substring(0, 3)}-${d.substring(3, mid)}-${d.substring(mid)}';
}
