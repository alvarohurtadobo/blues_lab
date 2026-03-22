import 'package:blues_lab/domain/entities/sync_grid_cell.dart';
import 'package:blues_lab/domain/value_objects/sync_grid_energy.dart';
import 'package:blues_lab/presentation/models/grid_tile_label.dart';

/// Sustituto Flutter de un `Observable` de textos: permite hidratar títulos y
/// descripciones desde bundles i18n de forma asíncrona.
typedef GridTileI18nSetter = Future<void> Function(Map<String, String> bundle);

/// Casilla del grid en estado de presentación: geometría, estilo y textos listos
/// para render (equivalente a `gridTile` tras `_getSyncGridTile` en el bundle).
///
/// En el JS original la propiedad de clase CSS se llama `class`; aquí se usa [cssClass].
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

  /// Constructor de apoyo alineado con `_getSyncGridTile` antes de enriquecer UI.
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
