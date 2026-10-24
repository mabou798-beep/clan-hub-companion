/// Loads units and leagues from the community CDN, keeps only entities the
/// release gate confirms are live in the game, and attaches art.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../models/league.dart';
import '../models/unit.dart';
import '../services/api.dart';
import '../util/text.dart';

/// Third-party crossover characters we never show (owned by someone other
/// than the game publisher). Matched on normalised names.
const crossoverBlocklist = {'kane', 'yetiundertaker'};

class CatalogStore extends ChangeNotifier {
  CatalogStore(this._api);
  final Api _api;

  bool loading = false;
  Object? error;

  /// True only in debug builds when no allowlist could be loaded.
  bool unverified = false;

  final Map<UnitKind, List<Unit>> _units = {};
  List<League> ranked = const [];
  List<League> war = const [];
  List<League> capital = const [];
  Set<String> silhouetteKeys = const {};

  bool get isReady => _units.isNotEmpty;
  List<Unit> units(UnitKind k) => _units[k] ?? const [];
  List<Unit> get all => _units.values.expand((e) => e).toList();

  Unit? find(UnitKind kind, String name) {
    final k = norm(name);
    for (final u in units(kind)) {
      if (u.key == k) return u;
    }
    return null;
  }

  Future<void> load({bool force = false}) async {
    if (loading || (isReady && !force)) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final cdn = AppConfig.cdnBase;
      final results = await Future.wait([
        _api.getJson(Uri.parse('$cdn/manifest.json'), timeout: const Duration(seconds: 30)),
        for (final k in UnitKind.values)
          _api.getJson(Uri.parse('$cdn/static_data/${k.dataFile}.json')),
        _api.getJson(Uri.parse('$cdn/static_data/league_tiers.json')),
        _api.getJson(Uri.parse('$cdn/static_data/war_leagues.json')),
        _api.getJson(Uri.parse('$cdn/static_data/capital_leagues.json')),
        _loadAllowlist(),
        rootBundle.loadString('assets/data/silhouettes.json'),
      ]);

      final art = _artIndex(results[0] as Map<String, dynamic>);
      final allow = results[UnitKind.values.length + 4] as Set<String>;
      unverified = allow.isEmpty && kDebugMode;

      _units.clear();
      for (var i = 0; i < UnitKind.values.length; i++) {
        final kind = UnitKind.values[i];
        final list = _items(results[i + 1])
            .map((j) => Unit.fromJson(j, kind))
            .where((u) => !crossoverBlocklist.contains(u.key))
            .where((u) => unverified || allow.contains(u.key))
            .toList();
        _units[kind] = _dedupe(list)
          ..forEach((u) => u.imageUrl = art[kind]?[u.key]);
      }

      final base = UnitKind.values.length + 1;
      ranked = _items(results[base]).map(League.ranked).toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      final w = _items(results[base + 1]);
      war = [for (var i = 0; i < w.length; i++) League.war(w[i], i)];
      final c = _items(results[base + 2]);
      capital = [for (var i = 0; i < c.length; i++) League.capital(c[i], i)];

      final sil = jsonDecode(results.last as String) as Map<String, dynamic>;
      silhouetteKeys = {
        for (final k in ['heroes', 'pets', 'equipment'])
          ...((sil[k] as List?) ?? const []).cast<String>(),
      };
    } catch (e) {
      error = e;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  static List<Map<String, dynamic>> _items(Object? raw) {
    final list = raw is Map<String, dynamic> ? raw['items'] : raw;
    return (list as List? ?? const []).whereType<Map<String, dynamic>>().toList();
  }

  /// Same name in the same village: keep the permanent (non-seasonal) entry.
  static List<Unit> _dedupe(List<Unit> list) {
    final byKey = <String, Unit>{};
    for (final u in list) {
      final k = '${u.key}|${u.village}';
      final prev = byKey[k];
      if (prev == null || (prev.isSeasonal && !u.isSeasonal)) byKey[k] = u;
    }
    return byKey.values.toList();
  }

  /// category -> normalised name -> image URL, from the CDN manifest.
  static Map<UnitKind, Map<String, String>> _artIndex(Map<String, dynamic> manifest) {
    final assets = manifest['assets'] as Map<String, dynamic>? ?? const {};
    final out = <UnitKind, Map<String, String>>{};
    for (final kind in UnitKind.values) {
      final map = <String, String>{};
      for (final a in (assets[kind.dataFile] as List? ?? const [])) {
        final path = (a as Map<String, dynamic>)['path'] as String;
        final parts = path.split('/');
        // troops/<slug>/icon.webp  or  spells/<slug>.webp
        final String slug;
        if (parts.length == 3) {
          if (!parts[2].startsWith('icon.')) continue;
          slug = parts[1];
        } else {
          slug = parts[1].replaceAll(RegExp(r'\.[a-z]+$'), '');
        }
        map[norm(slug)] = '${AppConfig.cdnBase}/$path';
      }
      out[kind] = map;
    }
    return out;
  }

  /// Names confirmed released by the Worker (built from real player data),
  /// falling back to the snapshot bundled at build time.
  Future<Set<String>> _loadAllowlist() async {
    Set<String> parse(Object? raw) => {
          for (final n in ((raw as Map<String, dynamic>?)?['names'] as List? ?? const []))
            norm(n.toString()),
        };
    try {
      final live = parse(await _api.getJson(Uri.parse('${AppConfig.workerBase}/released')));
      if (live.isNotEmpty) return live;
    } catch (_) {
      // Fall through to the bundled snapshot.
    }
    return parse(jsonDecode(await rootBundle.loadString('assets/data/released.json')));
  }
}
