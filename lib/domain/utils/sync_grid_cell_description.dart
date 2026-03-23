import 'package:blues_lab/domain/entities/sync_grid_cell.dart';
import 'package:blues_lab/domain/entities/sync_grid_cell_kind.dart';
import 'package:blues_lab/domain/entities/sync_pair_display_catalog.dart';
import 'package:blues_lab/domain/value_objects/sync_grid_tile_style.dart';

/// Long-form description for hover / detail panels (skills, moves, etc.).
///
/// Applies [SyncPairDisplayCatalog.substituteValuePlaceholders] with [SyncGridCell.value].
String syncGridCellDescription(
  SyncGridCell cell,
  SyncPairDisplayCatalog catalog,
) {
  String sub(String? s) {
    if (s == null || s.isEmpty) return '';
    return catalog.substituteValuePlaceholders(s, cell.value);
  }

  if (cell.skill != 0) {
    final d = catalog.skillDescription(cell.skill);
    if (d != null && d.isNotEmpty) return sub(d);
  }

  switch (cell.kind) {
    case SyncGridCellKind.stat:
      final line = catalog.gridStatLine(cell.target, cell.value);
      return line != null && line.isNotEmpty ? line : '';

    case SyncGridCellKind.learn:
      if (cell.target == 'PKMN') {
        return sub(catalog.moveDescription('${cell.value}'));
      }
      return sub(catalog.moveDescription(cell.target));

    case SyncGridCellKind.powerup:
      if (cell.target == kDemoSyncMoveTarget || cell.target == 'SYNC') {
        return '';
      }
      final md = catalog.moveDescription(cell.target);
      if (md != null && md.isNotEmpty) return sub(md);
      return '';

    case SyncGridCellKind.modifier:
      final md = catalog.moveDescription(cell.target);
      if (md != null && md.isNotEmpty) return sub(md);
      final id = int.tryParse(cell.target);
      if (id != null) {
        return sub(catalog.skillDescription(id));
      }
      return '';

    case SyncGridCellKind.skill:
      if (cell.target == 'PKMN') {
        return sub(catalog.skillDescription(cell.skill));
      }
      return sub(catalog.moveDescription(cell.target));
  }
}
