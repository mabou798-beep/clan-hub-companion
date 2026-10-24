/// "Live right now" rail: real event windows from the Worker, a one-minute
/// tick for countdown labels and a refetch whenever a window closes.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config.dart';
import '../models/live_event.dart';
import '../services/api.dart';

class LiveStore extends ChangeNotifier {
  LiveStore(this._api);
  final Api _api;

  List<LiveEvent> events = const [];
  bool loading = false;
  Object? error;
  DateTime now = DateTime.now().toUtc();
  String? _clanTag;
  Timer? _tick;

  void start() {
    _tick ??= Timer.periodic(const Duration(minutes: 1), (_) => _onTick());
    refresh();
  }

  /// The player's clan (if a tag is saved) adds its current war to the rail.
  void setClan(String? clanTag) {
    if (clanTag == _clanTag) return;
    _clanTag = clanTag;
    refresh();
  }

  /// Earliest moment any slot changes state (an upcoming one starts or a
  /// live one ends); crossing it triggers a refetch.
  DateTime? _nextBoundary;

  void _onTick() {
    now = DateTime.now().toUtc();
    final b = _nextBoundary;
    if (b != null && !now.isBefore(b)) {
      refresh();
    } else {
      notifyListeners();
    }
  }

  static DateTime? _boundary(List<LiveEvent> list, DateTime now) {
    DateTime? best;
    for (final e in list) {
      final t = e.isUpcoming(now) ? e.start! : e.end;
      if (best == null || t.isBefore(best)) best = t;
    }
    return best;
  }

  Future<void> refresh() async {
    if (loading) return;
    loading = true;
    notifyListeners();
    try {
      final q = _clanTag == null ? '' : '?clan=${Uri.encodeComponent(_clanTag!)}';
      final raw = await _api.getJson(Uri.parse('${AppConfig.workerBase}/live$q'));
      now = DateTime.now().toUtc();
      final list = ((raw as Map<String, dynamic>)['events'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(LiveEvent.fromJson)
          .whereType<LiveEvent>()
          .where((e) => !e.isOver(now))
          .toList()
        ..sort((a, b) {
          final la = a.isLive(now) ? 0 : 1, lb = b.isLive(now) ? 0 : 1;
          return la != lb ? la - lb : a.end.compareTo(b.end);
        });
      events = list;
      _nextBoundary = _boundary(list, now);
      error = null;
    } catch (e) {
      error = e;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }
}
