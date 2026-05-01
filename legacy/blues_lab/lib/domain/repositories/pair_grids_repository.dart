import 'package:blues_lab/domain/entities/pair_grids_map.dart';

/// Loads pair grid documents shipped with the app (local assets).
abstract class PairGridsRepository {
  /// Full production `pairgrids.json` from assets.
  Future<PairGridsMap> loadOfficialPairGrids();
}
