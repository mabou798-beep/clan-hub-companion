/// Home: the "Live right now" rail, shortcuts and a heroes strip.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/live_event.dart';
import '../models/unit.dart';
import '../state/catalog_store.dart';
import '../state/live_store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home_sections.dart';
import 'quiz_screen.dart';
import 'unit_detail_screen.dart';
import 'wallpapers_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenTab});

  /// Jumps to a bottom tab (1 = units, 2 = leagues, 3 = stats).
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        color: Palette.gold,
        onRefresh: () => context.read<LiveStore>().refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 240,
              backgroundColor: Palette.night,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 14),
                title: Text('Clan Hub',
                    style: Theme.of(context).textTheme.headlineSmall),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/home_banner.jpg',
                      fit: BoxFit.cover,
                      alignment: const Alignment(0, -0.15),
                      filterQuality: FilterQuality.medium,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0, 0.55, 1],
                          colors: [Color(0x33000000), Color(0x00000000), Palette.night],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SectionHeader('Live right now', trailing: _LiveDot())),
            const SliverToBoxAdapter(child: _LiveRail()),
            const SliverToBoxAdapter(child: SectionHeader('Today')),
            SliverToBoxAdapter(child: VillageCard(onOpenStats: () => onOpenTab(3))),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            const SliverToBoxAdapter(child: DailyChallengeCard()),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            const SliverToBoxAdapter(child: UnitOfTheDay()),
            const SliverToBoxAdapter(child: FavouritesStrip()),
            const SliverToBoxAdapter(child: SectionHeader('Explore')),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid.extent(
                maxCrossAxisExtent: 260,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.55,
                children: [
                  _ShortcutCard(
                    title: 'Units',
                    subtitle: 'Troops, heroes, pets, spells',
                    icon: Icons.shield_rounded,
                    tone: Palette.elixir,
                    onTap: () => onOpenTab(1),
                  ),
                  _ShortcutCard(
                    title: 'Leagues',
                    subtitle: 'Ranked, war and capital',
                    icon: Icons.emoji_events_rounded,
                    tone: Palette.gold,
                    onTap: () => onOpenTab(2),
                  ),
                  _ShortcutCard(
                    title: 'Quiz',
                    subtitle: 'Test what you know',
                    icon: Icons.psychology_alt_rounded,
                    tone: Palette.grass,
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const QuizScreen())),
                  ),
                  _ShortcutCard(
                    title: 'Wallpapers',
                    subtitle: 'Art for your phone',
                    icon: Icons.wallpaper_rounded,
                    tone: const Color(0xFF4FA3E0),
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const WallpapersScreen())),
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SectionHeader('Heroes')),
            const SliverToBoxAdapter(child: _HeroStrip()),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            const SliverToBoxAdapter(child: DidYouKnowCard()),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();
  @override
  Widget build(BuildContext context) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: Palette.grass,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Palette.grass.withValues(alpha: 0.6), blurRadius: 8)],
        ),
      );
}

class _LiveRail extends StatelessWidget {
  const _LiveRail();

  @override
  Widget build(BuildContext context) {
    final live = context.watch<LiveStore>();
    const height = 132.0;
    if (live.events.isEmpty) {
      Widget child;
      if (live.loading) {
        child = const LoadingView(label: 'Checking what is live…');
      } else if (live.error != null) {
        child = _RailNotice(
          icon: Icons.cloud_off_rounded,
          text: 'Live events could not be loaded.',
          action: 'Retry',
          onTap: live.refresh,
        );
      } else {
        child = const _RailNotice(
          icon: Icons.nights_stay_rounded,
          text: 'Nothing is running right now. Check back soon.',
        );
      }
      return SizedBox(height: height, child: child);
    }
    return SizedBox(
      height: height,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: live.events.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _LiveCard(event: live.events[i], now: live.now),
      ),
    );
  }
}

class _RailNotice extends StatelessWidget {
  const _RailNotice({required this.icon, required this.text, this.action, this.onTap});
  final IconData icon;
  final String text;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Palette.stone,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Palette.line),
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, color: Palette.inkFaint),
              const SizedBox(width: 12),
              Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
              if (action != null) TextButton(onPressed: onTap, child: Text(action!)),
            ],
          ),
        ),
      );
}

class _LiveCard extends StatelessWidget {
  const _LiveCard({required this.event, required this.now});
  final LiveEvent event;
  final DateTime now;

  (IconData, Color) get _look => switch (event.kind) {
        LiveKind.goldPass => (Icons.workspace_premium_rounded, Palette.gold),
        LiveKind.raidWeekend => (Icons.castle_rounded, const Color(0xFF4FA3E0)),
        LiveKind.clanWarLeague => (Icons.military_tech_rounded, Palette.elixir),
        LiveKind.clanWar => (Icons.flag_rounded, Palette.ember),
        LiveKind.other => (Icons.event_rounded, Palette.grass),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, tone) = _look;
    final live = event.isLive(now);
    return Container(
      width: 230,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tone.withValues(alpha: 0.5)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tone.withValues(alpha: 0.22), Palette.stone],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: tone, size: 22),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (live ? Palette.grass : Palette.inkFaint).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(live ? 'LIVE' : 'SOON',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        color: live ? Palette.grass : Palette.inkSoft)),
              ),
            ],
          ),
          const Spacer(),
          Text(event.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium),
          if (event.subtitle.isNotEmpty)
            Text(event.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(event.label(now),
              style: TextStyle(fontFamily: displayFont, fontSize: 16, color: tone)),
        ],
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tone,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: glowDecoration(tone),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: tone, size: 28),
                const Spacer(),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      );
}

class _HeroStrip extends StatelessWidget {
  const _HeroStrip();

  @override
  Widget build(BuildContext context) {
    final cat = context.watch<CatalogStore>();
    final heroes = cat.units(UnitKind.hero);
    if (heroes.isEmpty) {
      return SizedBox(
        height: 150,
        child: cat.loading
            ? const LoadingView()
            : _RailNotice(
                icon: Icons.shield_outlined,
                text: cat.error != null ? 'Heroes could not be loaded.' : 'No heroes to show yet.',
                action: cat.error != null ? 'Retry' : null,
                onTap: () => cat.load(force: true),
              ),
      );
    }
    return SizedBox(
      height: 150,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: heroes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final h = heroes[i];
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => UnitDetailScreen(unit: h))),
            child: Ink(
              width: 118,
              padding: const EdgeInsets.all(10),
              decoration: glowDecoration(Palette.gold),
              child: Column(
                children: [
                  Expanded(
                    child: Hero(
                        tag: 'unit-${h.kind.name}-${h.id}', child: ArtImage(h.imageUrl)),
                  ),
                  const SizedBox(height: 6),
                  Text(h.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
