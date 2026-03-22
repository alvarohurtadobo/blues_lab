import 'package:blues_lab/domain/entities/sync_grid_cell.dart';
import 'package:blues_lab/domain/entities/sync_grid_cell_kind.dart';
import 'package:blues_lab/domain/entities/sync_pair_display_catalog.dart';
import 'package:blues_lab/domain/value_objects/sync_grid_tile_style.dart';

/// Localized primary label for a sync grid tile (skill, move, stat line, etc.).
///
/// Fills `{{value}}` from i18n (e.g. skill [NAME]) using [SyncGridCell.value].
String syncGridCellEffectLabel(
  SyncGridCell cell,
  SyncPairDisplayCatalog catalog,
) {
  final raw = _syncGridCellEffectLabelRaw(cell, catalog);
  return catalog.substituteValuePlaceholders(raw, cell.value);
}

String _syncGridCellEffectLabelRaw(
  SyncGridCell cell,
  SyncPairDisplayCatalog catalog,
) {
  if (cell.skill != 0) {
    final name = catalog.skillName(cell.skill);
    if (name != null && name.isNotEmpty) return name;
  }

  switch (cell.kind) {
    case SyncGridCellKind.stat:
      return catalog.gridStatLine(cell.target, cell.value) ??
          catalog.statShortLabel(cell.target) ??
          cell.target;

    case SyncGridCellKind.learn:
      if (cell.target == 'PKMN') {
        return catalog.moveName('${cell.value}') ?? 'Move ${cell.value}';
      }
      return catalog.moveName(cell.target) ?? cell.target;

    case SyncGridCellKind.powerup:
      if (cell.target == kDemoSyncMoveTarget || cell.target == 'SYNC') {
        return catalog.gridPowerupLine('SYNC', cell.value) ?? 'Sync Move';
      }
      final move = catalog.moveName(cell.target);
      if (move != null) return move;
      return catalog.gridPowerupLine(cell.target, cell.value) ?? cell.target;

    case SyncGridCellKind.modifier:
      final move = catalog.moveName(cell.target);
      if (move != null) return move;
      final id = int.tryParse(cell.target);
      if (id != null) {
        final sn = catalog.skillName(id);
        if (sn != null && sn.isNotEmpty) return sn;
      }
      return cell.target;

    case SyncGridCellKind.skill:
      if (cell.target == 'PKMN') {
        return catalog.skillName(cell.skill) ?? 'Passive';
      }
      return catalog.moveName(cell.target) ?? cell.target;
  }
}
