import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:blues_lab/domain/entities/pair_grids_map.dart';
import 'package:blues_lab/domain/entities/sync_pair_display_catalog.dart';
import 'package:blues_lab/domain/repositories/sync_pair_display_catalog_repository.dart';
import 'package:blues_lab/domain/usecases/load_official_pair_grids.dart';
import 'package:blues_lab/domain/usecases/load_pair_super_awakening_flags.dart';
import 'package:blues_lab/domain/utils/pair_grid_revision_sort.dart';
import 'package:blues_lab/presentation/cubits/pair_grids_state.dart';

final class PairGridsCubit extends Cubit<PairGridsState> {
  PairGridsCubit({
    required LoadOfficialPairGrids loadOfficialPairGrids,
    required SyncPairDisplayCatalogRepository displayCatalogRepository,
    required LoadPairSuperAwakeningFlags loadPairSuperAwakeningFlags,
  })  : _loadOfficialPairGrids = loadOfficialPairGrids,
        _displayCatalogRepository = displayCatalogRepository,
        _loadPairSuperAwakeningFlags = loadPairSuperAwakeningFlags,
        super(const PairGridsInitial());

  final LoadOfficialPairGrids _loadOfficialPairGrids;
  final SyncPairDisplayCatalogRepository _displayCatalogRepository;
  final LoadPairSuperAwakeningFlags _loadPairSuperAwakeningFlags;

  Future<void> load() async {
    emit(const PairGridsLoading());
    try {
      final lang = PlatformDispatcher.instance.locale.languageCode;
      final results = await Future.wait<Object>([
        _loadOfficialPairGrids(),
        _displayCatalogRepository.loadForLanguage(lang),
        _loadPairSuperAwakeningFlags(),
      ]);
      final map = results[0] as PairGridsMap;
      final catalog = results[1] as SyncPairDisplayCatalog;
      final saSkills = results[2] as Map<String, int>;
      if (map.isEmpty) {
        emit(const PairGridsFailure('Official pair grids asset is empty'));
        return;
      }
      final sortedIds = map.keys.toList()..sort();
      final firstId = sortedIds.first;
      final revisions = PairGridRevisionSort.byDateAscending(map[firstId] ?? []);
      if (revisions.isEmpty) {
        emit(const PairGridsFailure('First pair entry has no revisions'));
        return;
      }
      emit(
        PairGridsReady(
          pairGrids: map,
          sortedPairIds: sortedIds,
          displayCatalog: catalog,
          selectedPairId: firstId,
          superAwakeningSkillByGridId: saSkills,
        ),
      );
    } catch (e, st) {
      emit(PairGridsFailure(e, stackTrace: st));
    }
  }

  void selectPair(String pairId) {
    final s = state;
    if (s is! PairGridsReady) return;
    if (!s.pairGrids.containsKey(pairId)) return;
    final revisions = PairGridRevisionSort.byDateAscending(s.pairGrids[pairId]!);
    if (revisions.isEmpty) return;
    emit(s.copyWith(selectedPairId: pairId));
  }

  /// Pair ids matching [query] for autocomplete / search (capped).
  Iterable<String> filteredPairIds(String query, {int limit = 80}) {
    final s = state;
    if (s is! PairGridsReady) return const [];
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return s.sortedPairIds.take(limit);
    }
    return s.sortedPairIds
        .where(
          (id) => s.displayCatalog.filterHaystack(id).contains(q),
        )
        .take(limit);
  }
}
