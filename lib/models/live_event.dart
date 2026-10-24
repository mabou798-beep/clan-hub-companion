/// A time-boxed thing happening in the game right now (or soon).
library;

import '../util/time.dart';

enum LiveKind { goldPass, raidWeekend, clanWarLeague, clanWar, other }

class LiveEvent {
  const LiveEvent({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.start,
    required this.end,
  });

  final String id;
  final LiveKind kind;
  final String title;
  final String subtitle;
  final DateTime? start;
  final DateTime end;

  bool isLive(DateTime now) =>
      (start == null || !now.isBefore(start!)) && now.isBefore(end);
  bool isUpcoming(DateTime now) => start != null && now.isBefore(start!);
  bool isOver(DateTime now) => !now.isBefore(end);

  String label(DateTime now) {
    if (isUpcoming(now)) return 'Starts in ${countdown(start!.difference(now))}';
    if (isOver(now)) return 'Ended';
    return 'Ends in ${countdown(end.difference(now))}';
  }

  static LiveKind _kind(String? k) => switch (k) {
        'goldPass' => LiveKind.goldPass,
        'raidWeekend' => LiveKind.raidWeekend,
        'clanWarLeague' => LiveKind.clanWarLeague,
        'clanWar' => LiveKind.clanWar,
        _ => LiveKind.other,
      };

  /// Shape produced by the Worker's /live endpoint.
  static LiveEvent? fromJson(Map<String, dynamic> j) {
    final end = parseApiTime(j['end'] as String?);
    if (end == null) return null;
    return LiveEvent(
      id: j['id'] as String? ?? '',
      kind: _kind(j['kind'] as String?),
      title: j['title'] as String? ?? '',
      subtitle: j['subtitle'] as String? ?? '',
      start: parseApiTime(j['start'] as String?),
      end: end,
    );
  }
}
