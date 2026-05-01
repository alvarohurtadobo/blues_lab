import 'package:blues_lab/domain/entities/sync_grid_cell.dart';

/// One revision of the sync grid for a given pair (`gridId` in the root map).
///
/// History for the same pair may contain several revisions ordered by [date]
/// (timestamp or version depending on the data source).
class PairGridRevision {
  const PairGridRevision({
    required this.date,
    required this.cells,
  });

  /// Timestamp or layout version id.
  final int date;

  /// All active cells in this revision.
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
