import 'package:blues_lab/domain/entities/sync_grid_cell_kind.dart';
import 'package:blues_lab/domain/value_objects/sync_grid_energy.dart';

/// A sync grid cell as serialized in `pairgrids.json` and in web client events
/// such as `syncTile` / `gridTile`.
///
/// - [position]: two ASCII characters; column/row indices in the hex layout are
///   `codeUnitAt(0|1)` minus base offsets (`colStart` / `rowStart`, typically 65).
/// - [target]: meaning depends on [kind] — `STAT_` prefix, move id as string, or
///   `"PKMN"` for Pokémon-bound nodes.
/// - [skill]: id in `skills.json`; `0` when unused.
/// - [level]: minimum sync move level required to unlock the node.
/// - [custom]: five auxiliary integers from game data (often zeros).
class SyncGridCell {
  const SyncGridCell({
    required this.position,
    required this.orbs,
    required this.custom,
    required this.kind,
    required this.target,
    required this.value,
    required this.skill,
    required this.level,
  });

  final String position;
  final int orbs;
  final List<int> custom;
  final SyncGridCellKind kind;
  final String target;
  final int value;
  final int skill;
  final int level;

  /// Energy cost for the tile (from [orbs], same rule as the web app).
  double get energyCost => gridTileEnergyFromOrbs(orbs);

  factory SyncGridCell.fromJson(Map<String, dynamic> json) {
    return SyncGridCell(
      position: json['position'] as String,
      orbs: json['orbs'] as int,
      custom: List<int>.from(json['custom'] as List<dynamic>),
      kind: SyncGridCellKind.fromWire(json['kind'] as String),
      target: json['target'] as String,
      value: json['value'] as int,
      skill: json['skill'] as int,
      level: json['level'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'position': position,
        'orbs': orbs,
        'custom': custom,
        'kind': kind.wire,
        'target': target,
        'value': value,
        'skill': skill,
        'level': level,
      };
}
