import 'package:blues_lab/domain/entities/pair_grid_revision.dart';

/// Documento raíz de `pairgrids.json`: cada clave es un identificador de grid / par
/// y el valor es la lista de revisiones conocidas para ese par.
typedef PairGridsMap = Map<String, List<PairGridRevision>>;

/// Construye un [PairGridsMap] a partir del objeto JSON ya decodificado (mapa raíz).
PairGridsMap pairGridsMapFromJson(Map<String, dynamic> json) {
  return json.map((pairId, value) {
    final list = (value as List<dynamic>)
        .map((e) => PairGridRevision.fromJson(e as Map<String, dynamic>))
        .toList();
    return MapEntry(pairId, list);
  });
}
