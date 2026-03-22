import 'package:blues_lab/domain/entities/sync_grid_cell.dart';

/// Una revisión del grid de sincronización para un par concreto (`gridId` en el mapa raíz).
///
/// El historial del mismo par puede contener varias revisiones ordenadas por
/// [date] (timestamp o versión según el origen de datos).
class PairGridRevision {
  const PairGridRevision({
    required this.date,
    required this.cells,
  });

  /// Marca temporal o identificador de versión del layout.
  final int date;

  /// Todas las celdas activas en esta revisión.
  final List<SyncGridCell> cells;

  factory PairGridRevision.fromJson(Map<String, dynamic> json) {
    return PairGridRevision(
      date: json['date'] as int,
      cells: (json['cells'] as List<dynamic>)
          .map((e) => SyncGridCell.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'cells': cells.map((c) => c.toJson()).toList(),
      };
}
