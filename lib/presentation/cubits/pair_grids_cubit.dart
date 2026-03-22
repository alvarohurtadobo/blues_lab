import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:blues_lab/domain/entities/pair_grids_map.dart';
import 'package:blues_lab/domain/entities/pair_grid_revision.dart';
import 'package:blues_lab/domain/entities/sync_pair_display_catalog.dart';
import 'package:blues_lab/domain/repositories/sync_pair_display_catalog_repository.dart';
import 'package:blues_lab/domain/usecases/load_official_pair_grids.dart';
import 'package:blues_lab/domain/utils/pair_grid_revision_sort.dart';
import 'package:blues_lab/presentation/cubits/pair_grids_state.dart';

final class PairGridsCubit extends Cubit<PairGridsState> {
  PairGridsCubit({
    required LoadOfficialPairGrids loadOfficialPairGrids,
    required SyncPairDisplayCatalogRepository displayCatalogRepository,
  })  : _loadOfficialPairGrids = loadOfficialPairGrids,
        _displayCatalogRepository = displayCatalogRepository,
        super(const PairGridsInitial());

  final LoadOfficialPairGrids _loadOfficialPairGrids;
  final SyncPairDisplayCatalogRepository _displayCatalogRepository;

  Future<void> load() async {
    emit(const PairGridsLoading());
    try {
      final lang = PlatformDispatcher.instance.locale.languageCode;
      final results = await Future.wait<Object>([
        _loadOfficialPairGrids(),
        _displayCatalogRepository.loadForLanguage(lang),
      ]);
      final map = results[0] as PairGridsMap;
      final catalog = results[1] as SyncPairDisplayCatalog;
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
          selectedRevisionIndex: revisions.length - 1,
        ),
      );
    } catch (e, st) {
      emit(PairGridsFailure(e, stackTrace: st));
    }
  }

  List<PairGridRevision> sortedRevisionsFor(PairGridsReady s) {
    final raw = s.pairGrids[s.selectedPairId] ?? [];
    return PairGridRevisionSort.byDateAscending(raw);
  }

  void selectPair(String pairId) {
    final s = state;
    if (s is! PairGridsReady) return;
    if (!s.pairGrids.containsKey(pairId)) return;
    final revisions = PairGridRevisionSort.byDateAscending(s.pairGrids[pairId]!);
    if (revisions.isEmpty) return;
    emit(
      s.copyWith(
        selectedPairId: pairId,
        selectedRevisionIndex: revisions.length - 1,
      ),
    );
  }

  void selectRevisionIndex(int index) {
    final s = state;
    if (s is! PairGridsReady) return;
    final revisions = sortedRevisionsFor(s);
    if (index < 0 || index >= revisions.length) return;
    emit(s.copyWith(selectedRevisionIndex: index));
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
