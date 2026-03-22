import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:blues_lab/domain/entities/sync_pair_display_catalog.dart';

/// Loads [SyncPairDisplayCatalog] from packaged i18n JSON (`DATA.CHAR`, `DATA.PKMN`).
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
    final char = _stringMap(data['CHAR']);
    final pkmn = _stringMap(data['PKMN']);
    return SyncPairDisplayCatalog(trainerNames: char, pokemonNames: pkmn);
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
}
