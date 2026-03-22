import 'package:blues_lab/domain/entities/pair_grid_revision.dart';

/// Stable ordering for UI pickers (oldest → newest by [PairGridRevision.date]).
abstract final class PairGridRevisionSort {
  static List<PairGridRevision> byDateAscending(List<PairGridRevision> source) {
    final out = [...source]..sort((a, b) => a.date.compareTo(b.date));
    return out;
  }
}
