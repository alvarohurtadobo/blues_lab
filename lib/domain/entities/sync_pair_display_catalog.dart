/// Trainer and Pokémon display strings keyed by their 6-digit ids (as in game data).
///
/// Built from `assets/i18n/<lang>.json` under `DATA.CHAR` and `DATA.PKMN`.
final class SyncPairDisplayCatalog {
  const SyncPairDisplayCatalog({
    required this.trainerNames,
    required this.pokemonNames,
  });

  final Map<String, String> trainerNames;
  final Map<String, String> pokemonNames;

  /// `pairId` is 12 chars: trainer id (6) + Pokémon unit id (6), matching `pairgrids.json` keys.
  String label(String pairId) {
    if (pairId.length != 12) {
      return '($pairId)';
    }
    final trainerId = pairId.substring(0, 6);
    final pokemonId = pairId.substring(6, 12);
    final trainer = trainerNames[trainerId] ?? trainerId;
    final pokemon = pokemonNames[pokemonId] ?? pokemonId;
    return '$trainer — $pokemon ($pairId)';
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
}
