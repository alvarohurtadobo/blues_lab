import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../damage/calc.dart';
import '../../helpers/damage_helpers.dart';
import '../../models/battle_state.dart';
import '../../models/combatant_state.dart';
import '../../models/sync_pair_models.dart';
import '../../star_level.dart';
import '../../constants/type_data.dart' as consts;
import '../../widgets/move_card.dart';
import '../../widgets/type_rebuff_dropdown.dart';

class DamageCalculatorPanel extends StatefulWidget {
  const DamageCalculatorPanel({
    super.key,
    required this.pair,
    required this.activeCells,
    required this.moveLevel,
    this.expanded = false,
    required this.superAwakeningLevel,
    required this.luckySkills,
  });

  final SyncPairData pair;
  final Set<int> activeCells;
  final int moveLevel;
  final bool expanded;
  final int superAwakeningLevel;
  final List<LuckySkillDef> luckySkills;

  @override
  State<DamageCalculatorPanel> createState() => _DamageCalculatorPanelState();
}

class _DamageCalculatorPanelState extends State<DamageCalculatorPanel> {
  late BattleState _battle;

  @override
  void initState() {
    super.initState();
    _battle = BattleState.initial(widget.pair);
  }

  @override
  void didUpdateWidget(DamageCalculatorPanel old) {
    super.didUpdateWidget(old);
    if (old.pair != widget.pair) {
      _battle.ally.pair = widget.pair;
      final ls = _battle.ally.luckySkill;
      if (ls != null) {
        final available = widget.luckySkills.where(
          (d) => d.isAvailableFor(
            widget.pair.role,
            pairName: widget.pair.displayName,
          ),
        );
        if (!available.any((d) => d.passive.name == ls.name)) {
          _battle.ally.luckySkill = null;
        }
      }
    }
  }

  int get _superAwakeningLevel => widget.superAwakeningLevel;

  bool get _isEx => _battle.ally.starLevel == '5★ EX';

  String _scaledPower(String rawPower, [int? moveLevel, int saBonus = 0]) {
    return calcScaledPower(rawPower, moveLevel ?? widget.moveLevel, saBonus);
  }

  bool get _isMegaSupport {
    final role = widget.pair.role.toLowerCase().trim();
    final exRole = widget.pair.exRole.toLowerCase().trim();
    return role == 'support' || exRole == 'support';
  }

  int get _megaSyncBaseBoosts {
    if (!_megaActive) return 0;
    return _isMegaSupport ? 2 : 1;
  }

  int get _effectivePlayerSyncBoosts {
    int total = _battle.ally.syncBoosts;
    if (_megaActive) total += _megaSyncBaseBoosts;
    if (_teraActive) {
      final hasSupportEx =
          _battle.ally.hasExRole &&
          widget.pair.exRole.toLowerCase() == 'support';
      total += hasSupportEx ? 2 : 1;
    }
    return total;
  }

  static const _circleRegions = CombatantState.circleRegions;

  List<LuckySkillDef> get _availableLuckySkills {
    final role = widget.pair.role;
    final name = widget.pair.displayName;
    final all = widget.luckySkills
        .where((ls) => ls.isAvailableFor(role, pairName: name))
        .toList();
    all.sort((a, b) {
      final aExclusive = a.restrictedToPairs != null ? 0 : 1;
      final bExclusive = b.restrictedToPairs != null ? 0 : 1;
      if (aExclusive != bExclusive) return aExclusive.compareTo(bExclusive);
      return a.passive.name.compareTo(b.passive.name);
    });
    return all;
  }

  List<MasterPassiveData> get _masterPassives {
    for (final mp in widget.pair.masterPassives) {
      _battle.ally.masterPassiveAllyCount.putIfAbsent(mp.name, () => 0);
    }
    return widget.pair.masterPassives;
  }

  double _masterPassivePowerUp(MoveData move) {
    double total = 0;
    for (final passive in _masterPassives) {
      if (!passive.appliesToMove(move)) continue;
      total += passive.powerUpForAdditionalAllies(
        _battle.ally.masterPassiveAllyCount[passive.name] ?? 0,
      );
    }
    return total;
  }

  List<CircleEffect> _activeCircles() {
    final list = <CircleEffect>[];
    for (final region in _circleRegions) {
      final allies = _battle.ally.circleAllyCount[region]!;
      for (final entry in _battle.ally.circleActive[region]!.entries) {
        if (entry.value) {
          final type = switch (entry.key) {
            'physical' => CircleType.physical,
            'special' => CircleType.special,
            _ => CircleType.defensive,
          };
          list.add(CircleEffect(type: type, allyCount: allies));
        }
      }
    }
    return list;
  }

  final _playerSyncBoostsController = TextEditingController(text: '0');
  final _enemySyncBoostsController = TextEditingController(text: '0');
  final _playerHpPercentController = TextEditingController(text: '100');
  final _enemyHpPercentController = TextEditingController(text: '100');

  static const _statLabels = ['hp', 'atk', 'def', 'spa', 'spd', 'spe'];
  static const _playerStatNames = {
    'hp': 'HP',
    'atk': 'Atk',
    'def': 'Def',
    'spa': 'Sp.Atk',
    'spd': 'Sp.Def',
    'spe': 'Spe',
    'acc': 'Acc',
    'eva': 'Eva',
    'crit': 'Crit',
  };
  static const _enemyStatNames = {
    'hp': 'HP',
    'atk': 'Atk',
    'def': 'Def',
    'spa': 'Sp.Atk',
    'spd': 'Sp.Def',
    'spe': 'Spe',
  };
  final Map<String, TextEditingController> _gearControllers = {
    for (final s in _statLabels) s: TextEditingController(text: '100'),
  };

  final Map<String, TextEditingController> _enemyControllers = {
    for (final e in CombatantState.enemyDefaults.entries)
      e.key: TextEditingController(text: '${e.value}'),
  };

  @override
  void dispose() {
    for (final c in _gearControllers.values) {
      c.dispose();
    }
    for (final c in _enemyControllers.values) {
      c.dispose();
    }
    _playerSyncBoostsController.dispose();
    _enemySyncBoostsController.dispose();
    _playerHpPercentController.dispose();
    _enemyHpPercentController.dispose();
    super.dispose();
  }

  bool get _syncTechExBoost {
    if (!_isEx || !widget.pair.hasEx) return false;
    final role = widget.pair.role.toLowerCase().trim();
    final exRole = widget.pair.exRole.toLowerCase().trim();
    return role == 'tech' || (_battle.ally.hasExRole && exRole == 'tech');
  }

  int _potentialBonus(String stat) {
    return calcPotentialBonus(
          baseRarity: widget.pair.rarity,
          targetStars: _battle.ally.starLevel,
        )[stat] ??
        0;
  }

  int _exRoleBonus(String stat) {
    if (!_isEx ||
        !widget.pair.hasEx ||
        !_battle.ally.hasExRole ||
        widget.pair.exRole.isEmpty) {
      return 0;
    }
    return exRoleBonusMap[widget.pair.exRole]?[stat] ?? 0;
  }

  bool get _megaActive {
    final pair = widget.pair;
    if (pair.megaStatMultiplier.isEmpty && pair.megaStats.isEmpty) return false;
    int megaIdx = pair.variations.length + 1;
    if (pair.hasTera) megaIdx++;
    return _battle.ally.formIndex == megaIdx;
  }

  bool get _hasMegaForm =>
      widget.pair.megaStatMultiplier.isNotEmpty ||
      widget.pair.megaStats.isNotEmpty;

  bool _usesMegaSyncStats(MoveData move) => move.isSync && _hasMegaForm;

  bool get _teraActive =>
      widget.pair.hasTera &&
      _battle.ally.formIndex == widget.pair.variations.length + 1;

  double _teraStatMult(String stat) {
    if (!_teraActive) return 1.0;
    return widget.pair.teraStatMultiplier[stat] ?? 1.0;
  }

  double _megaStatMult(String stat, {bool forceMega = false}) {
    if (!_megaActive && !forceMega) return 1.0;
    return widget.pair.megaStatMultiplier[stat] ?? 1.0;
  }

  double _formStatMult(String stat, {bool forceMega = false}) {
    return _teraStatMult(stat) * _megaStatMult(stat, forceMega: forceMega);
  }

  int _applyFormMultiplier(
    int value,
    double mult,
    String stat, {
    bool useExactMegaRatio = false,
  }) {
    if (mult == 1.0) return value;
    return (value * mult).ceil() - 1;
  }

  int _calcBaseStat(String stat, int jsonStat, {bool forceMega = false}) {
    return calcOverviewStat(
      baseStat: jsonStat,
      potentialBonus: {
        'hp': _potentialBonus('hp'),
        'atk': _potentialBonus('atk'),
        'def': _potentialBonus('def'),
        'spa': _potentialBonus('spa'),
        'spd': _potentialBonus('spd'),
        'spe': _potentialBonus('spe'),
      },
      exBonus: _exRoleBonus(stat),
      formMult: _formStatMult(stat, forceMega: forceMega),
      stat: stat,
      hasSA: widget.pair.hasSuperAwakening,
      saLevel: _superAwakeningLevel,
      role: widget.pair.role,
    );
  }

