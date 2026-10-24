/// Player profile from the official API (/v1/players/{tag}) via our Worker.
library;

class PlayerUnit {
  const PlayerUnit(this.name, this.level, this.maxLevel, this.village);

  final String name;
  final int level;
  final int maxLevel;
  final String village;

  double get progress => maxLevel == 0 ? 0 : (level / maxLevel).clamp(0, 1);

  static List<PlayerUnit> listFrom(Object? raw) => (raw as List? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map((j) => PlayerUnit(
            j['name'] as String? ?? '',
            (j['level'] as num?)?.toInt() ?? 0,
            (j['maxLevel'] as num?)?.toInt() ?? 0,
            j['village'] as String? ?? 'home',
          ))
      .toList();
}

class PlayerClan {
  const PlayerClan(this.tag, this.name, this.level, this.badgeUrl);
  final String tag;
  final String name;
  final int level;
  final String? badgeUrl;
}

class Player {
  Player({
    required this.tag,
    required this.name,
    required this.townHallLevel,
    required this.expLevel,
    required this.trophies,
    required this.bestTrophies,
    required this.warStars,
    required this.attackWins,
    required this.defenseWins,
    required this.donations,
    required this.donationsReceived,
    required this.capitalContributions,
    required this.builderHallLevel,
    required this.builderBaseTrophies,
    required this.leagueName,
    required this.leagueIcon,
    required this.clan,
    required this.role,
    required this.heroes,
    required this.troops,
    required this.spells,
    required this.equipment,
  });

  final String tag;
  final String name;
  final int townHallLevel;
  final int expLevel;
  final int trophies;
  final int bestTrophies;
  final int warStars;
  final int attackWins;
  final int defenseWins;
  final int donations;
  final int donationsReceived;
  final int capitalContributions;
  final int? builderHallLevel;
  final int? builderBaseTrophies;
  final String? leagueName;
  final String? leagueIcon;
  final PlayerClan? clan;
  final String? role;
  final List<PlayerUnit> heroes;
  final List<PlayerUnit> troops;
  final List<PlayerUnit> spells;
  final List<PlayerUnit> equipment;

  factory Player.fromJson(Map<String, dynamic> j) {
    int i(String k) => (j[k] as num?)?.toInt() ?? 0;
    int? oi(String k) => (j[k] as num?)?.toInt();
    // Ranked leagues moved to "leagueTier"; older payloads use "league".
    final league = (j['leagueTier'] ?? j['league']) as Map<String, dynamic>?;
    final icons = league?['iconUrls'] as Map<String, dynamic>?;
    final c = j['clan'] as Map<String, dynamic>?;
    return Player(
      tag: j['tag'] as String? ?? '',
      name: j['name'] as String? ?? '',
      townHallLevel: i('townHallLevel'),
      expLevel: i('expLevel'),
      trophies: i('trophies'),
      bestTrophies: i('bestTrophies'),
      warStars: i('warStars'),
      attackWins: i('attackWins'),
      defenseWins: i('defenseWins'),
      donations: i('donations'),
      donationsReceived: i('donationsReceived'),
      capitalContributions: i('clanCapitalContributions'),
      builderHallLevel: oi('builderHallLevel'),
      builderBaseTrophies: oi('builderBaseTrophies'),
      leagueName: league?['name'] as String?,
      leagueIcon: (icons?['medium'] ?? icons?['large'] ?? icons?['small']) as String?,
      clan: c == null
          ? null
          : PlayerClan(
              c['tag'] as String? ?? '',
              c['name'] as String? ?? '',
              (c['clanLevel'] as num?)?.toInt() ?? 0,
              (c['badgeUrls'] as Map<String, dynamic>?)?['medium'] as String?,
            ),
      role: j['role'] as String?,
      heroes: PlayerUnit.listFrom(j['heroes']),
      troops: PlayerUnit.listFrom(j['troops']),
      spells: PlayerUnit.listFrom(j['spells']),
      equipment: PlayerUnit.listFrom(j['heroEquipment']),
    );
  }

  static String roleLabel(String? role) => switch (role) {
        'leader' => 'Leader',
        'coLeader' => 'Co-leader',
        'admin' => 'Elder',
        'member' => 'Member',
        _ => '',
      };
}
