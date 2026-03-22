/// Trainer and Pokémon display strings keyed by their 6-digit ids (as in game data).
///
/// Built from `assets/i18n/<lang>.json` under `DATA.CHAR` and `DATA.PKMN`.
final class SyncPairDisplayCatalog {
  const SyncPairDisplayCatalog({
    required this.trainerNames,
    required this.pokemonNames,
    this.skillNames = const {},
    this.skillDescriptions = const {},
    this.moveNames = const {},
    this.gridStatTemplates = const {},
    this.statShortLabels = const {},
    this.gridPowerupTemplates = const {},
  });

  final Map<String, String> trainerNames;
  final Map<String, String> pokemonNames;

  /// `DATA.SKILLS` in i18n: keyed by numeric skill id string.
  final Map<String, String> skillNames;
  final Map<String, String> skillDescriptions;

  /// `DATA.MOVES` NAME field, keyed by move id string.
  final Map<String, String> moveNames;

  /// `MSGS.GRID_STAT` templates (`{{value}}` placeholder).
  final Map<String, String> gridStatTemplates;

  /// `MSGS.LABEL_STAT` short labels for stats.
  final Map<String, String> statShortLabels;

  /// `MSGS.GRID_POWERUP` labels (may include `{{value}}`).
  final Map<String, String> gridPowerupTemplates;

  /// `pairId` is 12 chars: trainer id (6) + Pokémon unit id (6), matching `pairgrids.json` keys.
  ///
  /// UI label: resolved trainer and Pokémon names only (ids stay in [filterHaystack] for search).
  String label(String pairId) {
    if (pairId.length != 12) {
      return pairId;
    }
    final trainerId = pairId.substring(0, 6);
    final pokemonId = pairId.substring(6, 12);
    final trainer = trainerNames[trainerId] ?? trainerId;
    final pokemon = pokemonNames[pokemonId] ?? pokemonId;
    return '$trainer — $pokemon';
  }

  /// Lowercase text used for filtering (id + resolved names).
  String filterHaystack(String pairId) {
    if (pairId.length != 12) {
      return pairId.toLowerCase();
    }
    final trainerId = pairId.substring(0, 6);
    final pokemonId = pairId.substring(6, 12);
    final tn = (trainerNames[trainerId] ?? '').toLowerCase();
    final pn = (pokemonNames[pokemonId] ?? '').toLowerCase();
    return '${pairId.toLowerCase()} $tn $pn';
  }

  String? skillName(int skillId) => skillNames['$skillId'];

  String? skillDescription(int skillId) => skillDescriptions['$skillId'];

  String? moveName(String moveId) {
    if (moveId.isEmpty) return null;
    return moveNames[moveId];
  }

  static final RegExp _valuePlaceholder = RegExp(
    r'\{\{\s*value\s*\}\}',
    caseSensitive: false,
  );

  /// Replaces `{{value}}` (optional inner spaces, any casing) with [value].
  String substituteValuePlaceholders(String text, int value) {
    return text.replaceAllMapped(_valuePlaceholder, (_) => '$value');
  }

  /// Fills value placeholders in [template] using [value].
  String applyValueTemplate(String template, int value) {
    return substituteValuePlaceholders(template, value);
  }

  String? gridStatLine(String statKey, int value) {
    final t = gridStatTemplates[statKey];
    if (t == null) return null;
    return applyValueTemplate(t, value);
  }

  String? gridPowerupLine(String key, int value) {
    final t = gridPowerupTemplates[key];
    if (t == null) return null;
    return applyValueTemplate(t, value);
  }

  String? statShortLabel(String statKey) => statShortLabels[statKey];
}
