import 'package:blues_lab/domain/entities/pair_grids_map.dart';
import 'package:blues_lab/domain/entities/sync_pair_display_catalog.dart';

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
    required this.displayCatalog,
    required this.selectedPairId,
    required this.superAwakeningSkillByGridId,
  });

  final PairGridsMap pairGrids;
  final List<String> sortedPairIds;
  final SyncPairDisplayCatalog displayCatalog;
  final String selectedPairId;

  /// From `pairs.json`: `awakeningSkill` id, or `0` if none.
  final Map<String, int> superAwakeningSkillByGridId;

  PairGridsReady copyWith({
    String? selectedPairId,
  }) {
    return PairGridsReady(
      pairGrids: pairGrids,
      sortedPairIds: sortedPairIds,
      displayCatalog: displayCatalog,
      selectedPairId: selectedPairId ?? this.selectedPairId,
      superAwakeningSkillByGridId: superAwakeningSkillByGridId,
    );
  }
}

final class PairGridsFailure extends PairGridsState {
  const PairGridsFailure(this.error, {this.stackTrace});

  final Object error;
  final StackTrace? stackTrace;
}
