/// Catalogue of units with kind / village filters and search.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ads/ads.dart';
import '../models/unit.dart';
import '../state/catalog_store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/unit_tile.dart';
import 'unit_detail_screen.dart';

class UnitsScreen extends StatefulWidget {
  const UnitsScreen({super.key});

  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> {
  UnitKind _kind = UnitKind.troop;
  bool _builder = false;
  String _query = '';

  /// Units per grid chunk before a native ad row.
  static const _chunk = 18;

  @override
  Widget build(BuildContext context) {
    final cat = context.watch<CatalogStore>();
    return Scaffold(
      appBar: AppBar(title: const Text('Units')),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final k in UnitKind.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(k.label),
                      selected: _kind == k,
                      showCheckmark: false,
                      labelStyle: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: _kind == k ? Palette.night : Palette.ink),
                      onSelected: (_) => setState(() => _kind = k),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Search',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                if (_kind == UnitKind.troop || _kind == UnitKind.hero) ...[
                  const SizedBox(width: 10),
                  SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: false, label: Text('Home')),
                      ButtonSegment(value: true, label: Text('Builder')),
                    ],
                    selected: {_builder},
                    onSelectionChanged: (s) => setState(() => _builder = s.first),
                  ),
                ],
              ],
            ),
          ),
          if (cat.unverified)
            Container(
              width: double.infinity,
              color: Palette.ember.withValues(alpha: 0.2),
              padding: const EdgeInsets.all(8),
              child: const Text(
                'DEBUG: release list unavailable, showing unverified data.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
          Expanded(child: _body(cat)),
        ],
      ),
    );
  }

  Widget _body(CatalogStore cat) {
    if (!cat.isReady) {
      if (cat.error != null) {
        return MessageView.error(
            'The unit catalogue could not be loaded.', () => cat.load(force: true));
      }
      return const LoadingView(label: 'Gathering the army…');
    }
    final usesVillage = _kind == UnitKind.troop || _kind == UnitKind.hero;
    final list = cat.units(_kind).where((u) {
      if (usesVillage && u.isBuilderBase != _builder) return false;
      return _query.isEmpty || u.name.toLowerCase().contains(_query);
    }).toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    if (list.isEmpty) {
      return MessageView(
        icon: Icons.search_off_rounded,
        title: 'No matches',
        message: _query.isEmpty
            ? 'Nothing to show in this section yet.'
            : 'No ${_kind.label.toLowerCase()} match "$_query".',
      );
    }

    final slivers = <Widget>[];
    for (var start = 0; start < list.length; start += _chunk) {
      final part = list.sublist(start, (start + _chunk).clamp(0, list.length));
      slivers.add(SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        sliver: SliverGrid.extent(
          maxCrossAxisExtent: 140,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.78,
          children: [
            for (final u in part)
              UnitTile(
                unit: u,
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => UnitDetailScreen(unit: u))),
              ),
          ],
        ),
      ));
      if (start + _chunk < list.length) {
        slivers.add(const SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(child: NativeAdTile()),
        ));
      }
    }
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 20)));
    return CustomScrollView(slivers: slivers);
  }
}
