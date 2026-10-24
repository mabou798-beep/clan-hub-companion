/// Unit detail: art, key facts, description and the level table.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/unit.dart';
import '../state/engagement_store.dart';
import '../theme.dart';
import '../util/text.dart';
import '../widgets/common.dart';
import '../widgets/unit_tile.dart';

class UnitDetailScreen extends StatelessWidget {
  const UnitDetailScreen({super.key, required this.unit});
  final Unit unit;

  List<(String, String)> get _facts {
    final u = unit;
    final f = <(String, String)>[];
    if (u.kind == UnitKind.equipment) {
      if (u.hero != null) f.add(('Hero', u.hero!));
      if (u.rarity != null) f.add(('Rarity', u.rarity!));
    } else {
      f.add(('Village', u.isBuilderBase ? 'Builder Base' : 'Home Village'));
    }
    if (u.housingSpace != null && u.housingSpace! > 0) f.add(('Housing', '${u.housingSpace}'));
    if (u.productionBuilding != null && u.kind != UnitKind.equipment) {
      f.add(('From', u.productionBuilding!));
    }
    if (u.upgradeResource != null) f.add(('Upgrade with', u.upgradeResource!));
    if (u.unlockTownhall != null) f.add(('Unlocks at', 'TH ${u.unlockTownhall}'));
    f.add(('Max level', '${u.maxLevel}'));
    if (u.kind != UnitKind.spell && u.kind != UnitKind.equipment) {
      final targets = [if (u.targetsGround) 'Ground', if (u.targetsAir) 'Air'];
      if (targets.isNotEmpty) f.add(('Targets', targets.join(' & ')));
      f.add(('Moves', u.isFlying ? 'Flying' : 'On foot'));
    }
    return f;
  }

  @override
  Widget build(BuildContext context) {
    final tone = toneFor(unit);
    final t = Theme.of(context).textTheme;
    final hasHp = unit.levels.any((l) => l.hitpoints != null);
    final hasDps = unit.levels.any((l) => l.dps != null);
    final hasDmg = unit.levels.any((l) => l.damage != null);
    final hasTh = unit.levels.any((l) => l.requiredTownhall != null);
    final hasCost = unit.levels.any((l) => l.upgradeCost != null);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            backgroundColor: Palette.night,
            actions: [_FavouriteButton(id: favouriteId(unit))],
            flexibleSpace: FlexibleSpaceBar(
              background: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, 0.1),
                    radius: 0.9,
                    colors: [tone.withValues(alpha: 0.45), Palette.night],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(40, 48, 40, 16),
                    child: Hero(
                      tag: 'unit-${unit.kind.name}-${unit.id}',
                      child: ArtImage(unit.imageUrl),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(unit.name, style: t.displaySmall),
                      if (unit.isSeasonal)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text('Event troop · available during events',
                              style: TextStyle(color: Palette.gold, fontWeight: FontWeight.w800)),
                        ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [for (final (k, v) in _facts) StatPill(label: k, value: v)],
                      ),
                      if (unit.info.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(unit.info, style: t.bodyLarge),
                      ],
                      if (unit.levels.isNotEmpty) ...[
                        const SizedBox(height: 26),
                        Text('Levels', style: t.titleLarge),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: Palette.stone,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Palette.line),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: const WidgetStatePropertyAll(Palette.stoneHigh),
                              headingTextStyle: const TextStyle(
                                  fontWeight: FontWeight.w900, color: Palette.inkSoft, fontSize: 12),
                              dataTextStyle: const TextStyle(color: Palette.ink, fontSize: 13),
                              columnSpacing: 22,
                              horizontalMargin: 16,
                              columns: [
                                const DataColumn(label: Text('LVL'), numeric: true),
                                if (hasHp) const DataColumn(label: Text('HP'), numeric: true),
                                if (hasDps) const DataColumn(label: Text('DPS'), numeric: true),
                                if (hasDmg) const DataColumn(label: Text('DAMAGE'), numeric: true),
                                if (hasTh) const DataColumn(label: Text('TH'), numeric: true),
                                if (hasCost) const DataColumn(label: Text('COST')),
                              ],
                              rows: [
                                for (final l in unit.levels)
                                  DataRow(cells: [
                                    DataCell(Text('${l.level}',
                                        style: const TextStyle(fontWeight: FontWeight.w900))),
                                    if (hasHp) DataCell(Text(l.hitpoints == null ? '–' : groupDigits(l.hitpoints!))),
                                    if (hasDps) DataCell(Text(l.dps == null ? '–' : groupDigits(l.dps!))),
                                    if (hasDmg) DataCell(Text(l.damage == null ? '–' : groupDigits(l.damage!))),
                                    if (hasTh) DataCell(Text(l.requiredTownhall?.toString() ?? '–')),
                                    if (hasCost) DataCell(Text(l.upgradeCost ?? '–')),
                                  ]),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String favouriteId(Unit u) => '${u.kind.name}:${u.id}';

class _FavouriteButton extends StatelessWidget {
  const _FavouriteButton({required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final e = context.watch<EngagementStore>();
    final on = e.isFavourite(id);
    return IconButton(
      tooltip: on ? 'Remove from favourites' : 'Add to favourites',
      icon: Icon(on ? Icons.star_rounded : Icons.star_outline_rounded,
          color: on ? Palette.gold : Palette.ink),
      onPressed: () {
        e.toggleFavourite(id);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(on ? 'Removed from favourites' : 'Added to favourites on Home'),
            duration: const Duration(seconds: 2),
          ));
      },
    );
  }
}
