import 'package:blues_lab/domain/entities/sync_grid_cell.dart';
import 'package:blues_lab/domain/value_objects/sync_grid_energy.dart';
import 'package:blues_lab/presentation/models/grid_tile_label.dart';

/// Flutter stand-in for an RxJS-style text `Observable`: hydrate titles and
/// descriptions from i18n bundles asynchronously.
typedef GridTileI18nSetter = Future<void> Function(Map<String, String> bundle);

/// Grid tile in presentation state: geometry, style, and strings ready to render
/// (equivalent to `gridTile` after `_getSyncGridTile` in the bundle).
///
/// The original JS uses a property named `class` for CSS; here it is [cssClass].
class GridTile {
  const GridTile({
    required this.index,
    required this.i,
    required this.j,
    required this.x,
    required this.y,
    required this.level,
    required this.orbs,
    required this.custom,
    required this.energy,
    required this.labels,
    required this.tile,
    required this.title,
    required this.description,
    required this.cssClass,
    required this.icon,
    required this.selected,
    this.setLabelsFromI18n,
  });

  final int index;
  final int i;
  final int j;
  final double x;
  final double y;
  final int level;
  final int orbs;
  final List<int> custom;
  final double energy;
  final List<GridTileLabel> labels;
  final String tile;
  final String title;
  final String description;
  final String cssClass;
  final String icon;
  final bool selected;
  final GridTileI18nSetter? setLabelsFromI18n;

  /// Scaffold aligned with `_getSyncGridTile` before UI enrichment.
  factory GridTile.fromSyncCell({
    required int index,
    required int i,
    required int j,
    required double x,
    required double y,
    required SyncGridCell cell,
  }) {
    return GridTile(
      index: index,
      i: i,
      j: j,
      x: x,
      y: y,
      level: cell.level,
      orbs: cell.orbs,
      custom: List<int>.from(cell.custom),
      energy: gridTileEnergyFromOrbs(cell.orbs),
      labels: const [],
      tile: '',
      title: '',
      description: '',
      cssClass: '',
      icon: '',
      selected: false,
      setLabelsFromI18n: null,
    );
  }

  GridTile copyWith({
    int? index,
    int? i,
    int? j,
    double? x,
    double? y,
    int? level,
    int? orbs,
    List<int>? custom,
    double? energy,
    List<GridTileLabel>? labels,
    String? tile,
    String? title,
    String? description,
    String? cssClass,
    String? icon,
    bool? selected,
    GridTileI18nSetter? setLabelsFromI18n,
  }) {
    return GridTile(
      index: index ?? this.index,
      i: i ?? this.i,
      j: j ?? this.j,
      x: x ?? this.x,
      y: y ?? this.y,
      level: level ?? this.level,
      orbs: orbs ?? this.orbs,
      custom: custom ?? this.custom,
      energy: energy ?? this.energy,
      labels: labels ?? this.labels,
      tile: tile ?? this.tile,
      title: title ?? this.title,
      description: description ?? this.description,
      cssClass: cssClass ?? this.cssClass,
      icon: icon ?? this.icon,
      selected: selected ?? this.selected,
      setLabelsFromI18n: setLabelsFromI18n ?? this.setLabelsFromI18n,
    );
  }
}
