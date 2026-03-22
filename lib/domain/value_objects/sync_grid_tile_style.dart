import 'package:blues_lab/domain/entities/sync_grid_cell.dart';
import 'package:blues_lab/domain/entities/sync_grid_cell_kind.dart';

/// Visual classification of a tile, aligned with site CSS classes (`--bs-tile-*`).
/// Drives color and iconography in the Flutter port.
///
/// Includes [arc] for multi-grid slots the original app forces at certain indices.
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
  /// Stable name for debugging or tooltips (CSS-style suffix).
  String get label => name;
}

/// Resolves the visual class from a domain cell.
///
/// Mirrors the Angular bundle `switch` on [SyncGridCell.kind] and
/// [SyncGridCell.target]. Without full `moves.json`, [kDemoSyncMoveTarget] marks
/// a sync-move node in demos.
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
