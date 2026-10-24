/// Extra Home sections that give a reason to come back: the player's
/// village, the daily challenge, a unit of the day, favourites and facts.
/// Everything is built from real game data or the player's own choices.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/unit.dart';
import '../state/catalog_store.dart';
import '../state/engagement_store.dart';
import '../state/player_store.dart';
import '../theme.dart';
import '../util/text.dart';
import '../widgets/common.dart';
import '../widgets/unit_tile.dart';
import 'quiz_screen.dart';
import 'unit_detail_screen.dart';

void _openUnit(BuildContext context, Unit u) => Navigator.of(context)
    .push(MaterialPageRoute(builder: (_) => UnitDetailScreen(unit: u)));

/// Cards share one look: rounded stone panel with a coloured glow.
class _Panel extends StatelessWidget {
  const _Panel({required this.tone, required this.child, this.onTap});
  final Color tone;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Ink(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: tone.withValues(alpha: 0.45)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [tone.withValues(alpha: 0.2), Palette.stone],
                ),
              ),
              child: child,
            ),
          ),
        ),
      );
}

/// The saved player at a glance, or an invitation to add a tag.
class VillageCard extends StatelessWidget {
  const VillageCard({super.key, required this.onOpenStats});
  final VoidCallback onOpenStats;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PlayerStore>();
    final p = store.player;
    final t = Theme.of(context).textTheme;
    if (p == null) {
      return _Panel(
        tone: Palette.gold,
        onTap: onOpenStats,
        child: Row(
          children: [
            const Icon(Icons.badge_rounded, color: Palette.gold, size: 36),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(store.tag == null ? 'Track your village' : 'Your village',
                      style: t.titleMedium),
                  Text(
                    store.tag == null
                        ? 'Add your player tag to see trophies and upgrade progress here.'
                        : store.loading
                            ? 'Loading ${store.tag}…'
                            : 'Could not load ${store.tag}. Tap to retry.',
                    style: t.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Palette.inkFaint),
          ],
        ),
      );
    }
    final heroes = p.heroes.where((h) => h.village == 'home' && h.maxLevel > 0).toList();
    final maxed = heroes.isEmpty
        ? null
        : (heroes.fold<int>(0, (s, h) => s + h.level) *
                100 /
                heroes.fold<int>(0, (s, h) => s + h.maxLevel))
            .round();
    return _Panel(
      tone: Palette.gold,
      onTap: onOpenStats,
      child: Row(
        children: [
          SizedBox(width: 56, height: 56, child: ArtImage(p.leagueIcon, size: 56)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: t.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    _Mini('TH', '${p.townHallLevel}'),
                    _Mini('Trophies', groupDigits(p.trophies)),
                    _Mini('War stars', groupDigits(p.warStars)),
                    if (maxed != null) _Mini('Heroes', '$maxed%'),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Palette.inkFaint),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Text.rich(TextSpan(children: [
        TextSpan(
            text: '$label ',
            style: const TextStyle(color: Palette.inkFaint, fontSize: 12, fontWeight: FontWeight.w700)),
        TextSpan(
            text: value,
            style: const TextStyle(fontFamily: displayFont, fontSize: 15, color: Palette.ink)),
      ]));
}

/// Five questions a day with a streak.
class DailyChallengeCard extends StatelessWidget {
  const DailyChallengeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final e = context.watch<EngagementStore>();
    final t = Theme.of(context).textTheme;
    final done = e.playedToday;
    return _Panel(
      tone: Palette.ember,
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const QuizScreen(daily: true))),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Palette.ember.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_fire_department_rounded, color: Palette.ember, size: 24),
                Text('${e.liveStreak}',
                    style: const TextStyle(fontFamily: displayFont, fontSize: 14, height: 1)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily challenge', style: t.titleMedium),
                Text(
                  done
                      ? 'Done today: ${e.lastDailyScore}/5. Come back tomorrow to keep your streak.'
                      : e.liveStreak > 0
                          ? 'Five questions. Play today to keep your ${e.liveStreak}-day streak.'
                          : 'Five new questions every day. Start a streak!',
                  style: t.bodyMedium,
                ),
              ],
            ),
          ),
          Icon(done ? Icons.check_circle_rounded : Icons.play_circle_fill_rounded,
              color: done ? Palette.grass : Palette.ember, size: 30),
        ],
      ),
    );
  }
}

/// One unit per day, the same for everyone.
class UnitOfTheDay extends StatelessWidget {
  const UnitOfTheDay({super.key});

