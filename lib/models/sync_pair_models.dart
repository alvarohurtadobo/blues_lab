import 'future_rules.dart';

class ParsedData {
  const ParsedData({required this.pairs});

  final List<SyncPairData> pairs;
}

class SyncPairData {
  const SyncPairData({
    required this.number,
    required this.displayName,
    required this.role,
    this.exRole = '',
    required this.type,
    this.rarity = 5,
    this.hasEx = false,
    this.hasSuperAwakening = false,
    required this.cells,
    this.releaseDate,
    this.syncMoveName = '',
    this.weakness = '',
    this.moves = const [],
    this.passives = const [],
    this.description = '',
    this.hasTera = false,
    this.teraMove,
    this.teraPassives = const [],
    this.stats = const {},
    this.teraStatMultiplier = const {},
    this.megaStatMultiplier = const {},
    this.megaStats = const {},
    this.formStats = const {},
    this.variations = const [],
    this.tags = const [],
    this.rules = const [],
    this.damagePassives = const [],
    this.masterPassives = const [],
  });

  final int number;
  final String displayName;
  final String role;
  final String exRole;
  final String type;
  final String weakness;
  final int rarity;
  final bool hasEx;
  final bool hasSuperAwakening;
  final List<GridCellData> cells;
  final DateTime? releaseDate;
  final String syncMoveName;
  final List<MoveData> moves;
  final List<PassiveData> passives;
  final String description;
  final bool hasTera;
  final MoveData? teraMove;
  final List<PassiveData> teraPassives;
  final Map<String, Map<String, int>> stats;
  final Map<String, double> teraStatMultiplier;
  final Map<String, double> megaStatMultiplier;
  final Map<String, Map<String, int>> megaStats;
  final Map<String, Map<String, Map<String, int>>> formStats;
  final List<VariationData> variations;
  final List<PairTag> tags;
  final List<PassiveRule> rules;
  final List<DamagePassive> damagePassives;
  final List<MasterPassiveData> masterPassives;

  Iterable<String> get searchTerms sync* {
    yield displayName;
  }
}

class GridCellData {
  const GridCellData({
    required this.cellNumber,
    required this.q,
    required this.r,
    required this.s,
    required this.energyCost,
    required this.orbCost,
    required this.title,
    required this.description,
    required this.colorKind,
    this.moveLevel = 1,
    this.tags = const [],
    this.effects = const [],
    this.subPassives = const [],
  });

  final int cellNumber;
  final int q;
  final int r;
  final int s;
  final int energyCost;
  final int orbCost;
  final String title;
  final String description;
  final String colorKind;
  final int moveLevel;
  final List<PairTag> tags;
  final List<PassiveEffect> effects;
  final List<SubPassiveData> subPassives;
}

class MoveData {
  const MoveData({
    required this.name,
    this.type = '',
    this.category = '',
    this.power = '',
    this.accuracy = '',
    this.gauge = '',
    this.target = '',
    this.description = '',
    this.isSync = false,
    this.slot,
    this.tags = const [],
    this.effects = const [],
    this.scaling,
    this.isExtendedRange = false,
  });

  final String name;
  final String type;
  final String category;
  final String power;
  final String accuracy;
  final String gauge;
  final String target;
  final String description;
  final bool isSync;
  final int? slot;
  final List<PairTag> tags;
  final List<PassiveEffect> effects;
  final MoveScaling? scaling;
  final bool isExtendedRange;

  Iterable<String> get searchTerms sync* {
    yield name;
    yield type;
    yield category;
    yield target;
    yield description;
    for (final tag in tags) {
      yield tag.category;
      yield tag.value;
    }
  }
}

class PassiveData {
  const PassiveData({
    required this.name,
    required this.description,
    this.tags = const [],
    this.rule = const PassiveRule(),
    this.locked = false,
    this.subPassives = const [],
  });

  final String name;
  final String description;
  final List<PairTag> tags;
  final PassiveRule rule;
  final bool locked;
  final List<SubPassiveData> subPassives;
}

class SubPassiveData {
  const SubPassiveData({
    required this.name,
    required this.description,
    required this.value,
  });

  final String name;
  final String description;
  final int value;
}

/// Innate power scaling for a move (loaded from move_scaling.json).
class MoveScaling {
  const MoveScaling({
    required this.stat,
    required this.who,
    required this.direction,
    required this.stepPer1000,
    this.thresholdTable = '',
    this.capPer1000 = 0,
  });

