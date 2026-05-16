import 'future_rules.dart';

class ParsedData {
  const ParsedData({required this.pairs, required this.luckySkills});

  final List<SyncPairData> pairs;
  final List<LuckySkillDef> luckySkills;
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
    this.teraType = '',
    this.teraMove,
    this.teraPassives = const [],
    this.teraMoves = const [],
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
  /// Pair's type when Terastallized. For most pairs equals [type]; for special
  /// pairs like Terapagos this is "Stellar" while [type] stays "Normal".
  /// Used for Tera STAB checks. Falls back to [type] when empty.
  final String teraType;
  final MoveData? teraMove;
  final List<PassiveData> teraPassives;
  /// Complete moves list to use when in Tera mode. When non-empty, this fully
  /// replaces the base moves (and any Tera-exclusive move is included here).
  /// When empty, base moves are kept and [teraMove] is appended (standard pairs).
  final List<MoveData> teraMoves;
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

  /// Resolves the active moves list given the current form state.
  ///
  /// - When [showTera] is true:
  ///   - If [teraMoves] is non-empty: returns it directly (full replacement;
  ///     any Tera-exclusive move must already be included).
  ///   - Otherwise: returns base [moves] with [teraMove] appended.
  /// - When [formIndex] points to a variation: applies that variation's overrides.
  /// - Otherwise: returns base [moves].
  ///
  /// Single source of truth for the active moves list — used both for display
  /// and damage calculation so they always agree.
  List<MoveData> resolvedMoves({required int formIndex, required bool showTera}) {
    if (showTera) {
      if (teraMoves.isNotEmpty) {
        return teraMoves;
      }
      return [
        ...moves,
        if (teraMove != null) teraMove!,
      ];
    }
    if (formIndex > 0 && formIndex <= variations.length) {
      return variations[formIndex - 1].applyTo(moves);
    }
    return moves;
  }

  /// Returns the base stats for [level] (before form multipliers).
  Map<String, int> effectiveStats(String level) {
    return stats[level] ?? (stats.isEmpty ? {} : stats.values.last);
  }

  /// Returns the stat multiplier for [stat] at variation [formIndex].
  /// formIndex 0 = base form (mult = 1.0). 1..N = variations.
  double variationStatMult(int formIndex, String stat) {
    if (formIndex <= 0 || formIndex > variations.length) return 1.0;
    return variations[formIndex - 1].statMultiplier[stat] ?? 1.0;
  }

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
    this.statBonus = const {},
    this.powerBonus = const {},
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
  final Map<String, int> statBonus;
  final Map<String, int> powerBonus;
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

  MoveData copyWith({String? type, String? power, String? target}) => MoveData(
        name: name,
        type: type ?? this.type,
        category: category,
        power: power ?? this.power,
        accuracy: accuracy,
        gauge: gauge,
        target: target ?? this.target,
        description: description,
        isSync: isSync,
        slot: slot,
        tags: tags,
        effects: effects,
        scaling: scaling,
        isExtendedRange: isExtendedRange,
      );

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

/// One entry in a threshold-based scaling table.
class ThresholdEntry {
  const ThresholdEntry({required this.minPct, required this.multiplierPer1000});

  /// HP percentage lower bound (inclusive). The first entry whose minPct < hpPct applies.
  final int minPct;
  /// Power multiplier in thousandths (1000 = 1.0×).
  final int multiplierPer1000;
}

/// Innate power scaling for a move (loaded from move_scaling.json).
class MoveScaling {
  const MoveScaling({
    required this.stat,
    required this.who,
    required this.direction,
    required this.stepPer1000,
    this.thresholdTable = const [],
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
  /// For HP-threshold moves like Fierce Fiery Wrath. Each entry: minPct + multiplierPer1000.
  final List<ThresholdEntry> thresholdTable;
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

/// A lucky skill available in the lucky cookie pool, pre-resolved to a DamagePassive.
class LuckySkillDef {
  const LuckySkillDef({required this.passive, this.restrictedToRoles, this.restrictedToPairs});

  final DamagePassive passive;

  /// If non-null, only pairs whose role matches one of these values can select this skill.
  final List<String>? restrictedToRoles;

  /// If non-null, only the specific pairs whose displayName matches can select this skill.
  final List<String>? restrictedToPairs;

  bool isAvailableFor(String role, {String pairName = ''}) {
    final rp = restrictedToPairs;
    if (rp != null) {
      return rp.any((p) => p.toLowerCase() == pairName.toLowerCase());
    }
    final r = restrictedToRoles;
    if (r == null) return true;
    return r.any((rr) => rr.toLowerCase() == role.toLowerCase());
  }
}

class VariationData {

  const VariationData({
    required this.formName,
    this.moves = const [],
    this.passives = const [],
    this.statMultiplier = const {},
    this.typeOverride = '',
  });

  final String formName;
  final List<MoveData> moves;
  final List<PassiveData> passives;
  /// Per-stat multipliers for this form (same format as megaStatMultiplier).
  /// Only populated for form-change variants like Deoxys formes.
  final Map<String, double> statMultiplier;
  /// If non-empty, overrides the type of every damaging move in this form.
  /// Status moves (empty type) are not affected.
  final String typeOverride;

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

    // Apply typeOverride to all moves that have a type (non-status moves).
    if (typeOverride.isNotEmpty) {
      for (var i = 0; i < result.length; i++) {
        if (result[i].type.isNotEmpty) {
          result[i] = result[i].copyWith(type: typeOverride);
        }
      }
    }

    return result;
  }
}
