import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'package:blues_lab/core/constants/app_constants.dart';

/// Reads [AppConstants.officialPairsAssetPath] (root JSON array).
final class PairSuperAwakeningAssetDataSource {
  const PairSuperAwakeningAssetDataSource();

  Future<Map<String, int>> loadAwakeningSkillByGridId() async {
    final raw = await rootBundle.loadString(AppConstants.officialPairsAssetPath);
    final decoded = json.decode(raw);
    if (decoded is! List<dynamic>) {
      return const {};
    }
    final out = <String, int>{};
    for (final e in decoded) {
      if (e is! Map) continue;
      final row = Map<String, dynamic>.from(e);
      final id = row['gridId'];
      if (id is! String) continue;
      final da = row['dateAwakening'];
      final sk = row['awakeningSkill'];
      final skillId = sk is int ? sk : 0;
      final has = (da is int && da != -1) && skillId != 0;
      out[id] = has ? skillId : 0;
    }
    return out;
  }
}
