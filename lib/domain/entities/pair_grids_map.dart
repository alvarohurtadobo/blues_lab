import 'package:blues_lab/domain/entities/pair_grid_revision.dart';

/// Root shape of `pairgrids.json`: keys are grid/pair ids; values are revision lists.
typedef PairGridsMap = Map<String, List<PairGridRevision>>;

/// Builds a [PairGridsMap] from an already-decoded JSON root object.
PairGridsMap pairGridsMapFromJson(Map<String, dynamic> json) {
  return json.map((pairId, value) {
    final list = (value as List<dynamic>)
        .map((e) => PairGridRevision.fromJson(e as Map<String, dynamic>))
        .toList();
    return MapEntry(pairId, list);
  });
}