  int _calcBeforeStageStat(
    String stat,
    int jsonStat, {
    bool forceMega = false,
  }) {
    final pair = widget.pair;
    var base = jsonStat;
    if (pair.hasSuperAwakening && _superAwakeningLevel >= 1) {
      base = (base * 1.1).ceil();
    }
    if (pair.hasSuperAwakening && pair.role.toLowerCase().trim() == 'support') {
      base += saSupportFlatBonus(_superAwakeningLevel)[stat] ?? 0;
    }
    final gear = _battle.ally.gear[stat] ?? 0;
    final rawBase = base + _potentialBonus(stat) + _exRoleBonus(stat);
    final mult = _formStatMult(stat, forceMega: forceMega);
    final afterMult = _applyFormMultiplier(
      rawBase + gear,
      mult,
      stat,
      useExactMegaRatio: _megaActive || forceMega,
    );
    final varMult = widget.pair.variationStatMult(_battle.ally.formIndex, stat);
    final afterVar = varMult == 1.0 ? afterMult : (afterMult * varMult).floor();
    return afterVar + _gridStatBonus(stat);
  }

  int _calcTotalStat(
    String stat,
    int jsonStat,
    int stage, {
    bool forceMega = false,
  }) {
    final beforeStage = _calcBeforeStageStat(
      stat,
      jsonStat,
      forceMega: forceMega,
    );
    return floorToInt(
      beforeStage * statVariation(stage, isSpeed: stat == 'spe'),
    );
  }

  int _gridStatBonus(String statName) {
    int total = 0;
    for (final cell in widget.pair.cells) {
      if (!widget.activeCells.contains(cell.cellNumber)) continue;
      total += cell.statBonus[statName] ?? 0;
    }
    return total;
  }

  int _gridPowerBonus(String moveName) {
    int total = 0;
    for (final cell in widget.pair.cells) {
      if (!widget.activeCells.contains(cell.cellNumber)) continue;
      total += cell.powerBonus[moveName] ?? 0;
    }
    return total;
  }

  bool _hasExpandedSync() {
    final pair = widget.pair;
    if (pair.passives.any((p) => p.name.toLowerCase() == 'expanded sync')) {
      return true;
    }
    final fi = _battle.ally.formIndex;
    if (fi > 0 && fi <= pair.variations.length) {
      return pair.variations[fi - 1].passives.any(
        (p) => p.name.toLowerCase() == 'expanded sync',
      );
    }
    return false;
  }

  int _effectiveTargetCount(MoveData move) {
    if (_battle.field.targetCount <= 1) return 1;
    if (move.isSync && _hasExpandedSync()) return _battle.field.targetCount;
    final isMultiTarget = move.target.toLowerCase() == 'all opponents';
    if (!isMultiTarget) return 1;
    if (move.isExtendedRange) return 1;
    return _battle.field.targetCount;
  }

  double _movePowerModifier(MoveData move) {
    final scaling = move.scaling;
    if (scaling == null) {
      if (move.isSync) {
        final desc = move.description.toLowerCase();
        if (desc.contains('power increases when')) {
          final conditions = <String>[];
          if (desc.contains('fairy zone')) conditions.add('fairy_zone');
          if (desc.contains('dragon zone')) conditions.add('dragon_zone');
          if (desc.contains('dark zone')) conditions.add('dark_zone');
          if (desc.contains('steel zone')) conditions.add('steel_zone');
          if (desc.contains('ghost zone')) conditions.add('ghost_zone');
          if (desc.contains('rock zone')) conditions.add('rock_zone');
          if (desc.contains('bug zone')) conditions.add('bug_zone');
          if (desc.contains('poison zone')) conditions.add('poison_zone');
          if (desc.contains('flying zone')) conditions.add('flying_zone');
          if (desc.contains('ground zone')) conditions.add('ground_zone');
          if (desc.contains('fighting zone')) conditions.add('fighting_zone');
          if (desc.contains('ice zone')) conditions.add('ice_zone');
          if (desc.contains('normal zone')) conditions.add('normal_zone');
          if (desc.contains('weather is sunny')) conditions.add('sunny');
          if (desc.contains('weather is rainy')) conditions.add('rain');
          if (desc.contains('weather is sandstorm'))
            conditions.add('sandstorm');
          if (desc.contains('weather is hail')) conditions.add('hail');
          if (desc.contains('electric terrain'))
            conditions.add('electric_terrain');
          if (desc.contains('grassy terrain')) conditions.add('grassy_terrain');
          if (desc.contains('psychic terrain'))
            conditions.add('psychic_terrain');
          if (desc.contains('terrain is in effect'))
            conditions.add('any_terrain');
          if (desc.contains('target is paralyzed')) conditions.add('paralyzed');
          if (desc.contains('target is burned')) conditions.add('burned');
          if (desc.contains('target is frozen')) conditions.add('frozen');
          if (desc.contains('target is asleep')) conditions.add('asleep');
          if (desc.contains('target is poisoned')) conditions.add('poisoned');
          if (desc.contains('target is confused')) conditions.add('confused');
          if (desc.contains('target is trapped')) conditions.add('trapped');
          if (desc.contains('target is flinching')) conditions.add('flinching');
          if (desc.contains('none of the target\'s stats are raised')) {
            final anyRaised = [
              'atk',
              'def',
              'spa',
              'spd',
              'spe',
              'acc',
              'eva',
            ].any((k) => (_battle.enemy.stages[k] ?? 0) > 0);
            if (!anyRaised) return 2.0;
          }
          for (final cond in conditions) {
            if (_checkCondition(cond, move)) return 2.0;
          }
        }
      }
      return 1.0;
    }

    final stages = scaling.who == 'user'
        ? _battle.ally.stages
        : _battle.enemy.stages;

    if (scaling.thresholdTable.isNotEmpty) {
      final hpPct = scaling.who == 'user'
          ? _battle.ally.hpPercent
          : _battle.enemy.hpPercent;
      for (final entry in scaling.thresholdTable) {
        if (hpPct < entry.minPct) continue;
        return entry.multiplierPer1000 / 1000;
      }
      return scaling.thresholdTable.last.multiplierPer1000 / 1000;
    }

    if (scaling.stat == 'boost_rank_pmun') {
      return 1.0 + _battle.ally.physicalBoostNext * scaling.stepPer1000 / 1000;
    }
    if (scaling.stat == 'boost_rank_smun') {
      return 1.0 + _battle.ally.specialBoostNext * scaling.stepPer1000 / 1000;
    }
    if (scaling.stat == 'boost_rank_syun') {
      return 1.0 + _battle.ally.syncMoveBoostNext * scaling.stepPer1000 / 1000;
    }
    if (scaling.stat.startsWith('cond:')) {
      final condMult = 1.0 + scaling.stepPer1000 / 1000;
      return _checkCondition(scaling.stat.substring(5), move) ? condMult : 1.0;
    }

    final isRaised = scaling.direction == 'raised';
    int count;

    if (scaling.stat == 'all_stats') {
      count = 0;
      for (final key in ['atk', 'def', 'spa', 'spd', 'spe', 'acc', 'eva']) {
        final s = stages[key] ?? 0;
        count += isRaised ? s.clamp(0, 6) : (-s).clamp(0, 6);
      }
    } else if (scaling.stat == 'def_spd') {
      final s1 = stages['def'] ?? 0;
      final s2 = stages['spd'] ?? 0;
      count = isRaised
          ? s1.clamp(0, 6) + s2.clamp(0, 6)
          : (-s1).clamp(0, 6) + (-s2).clamp(0, 6);
    } else if (scaling.stat == 'hp') {
      final hpPct = scaling.who == 'user'
          ? _battle.ally.hpPercent
          : _battle.enemy.hpPercent;
      return hpPct / 100;
    } else if (scaling.stat == 'rebuff') {
      final rebuff = scaling.who == 'user'
          ? (_battle.ally.userTypeRebuffs[move.type] ?? 0)
          : 0;
      count = rebuff.clamp(0, 3);
      if (count <= 0) return 1.0;
    } else {
      final s = stages[scaling.stat] ?? 0;
      count = isRaised ? s.clamp(0, 6) : (-s).clamp(0, 6);
    }

    final step = scaling.stepPer1000 / 1000;
    var mult = 1.0 + count * step;
    if (scaling.capPer1000 > 0) {
      mult = mult.clamp(0.0, scaling.capPer1000 / 1000);
    }
    return mult;
  }

