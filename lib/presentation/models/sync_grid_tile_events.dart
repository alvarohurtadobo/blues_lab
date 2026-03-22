import 'package:blues_lab/domain/entities/sync_grid_cell.dart';
import 'package:blues_lab/presentation/models/grid_tile.dart';

/// Fired when a cell has been parsed (e.g. `onParsedStatTile` on web).
class ParsedTileEvent {
  const ParsedTileEvent({
    required this.syncTile,
    required this.index,
  });

  final SyncGridCell syncTile;
  final int index;
}

/// Data cell plus UI tile when toggling selection (`_toggleTile`).
class SyncGridTilePair {
  const SyncGridTilePair({
    required this.syncTile,
    required this.gridTile,
  });

  final SyncGridCell syncTile;
  final GridTile gridTile;
}
