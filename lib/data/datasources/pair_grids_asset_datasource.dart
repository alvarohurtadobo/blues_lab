import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:blues_lab/domain/entities/pair_grids_map.dart';

/// Loads `pairgrids.json`-shaped documents from the app [assets] tree in `pubspec.yaml`.
class PairGridsAssetDataSource {
  const PairGridsAssetDataSource();

  /// Reads and parses JSON at [assetPath] (e.g. `assets/data/demo/pairgrids_demo.json`).
  Future<PairGridsMap> loadMap(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return pairGridsMapFromJson(decoded);
  }
}