  List<({String name, double value})> _gridSkillPowerUpDetails(MoveData move) {
    final results = <({String name, double value})>[];
    final lucky = _battle.ally.luckySkill;
    if (lucky != null) {
      final v = _evalDamagePassive(lucky, move);
      if (v > 0) results.add((name: '★ ${lucky.name}', value: v));
    }
    final pair = widget.pair;
    for (final dp in pair.damagePassives) {
      if (dp.source == 'grid_skill' && dp.cellNumber != null) {
        if (!widget.activeCells.contains(dp.cellNumber)) continue;
      }
      if (dp.source == 'super_awakening' && _superAwakeningLevel < 5) continue;
      if (dp.subPassives.isNotEmpty) {
        for (final sub in dp.subPassives) {
          if (sub.type != 'powerup') continue;
          final v = _evalDamagePassive(sub, move);
          if (v > 0) results.add((name: sub.name, value: v));
        }
        continue;
      }
      if (dp.type != 'powerup') continue;
      final v = _evalDamagePassive(dp, move);
      if (v > 0) results.add((name: dp.name, value: v));
    }
    return results;
  }

  double _gridSkillPowerUp(MoveData move) =>
      _gridSkillPowerUpDetails(move).fold(0.0, (sum, e) => sum + e.value);

  double _evalDamagePassive(DamagePassive dp, MoveData move) {
    if (dp.type == 'reducer') return 0;
    if (!_passiveAppliesToMove(dp, move)) return 0;
    if (dp.moveName.isNotEmpty && dp.moveName != move.name) return 0;

    switch (dp.mechanism) {
      case 'user_stat_raised':
        return _calcStatScalingBoost(dp, move, isUser: true, isRaised: true);
      case 'target_stat_lowered':
        return _calcStatScalingBoost(dp, move, isUser: false, isRaised: false);
      case 'stat_is_raised':
        final stages = _battle.ally.stages[dp.stat] ?? 0;
        return stages > 0 ? dp.value * 0.1 : 0;
      case 'stat_is_lowered':
        final stages = _battle.enemy.stages[dp.stat] ?? 0;
        return stages < 0 ? dp.value * 0.1 : 0;
      case 'stat_not_raised':
        final anyRaised = [
          'atk',
          'def',
          'spa',
          'spd',
          'spe',
          'acc',
          'eva',
        ].any((k) => (_battle.enemy.stages[k] ?? 0) > 0);
        return !anyRaised ? dp.value * 0.1 : 0;
      case 'gauge_cost_boost':
        final step = move.isSync ? 0.05 : 0.03;
        return (6 * step * 100).round() / 100;
      case 'flat_boost':
        return _evalFlatBoostConditions(dp, move) ? dp.value * 0.1 : 0;
      case 'PMUN':
        return _battle.ally.physicalBoostNext * dp.value * 0.1;
      case 'SMUN':
        return _battle.ally.specialBoostNext * dp.value * 0.1;
      case 'stat_raised_30pct':
        final stages = _battle.ally.stages[dp.stat] ?? 0;
        return stages > 0 ? 0.3 : 0;
      case 'ice_plow':
        final isSE =
            _battle.enemy.weakness.isNotEmpty &&
            move.type.toLowerCase() == _battle.enemy.weakness.toLowerCase();
        return isSE ? dp.value * 0.1 : 0;
      case 'mode_swing':
        final form = _battle.ally.formIndex;
        final modeType = form == 0 ? 'electric' : 'dark';
        return move.type.toLowerCase() == modeType ? dp.value * 0.1 : 0;
      default:
        return 0;
    }
  }

  bool _passiveAppliesToMove(DamagePassive dp, MoveData move) {
    final isSync = move.isSync;
    switch (dp.appliesTo) {
      case 'moves':
      case 'pokemon_moves':
        return !isSync;
      case 'sync_move':
        return isSync;
      case 'moves_and_sync':
      case 'all':
        return true;
      case 'max_move':
        return false;
      default:
        return !isSync;
    }
  }

  double _calcStatScalingBoost(
    DamagePassive dp,
    MoveData move, {
    required bool isUser,
    required bool isRaised,
  }) {
    final stages = isUser ? _battle.ally.stages : _battle.enemy.stages;
    final isSync = move.isSync;
    int count;

    if (dp.stat == 'all_stats') {
      count = 0;
      for (final key in ['atk', 'def', 'spa', 'spd', 'spe', 'acc', 'eva']) {
        final s = stages[key] ?? 0;
        count += isRaised ? s.clamp(0, 6) : (-s).clamp(0, 6);
      }
      final step = isSync ? 0.0667 : 0.026;
      final max = isSync ? 1.2 : 1.1;
      return ((count * step * 100).round() / 100).clamp(0.0, max);
    } else if (dp.stat == 'hp') {
      final hpPct = isUser ? _battle.ally.hpPercent : _battle.enemy.hpPercent;
      return (dp.value * 0.1 * hpPct / 100);
    } else if (dp.stat.contains('_')) {
      final keys = dp.stat.split('_');
      final step = isSync ? 0.167 : 0.05;
      final singleCap = isSync ? 1.0 : 0.3;
      var total = 0.0;
      for (final key in keys) {
        final s = stages[key] ?? 0;
        final c = isRaised ? s.clamp(0, 6) : (-s).clamp(0, 6);
        total += ((c * step * 100).round() / 100).clamp(0.0, singleCap);
      }
      return total;
    } else {
      final s = stages[dp.stat] ?? 0;
      count = isRaised ? s.clamp(0, 6) : (-s).clamp(0, 6);
      final step = isSync ? 0.167 : 0.05;
      final max = isSync ? 1.0 : 0.3;
      return ((count * step * 100).round() / 100).clamp(0.0, max);
    }
  }

  bool _evalFlatBoostConditions(DamagePassive dp, MoveData move) {
    if (dp.conditions.isEmpty) return true;
    for (final andGroup in dp.conditions) {
      if (andGroup.every((c) => _checkCondition(c, move))) return true;
    }
    return false;
  }

  bool _checkCondition(String condition, MoveData move) {
    switch (condition) {
      case 'sunny':
        return _battle.field.weather == 'Sunny';
      case 'rain':
        return _battle.field.weather == 'Rainy';
      case 'hail':
        return _battle.field.weather == 'Hail';
      case 'sandstorm':
        return _battle.field.weather == 'Sandstorm';
      case 'any_weather':
        return _battle.field.weather.isNotEmpty;
      case 'electric_terrain':
        return _battle.field.terrain == 'Electric Terrain';
      case 'psychic_terrain':
        return _battle.field.terrain == 'Psychic Terrain';
      case 'grassy_terrain':
        return _battle.field.terrain == 'Grassy Terrain';
      case 'any_terrain':
        return _battle.field.terrain.isNotEmpty;
      case 'normal_zone':
        return _battle.field.zone == 'Normal Zone';
      case 'fire_zone':
        return _battle.field.zone == 'Fire Zone';
      case 'water_zone':
        return _battle.field.zone == 'Water Zone';
      case 'electric_zone':
        return _battle.field.zone == 'Electric Zone';
      case 'ice_zone':
        return _battle.field.zone == 'Ice Zone';
      case 'fighting_zone':
        return _battle.field.zone == 'Fighting Zone';
      case 'poison_zone':
        return _battle.field.zone == 'Poison Zone';
      case 'ground_zone':
        return _battle.field.zone == 'Ground Zone';
      case 'flying_zone':
        return _battle.field.zone == 'Flying Zone';
      case 'psychic_zone':
        return _battle.field.zone == 'Psychic Zone';
      case 'bug_zone':
        return _battle.field.zone == 'Bug Zone';
      case 'rock_zone':
        return _battle.field.zone == 'Rock Zone';
      case 'ghost_zone':
        return _battle.field.zone == 'Ghost Zone';
      case 'dragon_zone':
        return _battle.field.zone == 'Dragon Zone';
      case 'dark_zone':
        return _battle.field.zone == 'Dark Zone';
      case 'steel_zone':
        return _battle.field.zone == 'Steel Zone';
      case 'fairy_zone':
        return _battle.field.zone == 'Fairy Zone';
      case 'any_zone':
        return _battle.field.zone.isNotEmpty;
      case 'any_weather_terrain_zone':
        return _battle.field.weather.isNotEmpty ||
            _battle.field.terrain.isNotEmpty ||
            _battle.field.zone.isNotEmpty;
      case 'paralyzed':
        return _battle.enemy.statusCondition == 'paralyzed';
      case 'burned':
        return _battle.enemy.statusCondition == 'burned';
      case 'frozen':
        return _battle.enemy.statusCondition == 'frozen';
      case 'asleep':
        return _battle.enemy.statusCondition == 'asleep';
      case 'poisoned':
        return _battle.enemy.statusCondition == 'poisoned' ||
            _battle.enemy.statusCondition == 'badly poisoned';
      case 'any_status':
        return _battle.enemy.statusCondition.isNotEmpty;
      case 'user_any_status':
        return _battle.ally.statusCondition.isNotEmpty;
      case 'user_poisoned':
        final c = _battle.ally.statusCondition;
        return c == 'poisoned' || c == 'badly poisoned';
      case 'target_hp_half':
        return _battle.enemy.hpPercent <= 50;
      case 'flinching':
        return _battle.enemy.volatileStatus['flinching'] ?? false;
      case 'confused':
        return _battle.enemy.volatileStatus['confused'] ?? false;
      case 'trapped':
        return _battle.enemy.volatileStatus['trapped'] ?? false;
      case 'flinch_confuse_trap':
        return (_battle.enemy.volatileStatus['flinching'] ?? false) ||
            (_battle.enemy.volatileStatus['confused'] ?? false) ||
            (_battle.enemy.volatileStatus['trapped'] ?? false);
      case 'restrained':
        return _battle.enemy.volatileStatus['restrained'] ?? false;
      case 'no_target_stats_raised':
        return ![
          'atk',
          'def',
          'spa',
          'spd',
          'spe',
          'acc',
          'eva',
        ].any((k) => (_battle.enemy.stages[k] ?? 0) > 0);
      case 'target_rebuff_lowered':
        return _battle.enemy.typeRebuffs.values.any((v) => v < 0) ||
            _battle.enemy.stellarRebuff < 0;
      case 'target_sync_buff':
        return _battle.enemy.hasSyncBuff;
      case 'user_prev_move_failed':
        return _battle.ally.prevMoveFailed;
      case 'any_condition':
        return _battle.enemy.statusCondition.isNotEmpty ||
            (_battle.enemy.volatileStatus['flinching'] ?? false) ||
            (_battle.enemy.volatileStatus['confused'] ?? false) ||
            (_battle.enemy.volatileStatus['trapped'] ?? false) ||
            (_battle.enemy.volatileStatus['restrained'] ?? false);
      case 'hp_low':
        return _battle.ally.hpPercent <= 25;
      case 'hp_full':
        return _battle.ally.hpPercent == 100;
      case 'super_effective':
        return _battle.enemy.weakness.isNotEmpty &&
            move.type.toLowerCase() == _battle.enemy.weakness.toLowerCase();
      case 'critical':
        return _battle.ally.isCriticalMove;
      case 'move_gauge_accel':
      case 'field_FILD_001':
        return _battle.ally.moveGaugeAccel;
      case 'enemy_move_gauge_accel':
        return _battle.enemy.moveGaugeAccel;
      case 'damage_field_DMFD_8':
        return _battle.enemy.damageField == 'Poison';
      case 'damage_field_DMFD_13':
        return _battle.enemy.damageField == 'Rock';
      case 'damage_field_DMFD_16':
        return _battle.enemy.damageField == 'Dark';
      case 'damage_field_DMFD_17':
        return _battle.enemy.damageField == 'Steel';
      case 'unity':
        return false;
      case 'circle':
        return _activeCircles().isNotEmpty;
      default:
        if (condition.startsWith('type_')) {
          final type = condition.substring(5);
          return move.type.toLowerCase() == type.toLowerCase();
        }
        if (condition.startsWith('theme_')) return _activeCircles().isNotEmpty;
        return true;
    }
  }

