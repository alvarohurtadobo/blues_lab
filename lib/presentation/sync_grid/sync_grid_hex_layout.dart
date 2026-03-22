import 'package:blues_lab/domain/entities/pair_grid_revision.dart';
import 'package:blues_lab/domain/entities/sync_grid_cell.dart';
import 'package:blues_lab/domain/value_objects/sync_grid_tile_style.dart';
import 'package:blues_lab/presentation/models/placed_sync_tile.dart';

/// Hex layout constants matching the PoMaTools web grid (`colStart` / `rowStart` = 65).
abstract final class SyncGridHexLayout {
  static const int colStart = 65;
  static const int rowStart = 65;

  static List<PlacedSyncTile> tilesFromRevision(PairGridRevision revision) {
    return tilesFromCells(revision.cells);
  }

  static List<PlacedSyncTile> tilesFromCells(List<SyncGridCell> cells) {
    final out = <PlacedSyncTile>[];
    for (var i = 0; i < cells.length; i++) {
      final c = cells[i];
      if (c.position.length != 2) continue;
      final gi = c.position.codeUnitAt(0) - colStart;
      final gj = c.position.codeUnitAt(1) - rowStart;
      final x = 46.0 * gi;
      final y = 52.0 * gj + (gi.isOdd ? 26.0 : 0.0);
      out.add(
        PlacedSyncTile(
          index: i,
          cell: c,
          gridI: gi,
          gridJ: gj,
          x: x,
          y: y,
          styleClass: resolveSyncGridTileStyleClass(c),
        ),
      );
    }
    return out;
  }
}
