import 'package:blues_lab/domain/entities/sync_grid_cell_kind.dart';
import 'package:blues_lab/domain/value_objects/sync_grid_energy.dart';

/// Celda de un sync grid tal como se serializa en `pairgrids.json` y en eventos
/// del tipo `syncTile` / `gridTile` del cliente web.
///
/// - [position]: dos caracteres ASCII; índices de columna y fila en el layout
///   hexagonal se obtienen con `codeUnitAt(0|1)` menos los offsets base
///   (`colStart` / `rowStart`, típicamente 65 en el sitio).
/// - [target]: interpretación según [kind] — prefijo `STAT_`, id de movimiento
///   como string, o la constante `"PKMN"` para nodos ligados al Pokémon.
/// - [skill]: identificador en catálogo `skills.json`; `0` si no aplica.
/// - [level]: nivel mínimo de sync move requerido para desbloquear el nodo.
/// - [custom]: cinco enteros auxiliares definidos por el juego (a menudo ceros).
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

  /// Coste de energía de la casilla (derivado de [orbs], misma regla que el web).
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