  int _totalBp(MoveData move) {
    final saBonus = calcSaBonus(widget.pair, _superAwakeningLevel, move);
    final base = int.tryParse(_scaledPower(move.power, null, saBonus)) ?? 0;
    final grid = _gridPowerBonus(move.name);

    double power = base.toDouble();
    if (move.isSync) {
      if (_syncTechExBoost) {
        power = (power * 1.5).floor().toDouble();
      }
    } else {
      final isTeraMove =
          widget.pair.teraMove != null &&
          move.name == widget.pair.teraMove!.name;
      final tera = _teraActive && widget.pair.hasTera;
      final teraBonus =
          tera &&
          !isTeraMove &&
          move.type.toLowerCase() == widget.pair.type.toLowerCase();
      if (teraBonus) {
        power = (power * 1.5).floor().toDouble();
      }
    }

    final baseWithGrid = power + grid;
    final isPhysical = move.category.toLowerCase() == 'physical';
    final boostRank = move.isSync
        ? 0
        : (isPhysical
              ? _battle.ally.physicalBoostNext
              : _battle.ally.specialBoostNext);
    final syncSkill = move.isSync ? _battle.ally.syncMoveBoostNext * 0.1 : 0.0;
    final masterPassiveSkill = _masterPassivePowerUp(move);
    final passiveSkill = _gridSkillPowerUp(move);
    final totalSkillMult =
        1 + syncSkill + masterPassiveSkill + passiveSkill + boostRank * 0.4;
    final scaled = (baseWithGrid * totalSkillMult).floor();
    final modifier = _movePowerModifier(move);
    final finalBp = (scaled * modifier).floor();
    return finalBp;
  }

  // ===== WIDGET BUILDING =====

  Widget _mitigationCell(int value, ValueChanged<int> onChanged) {
    return Center(
      child: DropdownButton<int>(
        value: value,
        isDense: true,
        underline: const SizedBox(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: value > 0 ? Colors.orange.shade800 : Colors.black,
        ),
        items: [
          for (int i = 0; i <= 9; i++)
            DropdownMenuItem(value: i, child: Text('$i')),
        ],
        onChanged: (v) => onChanged(v!),
      ),
    );
  }

  Widget _stageCell(int value, ValueChanged<int> onChanged) {
    return Center(
      child: DropdownButton<int>(
        value: value,
        isDense: true,
        underline: const SizedBox(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: value > 0
              ? Colors.blue
              : value < 0
              ? Colors.red
              : Colors.black,
        ),
        items: [
          for (int i = -6; i <= 6; i++)
            DropdownMenuItem(value: i, child: Text('$i')),
        ],
        onChanged: (v) => onChanged(v!),
      ),
    );
  }

