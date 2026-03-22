import 'package:blues_lab/domain/entities/pair_grids_map.dart';

sealed class PairGridsState {
  const PairGridsState();
}

final class PairGridsInitial extends PairGridsState {
  const PairGridsInitial();
}

final class PairGridsLoading extends PairGridsState {
  const PairGridsLoading();
}

final class PairGridsReady extends PairGridsState {
  const PairGridsReady({
    required this.pairGrids,
    required this.sortedPairIds,
    required this.selectedPairId,
    required this.selectedRevisionIndex,
  });

  final PairGridsMap pairGrids;
  final List<String> sortedPairIds;
  final String selectedPairId;

  /// Index into revisions sorted by [PairGridRevision.date] ascending.
  final int selectedRevisionIndex;

  PairGridsReady copyWith({
    String? selectedPairId,
    int? selectedRevisionIndex,
  }) {
    return PairGridsReady(
      pairGrids: pairGrids,
      sortedPairIds: sortedPairIds,
      selectedPairId: selectedPairId ?? this.selectedPairId,
      selectedRevisionIndex: selectedRevisionIndex ?? this.selectedRevisionIndex,
    );
  }
}

final class PairGridsFailure extends PairGridsState {
  const PairGridsFailure(this.error, {this.stackTrace});

  final Object error;
  final StackTrace? stackTrace;
}
