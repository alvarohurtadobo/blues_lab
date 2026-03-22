import 'package:blues_lab/domain/entities/sync_grid_cell.dart';
import 'package:blues_lab/domain/value_objects/sync_grid_tile_style.dart';

/// Sync grid cell projected onto the hex demo layout plane.
class PlacedSyncTile {
  const PlacedSyncTile({
    required this.index,
    required this.cell,
    required this.gridI,
    required this.gridJ,
    required this.x,
    required this.y,
    required this.styleClass,
  });

  final int index;
  final SyncGridCell cell;
  final int gridI;
  final int gridJ;
  final double x;
  final double y;
  final SyncGridTileStyleClass styleClass;
}
