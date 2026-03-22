import 'package:blues_lab/domain/entities/sync_grid_cell.dart';
import 'package:blues_lab/domain/entities/sync_grid_cell_kind.dart';

/// Clasificación visual de una casilla, alineada a las clases CSS del sitio
/// (`--bs-tile-*`). Determina color e iconografía en la réplica Flutter.
///
/// Incluye [arc] para los slots de multi-grid que el original fuerza en ciertos índices.
enum SyncGridTileStyleClass {
  stat,
  learn,
  powerup,
  sync,
  dmax,
  modifier,
  passive,
  arc,
}

extension SyncGridTileStyleClassLabel on SyncGridTileStyleClass {
  /// Nombre estable para depuración o tooltips (equivalente al sufijo CSS).
  String get label => name;
}

/// Resuelve la clase visual a partir de la celda de dominio.
///
/// Replica la lógica del `switch` del bundle Angular sobre [SyncGridCell.kind] y
/// [SyncGridCell.target]. Sin `moves.json` completo, el target especial [demoSyncMoveTarget]
/// identifica un nodo de sync move en demos.
const String kDemoSyncMoveTarget = 'DEMO_SN';

SyncGridTileStyleClass resolveSyncGridTileStyleClass(SyncGridCell cell) {
  switch (cell.kind) {
    case SyncGridCellKind.stat:
      return SyncGridTileStyleClass.stat;
    case SyncGridCellKind.learn:
      return SyncGridTileStyleClass.learn;
    case SyncGridCellKind.modifier:
      return SyncGridTileStyleClass.powerup;
    case SyncGridCellKind.powerup:
      if (cell.target == kDemoSyncMoveTarget) {
        return SyncGridTileStyleClass.sync;
      }
      return SyncGridTileStyleClass.powerup;
    case SyncGridCellKind.skill:
      if (cell.target == 'PKMN') return SyncGridTileStyleClass.passive;
      final u = int.tryParse(cell.target) ?? 0;
      if (u > 30000) return SyncGridTileStyleClass.passive;
      if (u > 6999 && u < 8000) return SyncGridTileStyleClass.dmax;
      return SyncGridTileStyleClass.modifier;
  }
}
