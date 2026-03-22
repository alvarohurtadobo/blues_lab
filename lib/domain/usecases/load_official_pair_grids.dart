import 'package:blues_lab/domain/entities/pair_grids_map.dart';
import 'package:blues_lab/domain/repositories/pair_grids_repository.dart';

/// Loads the official pair grids dataset for offline use.
final class LoadOfficialPairGrids {
  const LoadOfficialPairGrids(this._repository);

  final PairGridsRepository _repository;

  Future<PairGridsMap> call() => _repository.loadOfficialPairGrids();
}
