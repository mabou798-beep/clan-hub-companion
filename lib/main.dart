/// Clan Hub — unofficial companion app for Clash of Clans players.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ads/ads.dart';
import 'ads/att.dart';
import 'screens/home_screen.dart';
import 'screens/leagues_screen.dart';
import 'screens/more_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/unit_detail_screen.dart';
import 'screens/units_screen.dart';
import 'services/api.dart';
import 'state/catalog_store.dart';
import 'state/engagement_store.dart';
import 'state/live_store.dart';
import 'state/player_store.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final api = Api();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CatalogStore(api)..load()),
        ChangeNotifierProvider(create: (_) => LiveStore(api)..start()),
        ChangeNotifierProvider(create: (_) => PlayerStore(api)..restore()),
        ChangeNotifierProvider(create: (_) => EngagementStore()..restore()),
      ],
      child: const ClanHubApp(),
    ),
  );
}

class ClanHubApp extends StatelessWidget {
  const ClanHubApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Clan Hub',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const AppShell(),
      );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;
  String? _clanTag;

  @override
  void initState() {
    super.initState();
    // Ask for tracking after the first frame (never in main), then start ads.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await requestTrackingIfNeeded();
      await Ads.init();
    });
    if (kIsWeb) _openFromUrl();
  }

  /// Web preview only: `?tab=1` picks a tab, `?open=daily` or `?open=unit:NAME`
  /// opens a screen. Used to capture store screenshots.
  void _openFromUrl() {
    final q = Uri.base.queryParameters;
    _tab = (int.tryParse(q['tab'] ?? '') ?? 0).clamp(0, 4);
    final open = q['open'];
    if (open == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final nav = Navigator.of(context);
      if (open == 'daily') {
        nav.push(MaterialPageRoute(builder: (_) => const QuizScreen(daily: true)));
      } else if (open.startsWith('unit:')) {
        final cat = context.read<CatalogStore>();
        while (!cat.isReady && cat.error == null) {
          await Future<void>.delayed(const Duration(milliseconds: 300));
        }
        final name = open.substring(5);
        final u = cat.all.where((u) => u.name == name).firstOrNull;
        if (u != null) nav.push(MaterialPageRoute(builder: (_) => UnitDetailScreen(unit: u)));
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Feed the saved player's clan into the live rail (current war).
    final clan = context.watch<PlayerStore>().player?.clan?.tag;
    if (clan != _clanTag) {
      _clanTag = clan;
      context.read<LiveStore>().setClan(clan);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onOpenTab: (i) => setState(() => _tab = i)),
      const UnitsScreen(),
      const LeaguesScreen(),
      const StatsScreen(),
      const MoreScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _tab, children: pages),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AnchoredBanner(),
          NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.shield_rounded), label: 'Units'),
              NavigationDestination(icon: Icon(Icons.emoji_events_rounded), label: 'Leagues'),
              NavigationDestination(icon: Icon(Icons.badge_rounded), label: 'My stats'),
              NavigationDestination(icon: Icon(Icons.more_horiz_rounded), label: 'More'),
            ],
          ),
        ],
      ),
    );
  }
}
