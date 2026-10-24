/// Small text helpers shared across sources and screens.
library;

/// Lowercase letters and digits only. Used to match the same entity across
/// sources that spell it differently ("P.E.K.K.A" vs "pekka").
String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

/// 1234567 -> "1,234,567".
String groupDigits(num n) {
  final s = n.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0 && s[i - 1] != '-') b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// 1234567 -> "1.2M", 45000 -> "45K".
String compact(num n) {
  if (n >= 1000000) return '${_trim(n / 1000000)}M';
  if (n >= 10000) return '${_trim(n / 1000)}K';
  return groupDigits(n);
}

String _trim(num v) {
  final s = v.toStringAsFixed(v >= 100 ? 0 : 1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

/// Seconds -> "3d 4h", "5h 20m", "45m", "0".
String durationLabel(int seconds) {
  if (seconds <= 0) return 'Instant';
  final d = seconds ~/ 86400, h = (seconds % 86400) ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  if (d > 0) return h > 0 ? '${d}d ${h}h' : '${d}d';
  if (h > 0) return m > 0 ? '${h}h ${m}m' : '${h}h';
  return '${m}m';
}
