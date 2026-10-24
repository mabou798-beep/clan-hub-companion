/// Catalogue entities (troops, heroes, pets, spells, equipment) built from
/// the community static-data files.
library;

import '../util/text.dart';

enum UnitKind {
  troop('Troops', 'Troop', 'troops'),
  hero('Heroes', 'Hero', 'heroes'),
  pet('Pets', 'Pet', 'pets'),
  spell('Spells', 'Spell', 'spells'),
  equipment('Equipment', 'Equipment', 'equipment');

  const UnitKind(this.label, this.singular, this.dataFile);
  final String label;
  final String singular;
  final String dataFile;
}

class UnitLevel {
  const UnitLevel({
    required this.level,
    this.hitpoints,
    this.dps,
    this.damage,
    this.requiredTownhall,
    this.upgradeTime,
    this.upgradeCost,
  });

  final int level;
  final num? hitpoints;
  final num? dps;
  final num? damage;
  final int? requiredTownhall;
  final int? upgradeTime;

  /// Plain number for most units; equipment ore costs are flattened to text.
  final String? upgradeCost;

  factory UnitLevel.fromJson(Map<String, dynamic> j) {
    final cost = j['upgrade_cost'];
    String? costText;
    if (cost is num) {
      costText = cost > 0 ? compact(cost) : null;
    } else if (cost is Map) {
      final parts = <String>[];
      cost.forEach((k, v) {
        if (v is num && v > 0) {
          parts.add('${compact(v)} ${k.toString().replaceAll('_', ' ')}');
        }
      });
      costText = parts.isEmpty ? null : parts.join(' · ');
    }
    num? n(String k) {
      final v = j[k];
      return v is num && v > 0 ? v : null;
    }

    return UnitLevel(
      level: (j['level'] as num?)?.toInt() ?? 0,
      hitpoints: n('hitpoints'),
      dps: n('dps'),
      damage: n('damage'),
      requiredTownhall: (j['required_townhall'] as num?)?.toInt(),
      upgradeTime: (j['upgrade_time'] as num?)?.toInt(),
      upgradeCost: costText,
    );
  }
}

class Unit {
  Unit({
    required this.id,
    required this.name,
    required this.kind,
    required this.info,
    required this.village,
    required this.levels,
    this.productionBuilding,
    this.upgradeResource,
    this.housingSpace,
    this.isFlying = false,
    this.targetsAir = false,
    this.targetsGround = false,
    this.isSeasonal = false,
    this.movementSpeed,
    this.attackRange,
    this.rarity,
    this.hero,
    this.imageUrl,
  }) : key = norm(name);

  final int id;
  final String name;
  final String key;
  final UnitKind kind;
  final String info;

  /// "home" or "builderBase".
  final String village;
  final List<UnitLevel> levels;
  final String? productionBuilding;
  final String? upgradeResource;
  final int? housingSpace;
  final bool isFlying;
  final bool targetsAir;
  final bool targetsGround;
  final bool isSeasonal;
  final int? movementSpeed;
  final int? attackRange;
  final String? rarity;

  /// Equipment only: the hero that wears it.
  final String? hero;
  String? imageUrl;

  bool get isBuilderBase => village == 'builderBase';
  int get maxLevel => levels.isEmpty ? 1 : levels.last.level;
  int? get unlockTownhall => levels.isEmpty ? null : levels.first.requiredTownhall;

  factory Unit.fromJson(Map<String, dynamic> j, UnitKind kind) {
    final rawLevels = (j['levels'] as List?) ?? const [];
    return Unit(
      id: (j['_id'] as num).toInt(),
      name: (j['name'] as String).trim(),
      kind: kind,
      info: _cleanInfo(j['info'] as String? ?? ''),
      village: j['village'] as String? ?? 'home',
      levels: rawLevels
          .whereType<Map<String, dynamic>>()
          .map(UnitLevel.fromJson)
          .toList(),
      productionBuilding: j['production_building'] as String?,
      upgradeResource: j['upgrade_resource'] as String?,
      housingSpace: (j['housing_space'] as num?)?.toInt(),
      isFlying: j['is_flying'] == true,
      targetsAir: j['is_air_targeting'] == true,
      targetsGround: j['is_ground_targeting'] == true,
      isSeasonal: j['is_seasonal'] == true,
      movementSpeed: (j['movement_speed'] as num?)?.toInt(),
      attackRange: (j['attack_range'] as num?)?.toInt(),
      rarity: j['rarity'] as String?,
      hero: j['hero'] as String?,
    );
  }

  static String _cleanInfo(String s) => s
      .replaceAll(r'\n', '\n')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}
