/// Parsing for the official API's compact timestamps and countdown labels.
library;

/// Parses "20261020T080000.000Z" (official API) as well as ISO-8601.
DateTime? parseApiTime(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final m = RegExp(r'^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})').firstMatch(raw);
  if (m != null) {
    int g(int i) => int.parse(m.group(i)!);
    return DateTime.utc(g(1), g(2), g(3), g(4), g(5), g(6));
  }
  return DateTime.tryParse(raw)?.toUtc();
}

/// Countdown text such as "2d 5h", "3h 12m", "8m" or "under 1m".
String countdown(Duration d) {
  if (d.isNegative || d.inMinutes < 1) return 'under 1m';
  final days = d.inDays, hours = d.inHours % 24, mins = d.inMinutes % 60;
  if (days > 0) return '${days}d ${hours}h';
  if (hours > 0) return '${hours}h ${mins}m';
  return '${mins}m';
}
