/// League ladders: ranked tiers, Clan War Leagues and Capital leagues.
library;

import '../config.dart';

enum LeagueLadder { ranked, war, capital }

class League {
  League({
    required this.id,
    required this.name,
    required this.ladder,
    required this.order,
    required this.imageUrl,
    this.facts = const [],
  });

  final int id;
  final String name;
  final LeagueLadder ladder;
  final int order;
  final String imageUrl;

  /// Short label/value pairs shown on the row.
  final List<(String, String)> facts;

  static const _roman = {'I': 1, 'II': 2, 'III': 3};

  /// "Bronze League III" -> "bronze_league_3".
  static String _metalSlug(String name) {
    final parts = name.split(' ');
    final n = _roman[parts.last];
    final base = (n == null ? parts : parts.sublist(0, parts.length - 1))
        .join('_')
        .toLowerCase();
    return n == null ? base : '${base}_$n';
  }

  factory League.ranked(Map<String, dynamic> j) {
    final name = j['name'] as String;
    final tier = (j['league_tier'] as num?)?.toInt() ?? 0;
    String file;
    if (tier == 0) {
      file = 'unranked';
    } else if (name.startsWith('Legend')) {
      file = _metalSlug(name);
    } else {
      final base = name.replaceAll(RegExp(r'\s*\d+$'), '');
      file = '${base.toLowerCase().replaceAll('.', '').replaceAll(' ', '_')}_$tier';
    }
    final facts = <(String, String)>[];
    void add(String k, Object? v, [String suffix = '']) {
      if (v is num && v > 0) facts.add((k, '$v$suffix'));
    }

    add('Group', j['group_size']);
    add('Attacks', j['battle_count']);
    add('Promote', j['promote_percentage'], '%');
    add('Demote', j['demote_percentage'], '%');
    add('TH cap', j['townhall_cap']);
    add('Start', j['trophy_start'], ' 🏆');
    return League(
      id: (j['_id'] as num).toInt(),
      name: name,
      ladder: LeagueLadder.ranked,
      order: tier,
      imageUrl: '${AppConfig.cdnBase}/leagues/league-tier/$file.png',
      facts: facts,
    );
  }

  factory League.war(Map<String, dynamic> j, int order) {
    final name = j['name'] as String;
    final medals = j['cwl_medals'] as Map<String, dynamic>? ?? const {};
    final facts = <(String, String)>[
      if (medals['first_place'] is num) ('1st place', '${medals['first_place']} medals'),
      if (j['promotions'] is num) ('Promote', '${j['promotions']}'),
      if (j['demotions'] is num) ('Demote', '${j['demotions']}'),
    ];
    return League(
      id: (j['_id'] as num).toInt(),
      name: name,
      ladder: LeagueLadder.war,
      order: order,
      imageUrl: '${AppConfig.cdnBase}/leagues/cwl/${_metalSlug(name)}.png',
      facts: facts,
    );
  }

  factory League.capital(Map<String, dynamic> j, int order) {
    final name = j['name'] as String;
    final facts = <(String, String)>[
      if (j['trophy_start'] is num) ('Start', '${j['trophy_start']} 🏆'),
      if (j['clan_xp'] is num) ('Clan XP', '${j['clan_xp']}'),
    ];
    return League(
      id: (j['_id'] as num).toInt(),
      name: name,
      ladder: LeagueLadder.capital,
      order: order,
      imageUrl:
          '${AppConfig.cdnBase}/leagues/capital-leagues/${_metalSlug(name)}.png',
      facts: facts,
    );
  }
}
