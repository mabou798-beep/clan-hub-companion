/// On-device habits: favourite units and the daily challenge streak.
/// Nothing here leaves the device.
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "2026-10-24" in the player's local time; the daily challenge resets at
/// local midnight.
String dayKey([DateTime? at]) {
  final d = (at ?? DateTime.now()).toLocal();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Stable integer for a day, used to seed the daily picks.
int daySeed([DateTime? at]) {
  final d = (at ?? DateTime.now()).toLocal();
  return d.year * 10000 + d.month * 100 + d.day;
}

class EngagementStore extends ChangeNotifier {
  static const _favKey = 'favourites';
  static const _lastDayKey = 'daily_last_day';
  static const _scoreKey = 'daily_last_score';
  static const _streakKey = 'daily_streak';
  static const _bestStreakKey = 'daily_best_streak';

  SharedPreferences? _prefs;
  Set<String> favourites = {};
  String? lastDailyDay;
  int lastDailyScore = 0;
  int streak = 0;
  int bestStreak = 0;

  Future<void> restore() async {
    final p = _prefs = await SharedPreferences.getInstance();
    favourites = (p.getStringList(_favKey) ?? const []).toSet();
    lastDailyDay = p.getString(_lastDayKey);
    lastDailyScore = p.getInt(_scoreKey) ?? 0;
    streak = p.getInt(_streakKey) ?? 0;
    bestStreak = p.getInt(_bestStreakKey) ?? 0;
    notifyListeners();
  }

  /// Favourites are stored as "kind:id" so equal names in different
  /// villages stay distinct.
  bool isFavourite(String id) => favourites.contains(id);

  void toggleFavourite(String id) {
    favourites.contains(id) ? favourites.remove(id) : favourites.add(id);
    _prefs?.setStringList(_favKey, favourites.toList());
    notifyListeners();
  }

  bool get playedToday => lastDailyDay == dayKey();

  /// Streak shown to the player: still alive if they played today or
  /// yesterday.
  int get liveStreak {
    final last = lastDailyDay;
    if (last == null) return 0;
    final yesterday = dayKey(DateTime.now().subtract(const Duration(days: 1)));
    return last == dayKey() || last == yesterday ? streak : 0;
  }

  void completeDaily(int score) {
    final today = dayKey();
    if (lastDailyDay == today) return;
    final yesterday = dayKey(DateTime.now().subtract(const Duration(days: 1)));
    streak = lastDailyDay == yesterday ? streak + 1 : 1;
    if (streak > bestStreak) bestStreak = streak;
    lastDailyDay = today;
    lastDailyScore = score;
    final p = _prefs;
    if (p != null) {
      p.setString(_lastDayKey, today);
      p.setInt(_scoreKey, score);
      p.setInt(_streakKey, streak);
      p.setInt(_bestStreakKey, bestStreak);
    }
    notifyListeners();
  }
}