  Widget _calcFormTab(String label, int index, {Color? color, double? width}) {
    final selected = _battle.ally.formIndex == index;
    final tabColor = color ?? Theme.of(context).colorScheme.primary;
    final tab = GestureDetector(
      onTap: () => setState(() => _battle.ally.formIndex = index),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? tabColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tabColor, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
    return width == null ? Expanded(child: tab) : tab;
  }

  Widget _luckySkillRow(
    BuildContext context,
    SyncPairData pair,
    TextStyle labelStyle,
  ) {
    final available = _availableLuckySkills;
    final current = _battle.ally.luckySkill;
    final currentName = current?.name;

    return Row(
      children: [
        Text('Lucky Skill: ', style: labelStyle),
        const SizedBox(width: 4),
        Expanded(
          child: DropdownButton<String?>(
            value: currentName,
            isDense: true,
            isExpanded: true,
            style: const TextStyle(fontSize: 12, color: Colors.black),
            selectedItemBuilder: (context) => [
              const Text('None', style: TextStyle(fontSize: 12)),
              for (final ls in available)
                Row(
                  children: [
                    if (ls.restrictedToPairs != null) ...[
                      const Icon(
                        Icons.star,
                        size: 12,
                        color: Color(0xFFFFAA00),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        ls.passive.name,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
            ],
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('None', style: TextStyle(fontSize: 12)),
              ),
              for (final ls in available)
                DropdownMenuItem<String?>(
                  value: ls.passive.name,
                  child: ls.restrictedToPairs != null
                      ? Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 12,
                              color: Color(0xFFFFAA00),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                ls.passive.name,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        )
                      : Text(
                          ls.passive.name,
                          style: const TextStyle(fontSize: 12),
                        ),
                ),
            ],
            onChanged: (name) => setState(() {
              if (name == null) {
                _battle.ally.luckySkill = null;
              } else {
                _battle.ally.luckySkill = available
                    .firstWhere((ls) => ls.passive.name == name)
                    .passive;
              }
            }),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pair = widget.pair;
    final validStars = availableStarLevels(pair.rarity, pair.hasEx);
    if (!validStars.contains(_battle.ally.starLevel)) {
      _battle.ally.starLevel = validStars.last;
    }
    final levels = pair.stats.keys.toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    if (levels.isNotEmpty && !levels.contains(_battle.ally.charLevel)) {
      _battle.ally.charLevel = levels.last;
    }
    final isTeraActive = _teraActive;
    final currentStats = pair.effectiveStats(_battle.ally.charLevel);

    final displayMoves = pair
        .resolvedMoves(
          formIndex: _battle.ally.formIndex,
          showTera: isTeraActive,
        )
        .where((move) => move.power.isNotEmpty && move.power != '--')
        .toList();
    final masterPassives = _masterPassives;

    final labelStyle = TextStyle(
      fontSize: 11,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
    );

    final configWidgets = <Widget>[
      // Level selector
      Row(
        children: [
          Text('Level: ', style: labelStyle),
          if (levels.isNotEmpty)
            DropdownButton<String>(
              value: _battle.ally.charLevel,
              isDense: true,
              items: [
                for (final lv in levels)
                  DropdownMenuItem(
                    value: lv,
                    child: Text(
                      'Lv. $lv',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _battle.ally.charLevel = v!),
            )
          else
            Text('No data', style: labelStyle),
        ],
      ),
      const SizedBox(height: 6),

      // Star Level / EX / EX Role
      Row(
        children: [
          DropdownButton<String>(
            value: _battle.ally.starLevel,
            isDense: true,
            underline: const SizedBox(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            items: [
              for (final sl in availableStarLevels(pair.rarity, pair.hasEx))
                DropdownMenuItem(value: sl, child: Text(sl)),
            ],
            onChanged: (v) => setState(() => _battle.ally.starLevel = v!),
          ),
          if (pair.hasEx && pair.exRole.isNotEmpty) ...[
            const SizedBox(width: 6),
            FilterChip(
              label: Text(
                'EX Role (${pair.exRole})',
                style: TextStyle(
                  fontSize: 11,
                  color: _battle.ally.hasExRole ? Colors.white : null,
                ),
              ),
              selected: _battle.ally.hasExRole,
              showCheckmark: false,
              onSelected: (v) => setState(() => _battle.ally.hasExRole = v),
              selectedColor: Colors.indigo,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
      const SizedBox(height: 8),

      // Form selector
      if (pair.hasTera ||
          pair.variations.isNotEmpty ||
          pair.megaStatMultiplier.isNotEmpty ||
          pair.megaStats.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 6.0;
              int total = 1 + pair.variations.length;
              if (pair.hasTera) total += 1;
              if (pair.megaStatMultiplier.isNotEmpty ||
                  pair.megaStats.isNotEmpty) {
                total += 1;
              }
              final cols = math.max(2, (total + 2) ~/ 3);
              final tabWidth =
                  (constraints.maxWidth - spacing * (cols - 1)) / cols;
              Color variationColor(String formName) {
                final key = formName.toLowerCase();
                return consts.typeColors[key] ?? Colors.teal;
              }

              final tabs = <Widget>[
                _calcFormTab('Base', 0, width: tabWidth),
                for (int i = 0; i < pair.variations.length; i++)
                  _calcFormTab(
                    pair.variations[i].formName,
                    i + 1,
                    color: variationColor(pair.variations[i].formName),
                    width: tabWidth,
                  ),
                if (pair.hasTera)
                  _calcFormTab(
                    'Tera',
                    pair.variations.length + 1,
                    color: const Color(0xFF6C5CE7),
                    width: tabWidth,
                  ),
                if (pair.megaStatMultiplier.isNotEmpty ||
                    pair.megaStats.isNotEmpty)
                  Builder(
                    builder: (_) {
                      int megaIdx = pair.variations.length + 1;
                      if (pair.hasTera) megaIdx++;
                      return _calcFormTab(
                        'Mega',
                        megaIdx,
                        color: Colors.deepOrange,
                        width: tabWidth,
                      );
                    },
                  ),
              ];
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: tabs,
              );
            },
          ),
        ),

      // Field Effects
      _buildFieldSection(context),
      const SizedBox(height: 8),

      // Ally section
      Text(
        'Ally',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
      if (masterPassives.isNotEmpty) ...[
        const SizedBox(height: 4),
        _buildMasterPassivesSection(context, labelStyle),
      ],

      // Stats table
      if (currentStats.isNotEmpty)
        _buildAllyStatsTable(context, currentStats, labelStyle),
      const SizedBox(height: 4),

      _luckySkillRow(context, pair, labelStyle),
      const SizedBox(height: 4),

      Row(
        children: [
          FilterChip(
            label: const Text(
              'Move Gauge Acceleration',
              style: TextStyle(fontSize: 11),
            ),
            selected: _battle.ally.moveGaugeAccel,
            showCheckmark: false,
            onSelected: (v) => setState(() => _battle.ally.moveGaugeAccel = v),
            selectedColor: Colors.teal.withValues(alpha: 0.5),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Cheer', style: TextStyle(fontSize: 11)),
            selected: _battle.ally.cheer,
            showCheckmark: false,
            onSelected: (v) => setState(() => _battle.ally.cheer = v),
            selectedColor: Colors.amber.shade600,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
      const SizedBox(height: 4),

      // Acc/Eva/Crit/Sync buffs
      _buildAllyExtraFields(context, labelStyle),
      const SizedBox(height: 4),

      // Status and volatile status
      _buildAllyStatusSection(context, labelStyle),
      const SizedBox(height: 6),

      // Circles
      _buildCirclesSection(context, labelStyle),
      const SizedBox(height: 6),

      // User Type Rebuffs
      _buildRebuffsSection(
        labelStyle,
        _battle.ally.userTypeRebuffs,
        'Type Rebuffs',
        min: -3,
        max: 3,
      ),
      const SizedBox(height: 6),

      // Enemy section
      Text(
        'Enemy',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
      const SizedBox(height: 4),
      _buildEnemyConfig(context, labelStyle),
      const SizedBox(height: 8),

      Row(
        children: [
          FilterChip(
            label: const Text('Phys Break', style: TextStyle(fontSize: 10)),
            selected: _battle.ally.physicalBreak,
            showCheckmark: false,
            onSelected: (v) => setState(() => _battle.ally.physicalBreak = v),
            selectedColor: Colors.red.shade700,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
          FilterChip(
            label: const Text('Spec Break', style: TextStyle(fontSize: 10)),
            selected: _battle.ally.specialBreak,
            showCheckmark: false,
            onSelected: (v) => setState(() => _battle.ally.specialBreak = v),
            selectedColor: Colors.blue.shade700,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
      const SizedBox(height: 8),

      // Enemy Type Rebuffs
      _buildRebuffsSection(
        labelStyle,
        _battle.enemy.typeRebuffs,
        'Type Rebuffs',
      ),
      const SizedBox(height: 10),
    ];

    final moveWidgets = <Widget>[];
    if (displayMoves.isNotEmpty) {
      moveWidgets.addAll([
        Text(
          'Moves',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(height: 6),
        _buildMoveControls(context, labelStyle),
        const SizedBox(height: 6),
        for (final move in displayMoves)
          _buildMoveCalcCard(context, move, currentStats, isTeraActive),
      ]);
    }

    if (widget.expanded) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: configWidgets,
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: moveWidgets,
              ),
            ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [...configWidgets, ...moveWidgets],
      ),
    );
  }

  Widget _buildFieldSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Field Effects',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildFieldDropdown(
                context,
                'Zone',
                _battle.field.zone,
                consts.zoneOptions,
                consts.zoneBoostType,
                _battle.field.zoneEx,
                (v) => setState(() => _battle.field.zone = v ?? ''),
                onExToggle: (v) => setState(() => _battle.field.zoneEx = v),
              ),
              const SizedBox(width: 6),
              _buildFieldDropdown(
                context,
                'Terrain',
                _battle.field.terrain,
                consts.terrainOptions,
                consts.terrainBoostType,
                _battle.field.terrainEx,
                (v) => setState(() => _battle.field.terrain = v ?? ''),
                onExToggle: (v) => setState(() => _battle.field.terrainEx = v),
              ),
              const SizedBox(width: 6),
              _buildFieldDropdown(
                context,
                'Weather',
                _battle.field.weather,
                consts.weatherOptions,
                consts.weatherBoostType,
                _battle.field.weatherEx,
                (v) => setState(() => _battle.field.weather = v ?? ''),
                onExToggle: (v) => setState(() => _battle.field.weatherEx = v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFieldDropdown(
    BuildContext context,
    String label,
    String currentValue,
    List<String> options,
    Map<String, String> boostType,
    bool isEx,
    ValueChanged<String?> onChanged, {
    ValueChanged<bool>? onExToggle,
  }) {
    return Expanded(
      child: Row(
        children: [
          if (onExToggle != null)
            FilterChip(
              label: const Text('EX', style: TextStyle(fontSize: 11)),
              selected: isEx,
              showCheckmark: false,
              onSelected: onExToggle,
              selectedColor: Colors.deepPurple,
              visualDensity: VisualDensity.compact,
            ),
          const SizedBox(width: 4),
          Expanded(
            child: DropdownButton<String>(
              value: currentValue,
              isDense: true,
              isExpanded: true,
              underline: const SizedBox(),
              items: [
                for (final option in options)
                  DropdownMenuItem(
                    value: option,
                    child: Row(
                      children: [
                        Icon(
                          consts.fieldEffectIcons[option] ?? Icons.help_outline,
                          size: 16,
                          color: option.isNotEmpty
                              ? consts.typeColors[boostType[option]
                                        ?.toLowerCase()] ??
                                    Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _fieldLabel(label, option, isEx),
                          style: TextStyle(
                            fontSize: 12,
                            color: option.isNotEmpty
                                ? consts.typeColors[boostType[option]
                                      ?.toLowerCase()]
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  String _fieldLabel(String type, String value, bool isEx) {
    if (value.isEmpty) return 'None';
    if (!isEx) return value;
    if (type == 'Weather') {
      return (value == 'Sunny' || value == 'Rainy') ? 'EX $value' : value;
    }
    return 'EX $value';
  }

  Widget _buildMasterPassivesSection(
    BuildContext context,
    TextStyle labelStyle,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final passive in _masterPassives) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    passive.name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '+${(passive.powerUpForAdditionalAllies(_battle.ally.masterPassiveAllyCount[passive.name] ?? 0) * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(width: 8),
                Text('${passive.theme} allies:', style: labelStyle),
                const SizedBox(width: 4),
                DropdownButton<int>(
                  value: _battle.ally.masterPassiveAllyCount[passive.name] ?? 0,
                  isDense: true,
                  underline: const SizedBox(),
                  items: [
                    for (int i = 0; i <= 2; i++)
                      DropdownMenuItem(value: i, child: Text('+$i')),
                  ],
                  onChanged: (v) => setState(
                    () => _battle.ally.masterPassiveAllyCount[passive.name] =
                        v ?? 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              passive.appliesToSync
                  ? 'Applies to ${switch (passive.category) {
                      'physical' => 'physical moves and sync moves',
                      'special' => 'special moves and sync moves',
                      _ => 'moves and sync moves',
                    }}'
                  : 'Applies to ${switch (passive.category) {
                      'physical' => 'physical moves',
                      'special' => 'special moves',
                      _ => 'moves',
                    }}',
              style: labelStyle,
            ),
            if (passive != _masterPassives.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildAllyStatsTable(
    BuildContext context,
    Map<String, int> currentStats,
    TextStyle labelStyle,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: {
          0: const FixedColumnWidth(40),
          for (int i = 0; i < _statLabels.length; i++)
            i + 1: const FlexColumnWidth(),
        },
        children: [
          TableRow(
            children: [
              const SizedBox(),
              for (final s in _statLabels)
                Center(
                  child: Text(
                    _playerStatNames[s]!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          TableRow(
            children: [
              Text('Base', style: labelStyle),
              for (final s in _statLabels)
                Center(
                  child: Text(
                    '${_calcBaseStat(s, currentStats[s] ?? 0)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
            ],
          ),
          TableRow(
            children: [
              Text('Grid', style: labelStyle),
              for (final s in _statLabels)
                Builder(
                  builder: (_) {
                    final g = _gridStatBonus(s);
                    return Center(
                      child: Text(
                        g > 0 ? '+$g' : '-',
                        style: TextStyle(
                          fontSize: 11,
                          color: g > 0
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          TableRow(
            children: [
              Text('Gear', style: labelStyle),
              for (final s in _statLabels)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 2,
                  ),
                  child: SizedBox(
                    height: 24,
                    child: TextField(
                      controller: _gearControllers[s],
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 4,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(
                        () => _battle.ally.gear[s] = int.tryParse(v) ?? 0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          TableRow(
            children: [
              Text('Before Stage', style: labelStyle),
              for (final s in _statLabels)
                Center(
                  child: Text(
                    '${_calcBeforeStageStat(s, currentStats[s] ?? 0)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
            ],
          ),
          TableRow(
            children: [
              Text('Stage', style: labelStyle),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: SizedBox(
                  height: 24,
                  child: TextField(
                    controller: _playerHpPercentController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 4,
                      ),
                      border: OutlineInputBorder(),
                      suffixText: '%',
                      suffixStyle: TextStyle(fontSize: 9),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(
                      () => _battle.ally.hpPercent = (int.tryParse(v) ?? 100)
                          .clamp(0, 100),
                    ),
                  ),
                ),
              ),
              for (final s in _statLabels.skip(1))
                _stageCell(
                  _battle.ally.stages[s] ?? 0,
                  (v) => setState(() => _battle.ally.stages[s] = v),
                ),
            ],
          ),
          TableRow(
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              ),
              Center(
                child: Builder(
                  builder: (_) {
                    final total =
                        (_calcBeforeStageStat('hp', currentStats['hp'] ?? 0) *
                                _battle.ally.hpPercent /
                                100)
                            .round();
                    return Text(
                      '$total',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  },
                ),
              ),
              for (final s in _statLabels.skip(1))
                Builder(
                  builder: (_) {
                    final total = _calcTotalStat(
                      s,
                      currentStats[s] ?? 0,
                      _battle.ally.stages[s] ?? 0,
                    );
                    return Center(
                      child: Text(
                        '$total',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllyExtraFields(BuildContext context, TextStyle labelStyle) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Text('Acc: ', style: labelStyle),
          _stageCell(
            _battle.ally.stages['acc'] ?? 0,
            (v) => setState(() => _battle.ally.stages['acc'] = v),
          ),
          const SizedBox(width: 8),
          Text('Eva: ', style: labelStyle),
          _stageCell(
            _battle.ally.stages['eva'] ?? 0,
            (v) => setState(() => _battle.ally.stages['eva'] = v),
          ),
          const SizedBox(width: 8),
          Text('Crit: ', style: labelStyle),
          DropdownButton<int>(
            value: _battle.ally.stages['crit'] ?? 0,
            isDense: true,
            underline: const SizedBox(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: (_battle.ally.stages['crit'] ?? 0) > 0
                  ? Colors.blue
                  : Colors.black,
            ),
            items: [
              for (int i = 0; i <= 3; i++)
                DropdownMenuItem(value: i, child: Text('$i')),
            ],
            onChanged: (v) => setState(() => _battle.ally.stages['crit'] = v!),
          ),
          const SizedBox(width: 8),
          Text('Sync Buffs: ', style: labelStyle),
          SizedBox(
            width: 40,
            height: 24,
            child: TextField(
              controller: _playerSyncBoostsController,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 2,
                  vertical: 4,
                ),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) => setState(
                () => _battle.ally.syncBoosts = int.tryParse(v) ?? 0,
              ),
            ),
          ),
          const SizedBox(width: 4),
          if (_megaActive) ...[
            const SizedBox(width: 8),
            Text(
              'Mega: +$_megaSyncBaseBoosts ',
              style: TextStyle(fontSize: 11, color: Colors.blueGrey),
            ),
          ],
          Text(
            '×${(1 + _effectivePlayerSyncBoosts * 0.5).toStringAsFixed(1)}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _effectivePlayerSyncBoosts > 0 ? Colors.blue : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllyStatusSection(BuildContext context, TextStyle labelStyle) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Text('Status Change: ', style: labelStyle),
              const SizedBox(width: 4),
              for (final entry in _battle.ally.volatileStatus.entries) ...[
                FilterChip(
                  label: Text(
                    consts.statusLabel(entry.key),
                    style: TextStyle(
                      fontSize: 10,
                      color: entry.value ? Colors.white : null,
                    ),
                  ),
                  selected: entry.value,
                  showCheckmark: false,
                  onSelected: (v) => setState(
                    () => _battle.ally.volatileStatus[entry.key] = v,
                  ),
                  selectedColor: consts.statusColor(entry.key),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 4),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Text('Status Cond: ', style: labelStyle),
              DropdownButton<String>(
                value: _battle.ally.statusCondition,
                isDense: true,
                style: TextStyle(
                  fontSize: 12,
                  color: _battle.ally.statusCondition.isNotEmpty
                      ? consts.statusColor(_battle.ally.statusCondition)
                      : Colors.black,
                ),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('None', style: TextStyle(fontSize: 12)),
                  ),
                  for (final s in [
                    'burned',
                    'paralyzed',
                    'frozen',
                    'asleep',
                    'poisoned',
                    'badly poisoned',
                  ])
                    DropdownMenuItem(
                      value: s,
                      child: Text(
                        consts.statusLabel(s),
                        style: TextStyle(
                          fontSize: 12,
                          color: consts.statusColor(s),
                        ),
                      ),
                    ),
                ],
                onChanged: (v) =>
                    setState(() => _battle.ally.statusCondition = v!),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCirclesSection(BuildContext context, TextStyle labelStyle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Circles',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final region in _circleRegions)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    region,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final kind in ['physical', 'special', 'defensive'])
                        GestureDetector(
                          onTap: () => setState(
                            () => _battle.ally.circleActive[region]![kind] =
                                !_battle.ally.circleActive[region]![kind]!,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: Opacity(
                              opacity: _battle.ally.circleActive[region]![kind]!
                                  ? 1.0
                                  : 0.3,
                              child: Image.asset(
                                kind == 'physical'
                                    ? 'assets/img/battle/CATE_001.png'
                                    : kind == 'special'
                                    ? 'assets/img/battle/CATE_002.png'
                                    : 'assets/img/battle/CATE_004.png',
                                width: 16,
                                height: 16,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(
                    height: 24,
                    child: DropdownButton<int>(
                      value: _battle.ally.circleAllyCount[region]!,
                      isDense: true,
                      underline: const SizedBox(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      items: [
                        for (int j = 0; j <= 3; j++)
                          DropdownMenuItem(value: j, child: Text('$j')),
                      ],
                      onChanged: (v) => setState(
                        () => _battle.ally.circleAllyCount[region] = v!,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        Builder(
          builder: (_) {
            final active = _activeCircles();
            if (active.isEmpty) return const SizedBox();
            final offPhys = calcCircleOffenseMult(active, true);
            final offSpec = calcCircleOffenseMult(active, false);
            final defPhys = calcCircleDefenseMult(active, true);
            final defSpec = calcCircleDefenseMult(active, false);
            return Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Wrap(
                spacing: 12,
                children: [
                  if (offPhys != 1.0)
                    Text(
                      'Phys ×${offPhys.toStringAsFixed(3)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (offSpec != 1.0)
                    Text(
                      'Spec ×${offSpec.toStringAsFixed(3)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (defPhys != 1.0)
                    Text(
                      'Phys DR ×${defPhys.toStringAsFixed(3)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (defSpec != 1.0)
                    Text(
                      'Spec DR ×${defSpec.toStringAsFixed(3)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRebuffsSection(
    TextStyle labelStyle,
    Map<String, int> rebuffMap,
    String title, {
    int min = -3,
    int max = 0,
  }) {
    final types = title == 'Type Rebuffs'
        ? consts.allTypes.skip(1).toList()
        : CombatantState.allTypes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final type in types)
                TypeRebuffDropdown(
                  type: type,
                  value: rebuffMap[type] ?? 0,
                  min: min,
                  max: max,
                  onChanged: (v) => setState(() => rebuffMap[type] = v),
                ),
              if (title == 'Type Rebuffs')
                TypeRebuffDropdown(
                  type: 'Stellar',
                  value: _battle.enemy.stellarRebuff,
                  onChanged: (v) =>
                      setState(() => _battle.enemy.stellarRebuff = v),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnemyConfig(BuildContext context, TextStyle labelStyle) {
    return Column(
      children: [
        FilterChip(
          label: const Text(
            'Move Gauge Acceleration',
            style: TextStyle(fontSize: 11),
          ),
          selected: _battle.enemy.moveGaugeAccel,
          showCheckmark: false,
          onSelected: (v) => setState(() => _battle.enemy.moveGaugeAccel = v),
          selectedColor: Colors.red.withValues(alpha: 0.5),
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text('Damage Field: ', style: labelStyle),
            DropdownButton<String>(
              value: _battle.enemy.damageField,
              isDense: true,
              underline: const SizedBox(),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('None', style: TextStyle(fontSize: 12)),
                ),
                for (final t in consts.allTypes.skip(1))
                  DropdownMenuItem(
                    value: t,
                    child: Text(
                      '$t DF',
                      style: TextStyle(
                        fontSize: 12,
                        color: consts.typeColors[t.toLowerCase()],
                      ),
                    ),
                  ),
              ],
              onChanged: (v) =>
                  setState(() => _battle.enemy.damageField = v ?? ''),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text('Weakness: ', style: labelStyle),
            DropdownButton<String>(
              value: _battle.enemy.weakness,
              isDense: true,
              items: [
                for (final t in consts.weaknessTypes)
                  DropdownMenuItem(
                    value: t,
                    child: Text(
                      t.isEmpty ? 'None' : t,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _battle.enemy.weakness = v!),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: {
              0: const FixedColumnWidth(40),
              for (int i = 0; i < _statLabels.length; i++)
                i + 1: const FlexColumnWidth(),
            },
            children: [
              TableRow(
                children: [
                  const SizedBox(),
                  for (final s in _statLabels)
                    Center(
                      child: Text(
                        _enemyStatNames[s]!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              TableRow(
                children: [
                  Text('Base', style: labelStyle),
                  for (final s in _statLabels)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 2,
                      ),
                      child: SizedBox(
                        height: 24,
                        child: TextField(
                          controller: _enemyControllers[s],
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 4,
                            ),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setState(
                            () => _battle.enemy.manualStats[s] =
                                int.tryParse(v) ?? 0,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              TableRow(
                children: [
                  Text('Stage', style: labelStyle),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 2,
                    ),
                    child: SizedBox(
                      height: 24,
                      child: TextField(
                        controller: _enemyHpPercentController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 4,
                          ),
                          border: OutlineInputBorder(),
                          suffixText: '%',
                          suffixStyle: TextStyle(fontSize: 9),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => setState(
                          () => _battle.enemy.hpPercent =
                              (int.tryParse(v) ?? 100).clamp(0, 100),
                        ),
                      ),
                    ),
                  ),
                  for (final s in _statLabels.skip(1))
                    _stageCell(
                      _battle.enemy.stages[s] ?? 0,
                      (v) => setState(() => _battle.enemy.stages[s] = v),
                    ),
                ],
              ),
              TableRow(
                children: [
                  Text('Mitig.', style: labelStyle),
                  const Center(
                    child: Text('-', style: TextStyle(fontSize: 10)),
                  ),
                  for (final s in _statLabels.skip(1))
                    _mitigationCell(
                      _battle.enemy.mitigations[s] ?? 0,
                      (v) => setState(() => _battle.enemy.mitigations[s] = v),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Text('Acc: ', style: labelStyle),
              _stageCell(
                _battle.enemy.stages['acc'] ?? 0,
                (v) => setState(() => _battle.enemy.stages['acc'] = v),
              ),
              const SizedBox(width: 8),
              Text('Eva: ', style: labelStyle),
              _stageCell(
                _battle.enemy.stages['eva'] ?? 0,
                (v) => setState(() => _battle.enemy.stages['eva'] = v),
              ),
              const SizedBox(width: 8),
              Text('Sync Buffs: ', style: labelStyle),
              SizedBox(
                width: 40,
                height: 24,
                child: TextField(
                  controller: _enemySyncBoostsController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 4,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(
                    () => _battle.enemy.syncBoosts = int.tryParse(v) ?? 0,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '×${(1 + _battle.enemy.syncBoosts * 0.5).toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _battle.enemy.syncBoosts > 0 ? Colors.red : null,
                ),
              ),
              const SizedBox(width: 8),
              Text('Status Cond: ', style: labelStyle),
              DropdownButton<String>(
                value: _battle.enemy.statusCondition,
                isDense: true,
                style: TextStyle(
                  fontSize: 12,
                  color: _battle.enemy.statusCondition.isNotEmpty
                      ? consts.statusColor(_battle.enemy.statusCondition)
                      : Colors.black,
                ),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('None', style: TextStyle(fontSize: 12)),
                  ),
                  for (final s in [
                    'burned',
                    'paralyzed',
                    'frozen',
                    'asleep',
                    'poisoned',
                    'badly poisoned',
                  ])
                    DropdownMenuItem(
                      value: s,
                      child: Text(
                        consts.statusLabel(s),
                        style: TextStyle(
                          fontSize: 12,
                          color: consts.statusColor(s),
                        ),
                      ),
                    ),
                ],
                onChanged: (v) =>
                    setState(() => _battle.enemy.statusCondition = v!),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Text('Status Change: ', style: labelStyle),
              const SizedBox(width: 4),
              for (final entry in _battle.enemy.volatileStatus.entries) ...[
                FilterChip(
                  label: Text(
                    consts.statusLabel(entry.key),
                    style: TextStyle(
                      fontSize: 10,
                      color: entry.value ? Colors.white : null,
                    ),
                  ),
                  selected: entry.value,
                  showCheckmark: false,
                  onSelected: (v) => setState(
                    () => _battle.enemy.volatileStatus[entry.key] = v,
                  ),
                  selectedColor: consts.statusColor(entry.key),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 4),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMoveControls(BuildContext context, TextStyle labelStyle) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Text('Phys Up Next: ', style: labelStyle),
          DropdownButton<int>(
            value: _battle.ally.physicalBoostNext,
            isDense: true,
            underline: const SizedBox(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            items: [
              for (int i = 0; i <= 10; i++)
                DropdownMenuItem(value: i, child: Text('$i')),
            ],
            onChanged: (v) =>
                setState(() => _battle.ally.physicalBoostNext = v!),
          ),
          const SizedBox(width: 8),
          Text('Spec Up Next: ', style: labelStyle),
          DropdownButton<int>(
            value: _battle.ally.specialBoostNext,
            isDense: true,
            underline: const SizedBox(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            items: [
              for (int i = 0; i <= 10; i++)
                DropdownMenuItem(value: i, child: Text('$i')),
            ],
            onChanged: (v) =>
                setState(() => _battle.ally.specialBoostNext = v!),
          ),
          const SizedBox(width: 8),
          Text('Sync Up Next: ', style: labelStyle),
          DropdownButton<int>(
            value: _battle.ally.syncMoveBoostNext,
            isDense: true,
            underline: const SizedBox(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            items: [
              for (int i = 0; i <= 10; i++)
                DropdownMenuItem(value: i, child: Text('$i')),
            ],
            onChanged: (v) =>
                setState(() => _battle.ally.syncMoveBoostNext = v!),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('SEUN', style: TextStyle(fontSize: 10)),
            selected: _battle.ally.superEffectiveNext,
            showCheckmark: false,
            onSelected: (v) =>
                setState(() => _battle.ally.superEffectiveNext = v),
            selectedColor: Colors.orange,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Crit', style: TextStyle(fontSize: 10)),
            selected: _battle.ally.isCriticalMove,
            showCheckmark: false,
            onSelected: (v) => setState(() => _battle.ally.isCriticalMove = v),
            selectedColor: Colors.red,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 8),
          Text('Enemies: ', style: labelStyle),
          DropdownButton<int>(
            value: _battle.field.targetCount,
            isDense: true,
            underline: const SizedBox(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            items: const [
              DropdownMenuItem(value: 1, child: Text('1')),
              DropdownMenuItem(value: 2, child: Text('2')),
              DropdownMenuItem(value: 3, child: Text('3')),
            ],
            onChanged: (v) => setState(() => _battle.field.targetCount = v!),
          ),
        ],
      ),
    );
  }

  Widget _buildMoveCalcCard(
    BuildContext context,
    MoveData move,
    Map<String, int> currentStats,
    bool isTeraActive,
  ) {
    final hasPower = move.power.isNotEmpty && move.power != '--';
    final bp = hasPower ? _totalBp(move) : null;
    final isPhysical = move.category.toLowerCase() == 'physical';
    final atkKey = isPhysical ? 'atk' : 'spa';
    final forceMega = _usesMegaSyncStats(move);
    final defStat =
        _battle.enemy.manualStats[isPhysical ? 'def' : 'spd'] ?? 100;
    List<int>? rolls;
    if (bp != null && bp > 0) {
      final atkTotal = calcStat(
        StatInput(
          baseStat: _calcBeforeStageStat(
            atkKey,
            currentStats[atkKey] ?? 0,
            forceMega: forceMega,
          ),
          stage: _battle.ally.stages[atkKey] ?? 0,
        ),
      );
      final defKey = isPhysical ? 'def' : 'spd';
      final enemyDefTotal = calcStat(
        StatInput(
          baseStat: defStat,
          stage: _battle.enemy.stages[defKey] ?? 0,
          mitigation: _battle.enemy.mitigations[defKey] ?? 0,
        ),
      );
      final isSE =
          _battle.enemy.weakness.isNotEmpty &&
          move.type.toLowerCase() == _battle.enemy.weakness.toLowerCase();
      final moveType = move.type.isNotEmpty
          ? move.type[0].toUpperCase() + move.type.substring(1).toLowerCase()
          : '';
      final rebuffLookupType = moveType == 'Stellar' ? 'Normal' : moveType;
      final rebuff = _battle.enemy.typeRebuffs[rebuffLookupType] ?? 0;
      final stellarRebuff = moveType == 'Stellar'
          ? _battle.enemy.stellarRebuff
          : 0;
      final zoneBoost =
          _battle.field.zone.isNotEmpty &&
          consts.zoneBoostType[_battle.field.zone]?.toLowerCase() ==
              moveType.toLowerCase();
      final terrainBoost =
          _battle.field.terrain.isNotEmpty &&
          consts.terrainBoostType[_battle.field.terrain]?.toLowerCase() ==
              moveType.toLowerCase();
      final weatherBoost =
          _battle.field.weather.isNotEmpty &&
          consts.weatherBoostType[_battle.field.weather]?.toLowerCase() ==
              moveType.toLowerCase();
      final result = calcDamage(
        moveInput: MovePowerInput(
          basePower: bp,
          moveLevel: 1,
          gridPower: 0,
          boostRank: 0,
          skillPowerUps: 0,
        ),
        attackerInput: StatInput(baseStat: atkTotal),
        defenderStat: enemyDefTotal,
        conditions: BattleConditions(
          syncBoosts: _effectivePlayerSyncBoosts,
          isCritical: _battle.ally.isCriticalMove,
          isSuperEffective: isSE,
          hasSENext: _battle.ally.superEffectiveNext,
          typeRebuff: rebuff,
          stellarRebuff: stellarRebuff,
          zoneBoost: zoneBoost,
          zoneEx: _battle.field.zoneEx,
          terrainBoost: terrainBoost,
          terrainEx: _battle.field.terrainEx,
          weatherBoost: weatherBoost,
          weatherEx: _battle.field.weatherEx,
          physicalBreak:
              isPhysical && _battle.ally.physicalBreak && !move.isSync,
          specialBreak:
              !isPhysical && _battle.ally.specialBreak && !move.isSync,
          isPhysicalMove: isPhysical,
          targetCount: _effectiveTargetCount(move),
          circles: _activeCircles(),
        ),
      );
      rolls = result.rolls;
      if (_battle.ally.cheer) {
        rolls = rolls.map((r) => (r * 1.5).round()).toList();
      }
    }
    final isTeraMove =
        widget.pair.teraMove != null && move.name == widget.pair.teraMove!.name;
    final moveTeraBoost =
        isTeraActive &&
        !move.isSync &&
        !isTeraMove &&
        move.type.toLowerCase() == widget.pair.type.toLowerCase();
    final tooltipLines = <String>[];
    if (bp != null) {
      final saBonus = calcSaBonus(widget.pair, _superAwakeningLevel, move);
      tooltipLines.add(
        'Base Power: ${calcScaledPower(move.power, widget.moveLevel, saBonus)}',
      );
      if (move.isSync && _syncTechExBoost)
        tooltipLines.add('6EX Tech Sync Move ×1.5');
      if (moveTeraBoost) tooltipLines.add('Tera Boost ×1.5');
      final gp = _gridPowerBonus(move.name);
      if (gp > 0) tooltipLines.add('Grid Power: +$gp (additive)');
      final masterPassiveSkill = _masterPassivePowerUp(move);
      if (masterPassiveSkill > 0) {
        tooltipLines.add(
          'Master Passive +${(masterPassiveSkill * 100).toStringAsFixed(0)}%',
        );
      }
      final boostRank = move.isSync
          ? 0
          : (isPhysical
                ? _battle.ally.physicalBoostNext
                : _battle.ally.specialBoostNext);
      if (boostRank > 0) {
        tooltipLines.add(
          '${isPhysical ? 'Phys' : 'Spec'} Up Next +${(boostRank * 40).toStringAsFixed(0)}%',
        );
      }
      if (move.isSync && _battle.ally.syncMoveBoostNext > 0) {
        tooltipLines.add(
          'Sync Up Next +${(_battle.ally.syncMoveBoostNext * 10).toStringAsFixed(0)}%',
        );
      }
      for (final skill in _gridSkillPowerUpDetails(move)) {
        tooltipLines.add(
          '${skill.name} +${(skill.value * 100).toStringAsFixed(0)}%',
        );
      }
      final moveMod = _movePowerModifier(move);
      if (moveMod != 1.0) {
        tooltipLines.add('Move Modifier ×${moveMod.toStringAsFixed(3)}');
      }
      if (_battle.ally.cheer) tooltipLines.add('Cheer ×1.5');
    }
    final hasBpMod =
        moveTeraBoost ||
        _gridPowerBonus(move.name) > 0 ||
        _masterPassivePowerUp(move) > 0 ||
        _gridSkillPowerUp(move) > 0 ||
        _movePowerModifier(move) != 1.0 ||
        (move.isSync
            ? _battle.ally.syncMoveBoostNext > 0
            : (isPhysical
                  ? _battle.ally.physicalBoostNext > 0
                  : _battle.ally.specialBoostNext > 0));
    final saBonusForMove = calcSaBonus(widget.pair, _superAwakeningLevel, move);
    final baseBpVal = int.tryParse(
      calcScaledPower(move.power, widget.moveLevel, saBonusForMove),
    );
    final isExtendedRange = move.isExtendedRange;
    final isAreaSync = move.isSync && _hasExpandedSync();
    final autoSyncBoosts = _effectivePlayerSyncBoosts - _battle.ally.syncBoosts;

    return CalcMoveCard(
      move: MoveCardData(
        name: move.name,
        type: move.type,
        category: move.category,
        isSync: move.isSync,
      ),
      totalBp: bp,
      baseBp: baseBpVal,
      hasBpMod: hasBpMod,
      teraBoost: moveTeraBoost,
      isExtendedRange: isExtendedRange,
      isAreaSync: isAreaSync,
      autoSyncBoosts: autoSyncBoosts,
      atkStat: rolls != null
          ? calcStat(
              StatInput(
                baseStat: _calcBeforeStageStat(
                  atkKey,
                  currentStats[atkKey] ?? 0,
                  forceMega: forceMega,
                ),
                stage: _battle.ally.stages[atkKey] ?? 0,
              ),
            )
          : null,
      rolls: rolls,
      enemyHp:
          ((_battle.enemy.manualStats['hp'] ?? 1) *
                  _battle.enemy.hpPercent /
                  100)
              .round(),
      tooltipText: tooltipLines.join('\n'),
    );
  }
}