  @override
  Widget build(BuildContext context) {
    final cat = context.watch<CatalogStore>();
    final pool = cat.all.where((u) => u.imageUrl != null).toList()
      ..sort((a, b) => '${a.kind.index}-${a.id}'.compareTo('${b.kind.index}-${b.id}'));
    if (pool.isEmpty) return const SizedBox.shrink();
    final u = pool[Random(daySeed()).nextInt(pool.length)];
    final t = Theme.of(context).textTheme;
    final top = u.levels.isEmpty ? null : u.levels.last;
    return _Panel(
      tone: toneFor(u),
      onTap: () => _openUnit(context, u),
      child: Row(
        children: [
          SizedBox(width: 92, height: 92, child: ArtImage(u.imageUrl, size: 92)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('UNIT OF THE DAY',
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w900,
                        color: toneFor(u))),
                const SizedBox(height: 2),
                Text(u.name, style: t.titleLarge),
                const SizedBox(height: 4),
                Text(
                  [
                    u.kind.singular,
                    'Max level ${u.maxLevel}',
                    if (top?.hitpoints != null) '${compact(top!.hitpoints!)} HP',
                    if (u.unlockTownhall != null) 'TH ${u.unlockTownhall}',
                  ].join(' · '),
                  style: t.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Units the player starred; hidden until there is at least one.
class FavouritesStrip extends StatelessWidget {
  const FavouritesStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final fav = context.watch<EngagementStore>().favourites;
    final cat = context.watch<CatalogStore>();
    final units = cat.all.where((u) => fav.contains(favouriteId(u))).toList();
    if (units.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Your favourites'),
        SizedBox(
          height: 132,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: units.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(
              width: 104,
              child: UnitTile(unit: units[i], onTap: () => _openUnit(context, units[i])),
            ),
          ),
        ),
      ],
    );
  }
}

/// A fact computed from the catalogue; tap for another one.
class DidYouKnowCard extends StatefulWidget {
  const DidYouKnowCard({super.key});

  @override
  State<DidYouKnowCard> createState() => _DidYouKnowCardState();
}

class _DidYouKnowCardState extends State<DidYouKnowCard> {
  final _rng = Random();
  (String, Unit)? _fact;

  (String, Unit)? _make(List<Unit> all) {
    for (var tries = 0; tries < 30; tries++) {
      final u = all[_rng.nextInt(all.length)];
      final top = u.levels.isEmpty ? null : u.levels.last;
      final options = <String>[
        if (top?.hitpoints != null && u.kind != UnitKind.equipment)
          'At max level, ${u.name} has ${groupDigits(top!.hitpoints!)} hitpoints.',
        if (top?.dps != null && u.kind != UnitKind.equipment)
          'A max-level ${u.name} deals ${groupDigits(top!.dps!)} damage per second.',
        if (u.unlockTownhall != null && u.kind != UnitKind.equipment)
          '${u.name} unlocks at Town Hall ${u.unlockTownhall}.',
        if ((u.housingSpace ?? 0) > 0 && u.kind == UnitKind.troop)
          'One ${u.name} takes ${u.housingSpace} housing space.',
        if (u.hero != null) '${u.name} is equipment for the ${u.hero}.',
        if (u.maxLevel > 1) '${u.name} can be upgraded to level ${u.maxLevel}.',
        if (u.kind == UnitKind.troop && u.isFlying) '${u.name} flies over walls.',
      ];
      if (options.isNotEmpty) return (options[_rng.nextInt(options.length)], u);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final all = context.watch<CatalogStore>().all;
    if (all.isEmpty) return const SizedBox.shrink();
    final fact = _fact ??= _make(all);
    if (fact == null) return const SizedBox.shrink();
    final (text, unit) = fact;
    final t = Theme.of(context).textTheme;
    return _Panel(
      tone: Palette.elixir,
      onTap: () => _openUnit(context, unit),
      child: Row(
        children: [
          SizedBox(width: 56, height: 56, child: ArtImage(unit.imageUrl, size: 56)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DID YOU KNOW?',
                    style: TextStyle(
                        fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w900, color: Palette.elixir)),
                const SizedBox(height: 4),
                Text(text, style: t.bodyLarge),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Another fact',
            icon: const Icon(Icons.refresh_rounded, color: Palette.elixir),
            onPressed: () => setState(() => _fact = _make(all)),
          ),
        ],
      ),
    );
  }
}
