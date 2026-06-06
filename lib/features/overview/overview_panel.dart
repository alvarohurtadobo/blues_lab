import 'package:flutter/material.dart';

import '../../helpers/damage_helpers.dart';
import '../../models/sync_pair_models.dart';
import '../../star_level.dart';
import '../../constants/type_data.dart' as consts;
import '../../widgets/move_card.dart';
import '../../widgets/passive_card.dart';

class SyncPairOverview extends StatefulWidget {
  const SyncPairOverview({
    super.key,
    required this.pair,
    required this.moveLevel,
    required this.activeCells,
    required this.superAwakeningLevel,
  });

  final SyncPairData pair;
  final int moveLevel;
  final Set<int> activeCells;
  final int superAwakeningLevel;

  @override
  State<SyncPairOverview> createState() => _SyncPairOverviewState();
}

class _SyncPairOverviewState extends State<SyncPairOverview> {
  int _formIndex = 0;
  String _level = '200';
  String? _starLevel;
  bool _exRoleActive = true;

  int get _superAwakeningLevel => widget.superAwakeningLevel;

  @override
  void didUpdateWidget(covariant SyncPairOverview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pair.number != oldWidget.pair.number) {
      _starLevel = null;
    }
  }

  String get _effectiveStarLevel {
    final valid = availableStarLevels(pair.rarity, pair.hasEx);
    if (_starLevel != null && valid.contains(_starLevel)) return _starLevel!;
    return valid.last;
  }

  SyncPairData get pair => widget.pair;
  bool get _showTera =>
      pair.hasTera && _formIndex == pair.variations.length + 1;
  bool get _isVariation =>
      _formIndex > 0 && _formIndex <= pair.variations.length;
  VariationData? get _activeVariation =>
      _isVariation ? pair.variations[_formIndex - 1] : null;

  int _gridBonus2(String statKey) {
    const mapping = {
      'hp': 'HP',
      'atk': 'Attack',
      'def': 'Defense',
      'spa': 'Sp. Atk',
      'spd': 'Sp. Def',
      'spe': 'Speed',
    };
    final prefix = mapping[statKey] ?? '';
    if (prefix.isEmpty) return 0;
    int total = 0;
    for (final cell in pair.cells) {
      if (!widget.activeCells.contains(cell.cellNumber)) continue;
      final t = cell.title.trim();
      if (t.startsWith(prefix)) {
        final val = int.tryParse(t.substring(prefix.length).trim());
        if (val != null) total += val;
      }
    }
    return total;
  }

  Map<String, int> _potentialBonus() => calcPotentialBonus(
    baseRarity: pair.rarity,
    targetStars: _effectiveStarLevel,
  );

  bool get _exActive => _effectiveStarLevel == '5★ EX';

  bool get _megaActiveOverview {
    if (pair.megaStatMultiplier.isEmpty) return false;
    int megaIdx = pair.variations.length + 1;
    if (pair.hasTera) megaIdx++;
    return _formIndex == megaIdx;
  }

  int _exBonusOverview(String stat) {
    if (!_exActive || !pair.hasEx) return 0;
    int total = exBaseBonus[stat] ?? 0;
    if (_exRoleActive && pair.exRole.isNotEmpty) {
      total += lookupExRoleBonus(pair.exRole)?[stat] ?? 0;
    }
    return total;
  }

  double _megaMultOverview(String stat) {
    if (!_megaActiveOverview) return 1.0;
    return pair.megaStatMultiplier[stat] ?? 1.0;
  }

  Map<String, int> _interpolatedStats() {
    if (pair.stats.isEmpty) return {};
    return pair.effectiveStats(_level);
  }

  int _overviewTotal(String stat, int baseStat) {
    final base = calcOverviewStat(
      baseStat: baseStat,
      potentialBonus: _potentialBonus(),
      exBonus: _exBonusOverview(stat),
      formMult: _megaMultOverview(stat),
      stat: stat,
      hasSA: pair.hasSuperAwakening,
      saLevel: _superAwakeningLevel,
      role: pair.role,
    );
    final varMult = pair.variationStatMult(_formIndex, stat);
    if (varMult == 1.0) return base;
    return (base * varMult).floor();
  }

  Widget _formTab(String label, int index, {Color? color}) {
    final selected = _formIndex == index;
    final tabColor = color ?? Theme.of(context).colorScheme.primary;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _formIndex = index),
        child: Container(
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
      ),
    );
  }

  bool get _isEx => _effectiveStarLevel == '5★ EX';

  bool get _syncTechExBoost {
    if (!_isEx || !pair.hasEx) return false;
    final role = pair.role.toLowerCase().trim();
    final exRole = pair.exRole.toLowerCase().trim();
    return role == 'tech' || (_exRoleActive && exRole == 'tech');
  }

  int _gridBonus(String moveName, String stat) {
    int total = 0;
    final prefix = '$moveName: $stat ';
    for (final cell in widget.pair.cells) {
      if (!widget.activeCells.contains(cell.cellNumber)) continue;
      if (!cell.title.startsWith(prefix)) continue;
      final numStr = cell.title.substring(prefix.length).trim();
      final val = int.tryParse(numStr);
      if (val != null) total += val;
    }
    return total;
  }

  Widget _typeChip(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: consts.typeColor(type),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _moveCard(BuildContext context, MoveData move, String teraMoveName) {
    final saBonus = calcSaBonus(pair, _superAwakeningLevel, move);
    return MoveCard(
      moveName: move.name,
      typeColor: consts.typeColor(move.type),
      typeChip: move.type.isNotEmpty ? _typeChip(move.type) : null,
      powerBonus: _gridBonus(move.name, 'Power'),
      accBonus: _gridBonus(move.name, 'Accuracy'),
      basePower: calcScaledPower(move.power, widget.moveLevel, saBonus),
      moveCategory: move.category,
      moveType: move.type,
      moveAccuracy: move.accuracy,
      moveGauge: move.gauge,
      moveTarget: move.target,
      moveDescription: move.description,
      isSync: move.isSync,
      teraBoost:
          _showTera &&
          move.type.toLowerCase() == pair.type.toLowerCase() &&
          move.name != teraMoveName &&
          !move.isSync,
      syncTechBoost: move.isSync && _syncTechExBoost,
    );
  }

  Widget _passiveCard(BuildContext context, PassiveData passive) {
    return PassiveCard(passive: passive);
  }

  List<PassiveData> _applyPassiveReplacements(
    List<PassiveData> base,
    List<PassiveData> replacements,
  ) {
    final result = <PassiveData>[];
    int replIdx = 0;
    for (int i = 0; i < base.length; i++) {
      final p = base[i];
      if (i == 0) {
        result.add(p);
      } else if (replIdx < replacements.length) {
        result.add(replacements[replIdx++]);
      } else {
        result.add(p);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    List<MoveData> displayMoves;
    List<PassiveData> displayPassives;
    displayMoves = pair.resolvedMoves(
      formIndex: _formIndex,
      showTera: _showTera,
    );
    if (_showTera) {
      displayPassives = _applyPassiveReplacements(
        pair.passives,
        pair.teraPassives,
      );
    } else if (_isVariation && _activeVariation != null) {
      displayPassives = _applyPassiveReplacements(
        pair.passives,
        _activeVariation!.passives,
      );
    } else {
      displayPassives = pair.passives;
    }
    if (pair.hasSuperAwakening &&
        _superAwakeningLevel < 5 &&
        displayPassives.isNotEmpty) {
      displayPassives = displayPassives
          .where((p) => p != pair.passives.first)
          .toList();
    }
    final teraMoveName = pair.teraMove?.name ?? '';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (pair.role.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    pair.role,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              if (pair.exRole.isNotEmpty) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'EX: ${pair.exRole}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              if (pair.type.isNotEmpty) _typeChip(pair.type),
            ],
          ),
          if (pair.hasTera ||
              pair.variations.isNotEmpty ||
              pair.megaStatMultiplier.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  _formTab('Base', 0),
                  for (int i = 0; i < pair.variations.length; i++) ...[
                    const SizedBox(width: 6),
                    _formTab(
                      pair.variations[i].formName,
                      i + 1,
                      color: Colors.teal,
                    ),
                  ],
                  if (pair.hasTera) ...[
                    const SizedBox(width: 6),
                    _formTab(
                      'Tera',
                      pair.variations.length + 1,
                      color: const Color(0xFF6C5CE7),
                    ),
                  ],
                  if (pair.megaStatMultiplier.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Builder(
                      builder: (_) {
                        int megaIdx = pair.variations.length + 1;
                        if (pair.hasTera) megaIdx++;
                        return _formTab(
                          'Mega',
                          megaIdx,
                          color: Colors.deepOrange,
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          if (pair.stats.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Builder(
                builder: (_) {
                  final s = _interpolatedStats();
                  const labels = [
                    'HP',
                    'Atk',
                    'Def',
                    'Sp.Atk',
                    'Sp.Def',
                    'Spe',
                  ];
                  const keys = ['hp', 'atk', 'def', 'spa', 'spd', 'spe'];
                  final levels = pair.stats.keys.toList()
                    ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
                  if (!levels.contains(_level)) _level = levels.last;
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Stats',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            DropdownButton<String>(
                              value: _level,
                              isDense: true,
                              underline: const SizedBox(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                              items: [
                                for (final lv in levels)
                                  DropdownMenuItem(
                                    value: lv,
                                    child: Text('Lv. $lv'),
                                  ),
                              ],
                              onChanged: (v) => setState(() => _level = v!),
                            ),
                            const Spacer(),
                            DropdownButton<String>(
                              value: _effectiveStarLevel,
                              isDense: true,
                              underline: const SizedBox(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                              items: [
                                for (final sl in availableStarLevels(
                                  pair.rarity,
                                  pair.hasEx,
                                ))
                                  DropdownMenuItem(value: sl, child: Text(sl)),
                              ],
                              onChanged: (v) => setState(() => _starLevel = v!),
                            ),
                            if (pair.hasEx && pair.exRole.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              FilterChip(
                                label: Text(
                                  'EX ${pair.exRole}',
                                  style: const TextStyle(fontSize: 10),
                                ),
                                selected: _exRoleActive,
                                showCheckmark: false,
                                onSelected: (v) =>
                                    setState(() => _exRoleActive = v),
                                selectedColor: Colors.indigo,
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const SizedBox(width: 30),
                            for (int i = 0; i < 6; i++)
                              Expanded(
                                child: Center(
                                  child: Text(
                                    labels[i],
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const SizedBox(
                              width: 30,
                              child: Text(
                                'Base',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            for (int i = 0; i < 6; i++)
                              Expanded(
                                child: Center(
                                  child: Text(
                                    '${_overviewTotal(keys[i], s[keys[i]] ?? 0)}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Row(
                          children: [
                            const SizedBox(
                              width: 30,
                              child: Text(
                                'Grid',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            for (int i = 0; i < 6; i++)
                              Expanded(
                                child: Center(
                                  child: Builder(
                                    builder: (_) {
                                      final g = _gridBonus2(keys[i]);
                                      return Text(
                                        g > 0 ? '+$g' : '-',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: g > 0
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : Colors.grey,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Builder(
                          builder: (_) {
                            return Row(
                              children: [
                                const SizedBox(
                                  width: 30,
                                  child: Text(
                                    'Total',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                for (int i = 0; i < 6; i++)
                                  Expanded(
                                    child: Center(
                                      child: Builder(
                                        builder: (_) {
                                          final base = s[keys[i]] ?? 0;
                                          final grid = _gridBonus2(keys[i]);
                                          return Text(
                                            '${_overviewTotal(keys[i], base) + grid}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          if (pair.passives.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                'Passives',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
            for (final passive in displayPassives)
              _passiveCard(context, passive),
          ],
          if (pair.moves.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 8),
              child: Text(
                'Moves',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
            for (final move in displayMoves)
              _moveCard(context, move, teraMoveName),
          ],
        ],
      ),
    );
  }
}
