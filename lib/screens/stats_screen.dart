/// My stats: optional player tag (stored on this device), profile and
/// upgrade progress, pull to refresh.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/player.dart';
import '../models/unit.dart';
import '../state/catalog_store.dart';
import '../state/player_store.dart';
import '../theme.dart';
import '../util/text.dart';
import '../widgets/common.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PlayerStore>();
    final p = store.player;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My stats'),
        actions: [
          if (store.tag != null)
            IconButton(
              tooltip: 'Change player',
              icon: const Icon(Icons.manage_accounts_rounded),
              onPressed: () => _confirmForget(context, store),
            ),
        ],
      ),
      body: store.tag == null
          ? const _TagEntry()
          : RefreshIndicator(
              color: Palette.gold,
              onRefresh: store.refresh,
              child: p == null
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: 420,
                          child: store.loading
                              ? const LoadingView(label: 'Fetching your village…')
                              : MessageView.error(store.error ?? 'No data yet.', store.refresh),
                        ),
                      ],
                    )
                  : _Profile(player: p, error: store.error),
            ),
    );
  }

  Future<void> _confirmForget(BuildContext context, PlayerStore store) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Palette.stone,
        title: const Text('Use a different tag?'),
        content: const Text('This removes the saved tag from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok == true) await store.forget();
  }
}

class _TagEntry extends StatefulWidget {
  const _TagEntry();

  @override
  State<_TagEntry> createState() => _TagEntryState();
}

class _TagEntryState extends State<_TagEntry> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    await context.read<PlayerStore>().save(_ctrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PlayerStore>();
    final t = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.badge_rounded, size: 56, color: Palette.gold),
              const SizedBox(height: 14),
              Text('See your village', style: t.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Enter your player tag to see trophies, war stars and upgrade progress. '
                'Find it in the game under your name in your profile. '
                'This is optional and the tag is saved only on this device.',
                style: t.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              TextField(
                controller: _ctrl,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                style: const TextStyle(fontFamily: displayFont, fontSize: 20, letterSpacing: 1.5),
                decoration: InputDecoration(
                  prefixText: '# ',
                  hintText: 'YOURTAG',
                  errorText: store.error,
                  errorMaxLines: 3,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: store.loading ? null : _submit,
                child: store.loading
                    ? const SizedBox(
                        width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : const Text('Show my stats'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Profile extends StatelessWidget {
  const _Profile({required this.player, this.error});
  final Player player;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final p = player;
    final t = Theme.of(context).textTheme;
    final cat = context.watch<CatalogStore>();
    final homeTroops = p.troops.where((u) => u.village == 'home').toList();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text('Showing saved data. $error',
                style: const TextStyle(color: Palette.ember, fontWeight: FontWeight.w700)),
          ),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: glowDecoration(Palette.gold),
          child: Row(
            children: [
              SizedBox(width: 76, height: 76, child: ArtImage(p.leagueIcon, size: 76)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: t.headlineSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(p.tag, style: t.bodyMedium),
                    if (p.leagueName != null)
                      Text(p.leagueName!,
                          style: const TextStyle(color: Palette.gold, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatPill(label: 'Town Hall', value: '${p.townHallLevel}', color: Palette.gold),
            StatPill(label: 'XP level', value: '${p.expLevel}'),
            StatPill(label: 'Trophies', value: groupDigits(p.trophies)),
            StatPill(label: 'Best', value: groupDigits(p.bestTrophies)),
            StatPill(label: 'War stars', value: groupDigits(p.warStars)),
            StatPill(label: 'Attack wins', value: groupDigits(p.attackWins)),
            StatPill(label: 'Donated', value: groupDigits(p.donations)),
            StatPill(label: 'Received', value: groupDigits(p.donationsReceived)),
            StatPill(label: 'Capital gold', value: compact(p.capitalContributions)),
            if (p.builderHallLevel != null)
              StatPill(label: 'Builder Hall', value: '${p.builderHallLevel}'),
            if (p.builderBaseTrophies != null)
              StatPill(label: 'Builder trophies', value: groupDigits(p.builderBaseTrophies!)),
          ],
        ),
        if (p.clan != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Palette.stone,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Palette.line),
            ),
            child: Row(
              children: [
                SizedBox(width: 48, height: 48, child: ArtImage(p.clan!.badgeUrl, size: 48)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.clan!.name, style: t.titleMedium),
                      Text(
                        [Player.roleLabel(p.role), 'Clan level ${p.clan!.level}']
                            .where((s) => s.isNotEmpty)
                            .join(' · '),
                        style: t.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        _ProgressSection('Heroes', p.heroes.where((u) => u.village == 'home').toList(), UnitKind.hero, cat),
        _ProgressSection('Equipment', p.equipment, UnitKind.equipment, cat),
        _ProgressSection('Troops', homeTroops, UnitKind.troop, cat),
        _ProgressSection('Spells', p.spells, UnitKind.spell, cat),
      ],
    );
  }
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection(this.title, this.units, this.kind, this.cat);
  final String title;
  final List<PlayerUnit> units;
  final UnitKind kind;
  final CatalogStore cat;

  @override
  Widget build(BuildContext context) {
    // Pets come back inside "troops"; show them under troops via the catalogue.
    final shown = units.where((u) => u.maxLevel > 0).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    final total = shown.fold<int>(0, (s, u) => s + u.maxLevel);
    final done = shown.fold<int>(0, (s, u) => s + u.level);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
          child: Row(
            children: [
              Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
              Text('${(done * 100 / total).round()}% maxed',
                  style: const TextStyle(color: Palette.gold, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        GridView.extent(
          maxCrossAxisExtent: 210,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 3.2,
          children: [
            for (final u in shown)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Palette.stone,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: u.level >= u.maxLevel ? Palette.gold.withValues(alpha: 0.7) : Palette.line),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: ArtImage(
                          (cat.find(kind, u.name) ?? cat.find(UnitKind.pet, u.name))?.imageUrl,
                          size: 36),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: u.progress,
                              minHeight: 5,
                              backgroundColor: Palette.stoneHigh,
                              color: u.level >= u.maxLevel ? Palette.gold : Palette.elixir,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('${u.level}/${u.maxLevel}',
                        style: const TextStyle(fontFamily: displayFont, fontSize: 13)),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
