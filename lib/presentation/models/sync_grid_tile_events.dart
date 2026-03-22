import 'package:blues_lab/domain/entities/sync_grid_cell.dart';
import 'package:blues_lab/presentation/models/grid_tile.dart';

/// Evento emitido al interpretar una celda (p. ej. `onParsedStatTile` en el web).
class ParsedTileEvent {
  const ParsedTileEvent({
    required this.syncTile,
    required this.index,
  });

  final SyncGridCell syncTile;
  final int index;
}

/// Par celda de datos + casilla de UI al alternar o quitar selección (`_toggleTile`).
class SyncGridTilePair {
  const SyncGridTilePair({
    required this.syncTile,
    required this.gridTile,
  });

  final SyncGridCell syncTile;
  final GridTile gridTile;
}