  /// Stat key: atk, def, spa, spd, spe, def_spd, all_stats, hp, acc, eva
  final String stat;
  /// 'user' or 'target'
  final String who;
  /// 'raised' or 'lowered'
  final String direction;
  /// Multiplier per stage in thousandths (250 = 0.25 per stage)
  final int stepPer1000;
  /// For HP-threshold moves like Fierce Fiery Wrath: "100,1000|75,1100|..."
  final String thresholdTable;
  /// Optional cap in thousandths
  final int capPer1000;
}

/// Pre-processed damage passive from damage_passives.json.
class DamagePassive {
  const DamagePassive({
    required this.source,
    required this.name,
    required this.type,
    required this.appliesTo,
    required this.affects,
    this.mechanism = '',
    this.value = 0,
    this.stat = '',
    this.statTarget = '',
    this.conditions = const [],
    this.moveName = '',
    this.cellNumber,
    this.subPassives = const [],
  });

  /// 'passive', 'grid_skill', 'super_awakening'
  final String source;
  final String name;
  /// 'powerup', 'reducer', 'modifier', 'composite'
  final String type;
  /// 'moves', 'sync_move', 'moves_and_sync', 'all', 'pokemon_moves', 'max_move'
  final String appliesTo;
  /// 'self', 'team', ''
  final String affects;
  /// 'flat_boost', 'user_stat_raised', 'target_stat_lowered', 'stat_is_raised',
  /// 'stat_is_lowered', 'stat_not_raised', 'gauge_cost_boost', 'PMUN', 'SMUN', 'stat_raised_30pct'
  final String mechanism;
  /// Numeric value (e.g. 5 for Power Reserves 5 = 50%)
  final int value;
  /// Stat key for stat-scaling mechanisms
  final String stat;
  /// 'self' or 'target'
  final String statTarget;
  /// Condition arrays for flat_boost (e.g. [["hp_low"]], [["sandstorm"]])
  final List<List<String>> conditions;
  /// If this passive only applies to a specific move
  final String moveName;
  /// Grid cell number (null for innate passives)
  final int? cellNumber;
  /// For composite passives
  final List<DamagePassive> subPassives;
}

/// Pre-processed master passive from master_passives.json.
class MasterPassiveData {
  const MasterPassiveData({
    required this.name,
    required this.theme,
    required this.category,
    required this.appliesToSync,
    required this.basePowerUpPct,
    required this.perAdditionalAllyPct,
    required this.maxPowerUpPct,
  });

  final String name;
  final String theme;
  /// 'any', 'physical', 'special'
  final String category;
  final bool appliesToSync;
  final int basePowerUpPct;
  final int perAdditionalAllyPct;
  final int maxPowerUpPct;

  double powerUpForAdditionalAllies(int additionalAllies) {
    final extra = additionalAllies.clamp(0, 2);
    final powerUp = basePowerUpPct + perAdditionalAllyPct * extra;
    final capped = powerUp > maxPowerUpPct ? maxPowerUpPct : powerUp;
    return capped / 100;
  }

  bool appliesToMove(MoveData move) {
    final isPhysical = move.category.toLowerCase() == 'physical';
    final isSpecial = move.category.toLowerCase() == 'special';
    if (move.isSync && !appliesToSync) return false;
    return switch (category) {
      'physical' => isPhysical,
      'special' => isSpecial,
      _ => true,
    };
  }
}

class VariationData {

  const VariationData({
    required this.formName,
    this.moves = const [],
    this.passives = const [],
  });

  final String formName;
  final List<MoveData> moves;
  final List<PassiveData> passives;

  List<MoveData> applyTo(List<MoveData> baseMoves) {
    final result = List<MoveData>.from(baseMoves);
    for (final vm in moves) {
      if (vm.isSync) {
        final idx = result.indexWhere((move) => move.isSync);
        if (idx >= 0) {
          result[idx] = vm;
        } else {
          result.add(vm);
        }
        continue;
      }

      if (vm.slot == null) {
        result.add(vm);
        continue;
      }

      final slotIndex = vm.slot! - 1;
      final nonSyncMoves = result.where((move) => !move.isSync).toList();
      if (slotIndex < 0 || slotIndex >= nonSyncMoves.length) {
        result.add(vm);
        continue;
      }

      var seenMoves = 0;
      for (var index = 0; index < result.length; index++) {
        if (result[index].isSync) {
          continue;
        }
        if (seenMoves == slotIndex) {
          result[index] = vm;
          break;
        }
        seenMoves++;
      }
    }
    return result;
  }
}
