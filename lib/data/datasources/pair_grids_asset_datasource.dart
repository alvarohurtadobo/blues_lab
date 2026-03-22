import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:blues_lab/domain/entities/pair_grids_map.dart';

/// Carga documentos `pairgrids.json` desde la carpeta [assets] declarada en `pubspec.yaml`.
class PairGridsAssetDataSource {
  const PairGridsAssetDataSource();

  /// Lee y parsea el JSON en [assetPath] (p. ej. `assets/data/demo/pairgrids_demo.json`).
  Future<PairGridsMap> loadMap(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return pairGridsMapFromJson(decoded);
  }
}
