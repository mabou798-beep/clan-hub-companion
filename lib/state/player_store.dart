/// Optional player tag (stored on device only) and the fetched profile.
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../models/player.dart';
import '../services/api.dart';

/// Characters the game uses in tags.
const _tagAlphabet = '0289PYLQGRJCUV';

/// Returns a cleaned tag ("#ABC123"), or throws a [FormatException] whose
/// message tells the player how to fix it.
String cleanTag(String input) {
  var t = input.trim().toUpperCase().replaceAll(RegExp(r'[\s#]'), '');
  if (t.isEmpty) throw const FormatException('Enter your player tag.');
  if (t.contains('O')) {
    throw const FormatException('Tags use the digit 0 (zero), not the letter O.');
  }
  if (t.contains('I') || t.contains('1')) {
    throw const FormatException('Tags never contain I or 1. Check the tag in your profile.');
  }
  if (t.length < 3 || t.length > 12) {
    throw const FormatException('A player tag is 3 to 12 characters long.');
  }
  for (final ch in t.split('')) {
    if (!_tagAlphabet.contains(ch)) {
      throw FormatException('"$ch" never appears in tags. Copy it from your profile.');
    }
  }
  return '#$t';
}

class PlayerStore extends ChangeNotifier {
  PlayerStore(this._api);
  final Api _api;
  static const _prefKey = 'player_tag';

  String? tag;
  Player? player;
  bool loading = false;
  String? error;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    tag = prefs.getString(_prefKey);
    notifyListeners();
    if (tag != null) await refresh();
  }

  Future<bool> save(String input) async {
    final String t;
    try {
      t = cleanTag(input);
    } on FormatException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    }
    tag = t;
    player = null;
    (await SharedPreferences.getInstance()).setString(_prefKey, t);
    await refresh();
    return player != null;
  }

  Future<void> forget() async {
    (await SharedPreferences.getInstance()).remove(_prefKey);
    tag = null;
    player = null;
    error = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    final t = tag;
    if (t == null || loading) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final raw = await _api.getJson(
          Uri.parse('${AppConfig.workerBase}/player/${Uri.encodeComponent(t)}'));
      player = Player.fromJson(raw as Map<String, dynamic>);
    } on ApiException catch (e) {
      error = e.kind == ApiErrorKind.notFound
          ? 'No player found with $t. Check the tag in your in-game profile '
              '(tap your name, the tag is under it).'
          : friendlyError(e);
    } catch (e) {
      error = friendlyError(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
