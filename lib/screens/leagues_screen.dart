/// League ladders: Ranked, Clan War Leagues and Clan Capital.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ads/ads.dart';
import '../models/league.dart';
import '../state/catalog_store.dart';
import '../theme.dart';
import '../widgets/common.dart';

class LeaguesScreen extends StatelessWidget {
  const LeaguesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cat = context.watch<CatalogStore>();
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Leagues'),
          bottom: const TabBar(
            indicatorColor: Palette.gold,
            labelColor: Palette.gold,
            unselectedLabelColor: Palette.inkFaint,
            labelStyle: TextStyle(fontWeight: FontWeight.w900),
            tabs: [Tab(text: 'Ranked'), Tab(text: 'Clan War'), Tab(text: 'Capital')],
          ),
        ),
        body: !cat.isReady
            ? (cat.error != null
                ? MessageView.error('Leagues could not be loaded.', () => cat.load(force: true))
                : const LoadingView())
            : TabBarView(
                children: [
                  _LeagueList(leagues: cat.ranked.reversed.toList()),
                  _LeagueList(leagues: cat.war.reversed.toList()),
                  _LeagueList(leagues: cat.capital.reversed.toList()),
                ],
              ),
      ),
    );
  }
}

class _LeagueList extends StatelessWidget {
  const _LeagueList({required this.leagues});
  final List<League> leagues;

  static const _adEvery = 10;

  @override
  Widget build(BuildContext context) {
    if (leagues.isEmpty) {
      return const MessageView(
          icon: Icons.emoji_events_outlined,
          title: 'No leagues',
          message: 'This ladder has no data right now.');
    }
    final rows = <Widget>[];
    for (var i = 0; i < leagues.length; i++) {
      rows.add(_LeagueRow(league: leagues[i]));
      if ((i + 1) % _adEvery == 0 && i + 1 < leagues.length) rows.add(const NativeAdTile());
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          itemCount: rows.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) => rows[i],
        ),
      ),
    );
  }
}

class _LeagueRow extends StatelessWidget {
  const _LeagueRow({required this.league});
  final League league;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Palette.stone,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Palette.line),
        ),
        child: Row(
          children: [
            SizedBox(width: 60, height: 60, child: ArtImage(league.imageUrl, size: 60)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(league.name, style: Theme.of(context).textTheme.titleMedium),
                  if (league.facts.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        for (final (k, v) in league.facts)
                          Text.rich(TextSpan(children: [
                            TextSpan(
                                text: '$k ',
                                style: const TextStyle(
                                    color: Palette.inkFaint, fontSize: 12, fontWeight: FontWeight.w700)),
                            TextSpan(
                                text: v,
                                style: const TextStyle(
                                    color: Palette.ink, fontSize: 12.5, fontWeight: FontWeight.w900)),
                          ])),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}
