/// Sync grid cell category in PoMaTools data format.
///
/// JSON and the compiled Angular bundle use the [wire] string (`STAT`, `LEARN`,
/// etc.). The original grid component `switch` branches on this type and the
/// cell's `target` field.
enum SyncGridCellKind {
  /// Stat boost (target shaped like `STAT_00n`).
  stat('STAT'),

  /// Move learning node.
  learn('LEARN'),

  /// Move power-up (move id in `target`).
  powerup('POWERUP'),

  /// Passive or other skill node (id in `skills.json` via `skill`).
  skill('SKILL'),

  /// Modifier (e.g. numeric target as effect id).
  modifier('MODIFIER');

  const SyncGridCellKind(this.wire);

  /// Value as it appears in `pairgrids.json` and `syncTile` events.
  final String wire;

  /// Parses the JSON string; throws [FormatException] if unknown.
  static SyncGridCellKind fromWire(String s) {
    return SyncGridCellKind.values.firstWhere(
      (e) => e.wire == s,
      orElse: () => throw FormatException('Unknown SyncGridCellKind: $s'),
    );
  }
}
