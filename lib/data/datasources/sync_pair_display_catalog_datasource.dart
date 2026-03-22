import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:blues_lab/domain/entities/sync_pair_display_catalog.dart';

/// Loads [SyncPairDisplayCatalog] from packaged i18n JSON
/// (`DATA.CHAR`, `DATA.PKMN`, `DATA.SKILLS`, `DATA.MOVES`, and grid strings under `MSGS`).
final class SyncPairDisplayCatalogDataSource {
  const SyncPairDisplayCatalogDataSource();

  /// Uses [languageCode] (e.g. `es`, `en`) to pick `assets/i18n/<code>.json`.
  /// Falls back to English when the asset is missing.
  Future<SyncPairDisplayCatalog> loadForLanguage(String languageCode) async {
    final code = _normalizeLanguageCode(languageCode);
    Map<String, dynamic>? root;
    try {
      final raw = await rootBundle.loadString('assets/i18n/$code.json');
      root = jsonDecode(raw) as Map<String, dynamic>?;
    } catch (_) {
      if (code != 'en') {
        final raw = await rootBundle.loadString('assets/i18n/en.json');
        root = jsonDecode(raw) as Map<String, dynamic>?;
      }
    }
    if (root == null) {
      return const SyncPairDisplayCatalog(trainerNames: {}, pokemonNames: {});
    }
    final data = root['DATA'];
    if (data is! Map<String, dynamic>) {
      return const SyncPairDisplayCatalog(trainerNames: {}, pokemonNames: {});
    }
    final msgs = root['MSGS'];
    final gridStat = msgs is Map<String, dynamic>
        ? _stringMap(msgs['GRID_STAT'])
        : <String, String>{};
    final statShort = msgs is Map<String, dynamic>
        ? _stringMap(msgs['LABEL_STAT'])
        : <String, String>{};
    final gridPowerup = msgs is Map<String, dynamic>
        ? _stringMap(msgs['GRID_POWERUP'])
        : <String, String>{};

    final char = _stringMap(data['CHAR']);
    final pkmn = _stringMap(data['PKMN']);
    final skills = _skillNameAndDescMaps(data['SKILLS']);
    final moves = _moveNameMap(data['MOVES']);
    return SyncPairDisplayCatalog(
      trainerNames: char,
      pokemonNames: pkmn,
      skillNames: skills.$1,
      skillDescriptions: skills.$2,
      moveNames: moves,
      gridStatTemplates: gridStat,
      statShortLabels: statShort,
      gridPowerupTemplates: gridPowerup,
    );
  }

  static String _normalizeLanguageCode(String languageCode) {
    final c = languageCode.toLowerCase();
    const supported = {'en', 'es', 'de', 'fr', 'it', 'ja', 'ko', 'zh'};
    if (supported.contains(c)) return c;
    return 'en';
  }

  static Map<String, String> _stringMap(Object? node) {
    if (node is! Map) return {};
    return node.map(
      (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
    );
  }

  static Map<String, String> _moveNameMap(Object? node) {
    if (node is! Map) return {};
    final out = <String, String>{};
    for (final e in node.entries) {
      final v = e.value;
      if (v is! Map) continue;
      final n = v['NAME'];
      if (n is String) out[e.key.toString()] = n;
    }
    return out;
  }

  /// (`NAME` map, `DESC` map) from `DATA.SKILLS`.
  static (Map<String, String>, Map<String, String>) _skillNameAndDescMaps(
    Object? node,
  ) {
    if (node is! Map) {
      return ({}, {});
    }
    final names = <String, String>{};
    final descs = <String, String>{};
    for (final e in node.entries) {
      final v = e.value;
      if (v is! Map) continue;
      final key = e.key.toString();
      final n = v['NAME'];
      if (n is String) names[key] = n;
      final d = v['DESC'];
      if (d is String) descs[key] = d;
    }
    return (names, descs);
  }
}
