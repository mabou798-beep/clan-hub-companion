/// Grid tile for a catalogue entity.
library;

import 'package:flutter/material.dart';

import '../models/unit.dart';
import '../theme.dart';
import 'common.dart';

Color toneFor(Unit u) {
  switch (u.kind) {
    case UnitKind.hero:
      return Palette.gold;
    case UnitKind.pet:
      return Palette.grass;
    case UnitKind.spell:
      return Palette.elixir;
    case UnitKind.equipment:
      return switch (u.rarity) { 'Epic' => Palette.elixir, _ => Palette.gold };
    case UnitKind.troop:
      if (u.isBuilderBase) return const Color(0xFF4FA3E0);
      return u.upgradeResource == 'Dark Elixir' ? Palette.darkElixir : Palette.elixir;
  }
}

class UnitTile extends StatelessWidget {
  const UnitTile({super.key, required this.unit, required this.onTap});
  final Unit unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = toneFor(unit);
    return Semantics(
      button: true,
      label: unit.name,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            decoration: glowDecoration(tone),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
              child: Column(
                children: [
                  Expanded(
                    child: Hero(
                      tag: 'unit-${unit.kind.name}-${unit.id}',
                      child: ArtImage(unit.imageUrl),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    unit.name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 13, height: 1.15),
                  ),
                  if (unit.isSeasonal)
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Text('EVENT',
                          style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w900,
                              color: Palette.gold)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
