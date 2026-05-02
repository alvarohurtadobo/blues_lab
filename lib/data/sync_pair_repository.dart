import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/future_rules.dart';
import '../models/sync_pair_models.dart';

class SyncPairRepository {
  const SyncPairRepository();

  Future<ParsedData> load() async {
    final jsonStr = await rootBundle.loadString('assets/data/sync_pairs.json');
    final jsonList = json.decode(jsonStr) as List<dynamic>;

    // Load move scaling data
    final scalingStr = await rootBundle.loadString('assets/data/move_scaling.json');
    final scalingList = json.decode(scalingStr) as List<dynamic>;
    // Key: "pairName|moveName" -> MoveScaling
    final scalingMap = <String, MoveScaling>{};
    for (final entry in scalingList) {
      final e = entry as Map<String, dynamic>;
      final key = '${e['syncPair']}|${e['moveName']}';
      scalingMap[key] = MoveScaling(
        stat: (e['stat'] ?? '') as String,
        who: (e['who'] ?? 'user') as String,
        direction: (e['direction'] ?? 'raised') as String,
        stepPer1000: (e['stepPer1000'] as num?)?.toInt() ?? 0,
        thresholdTable: (e['thresholdTable'] as List? ?? const [])
            .map((t) {
              final row = t as Map<String, dynamic>;
              return ThresholdEntry(
                minPct: (row['minPct'] as num).toInt(),
                multiplierPer1000: (row['multiplierPer1000'] as num).toInt(),
              );
            })
            .toList(),
        capPer1000: (e['capPer1000'] as num?)?.toInt() ?? 0,
      );
    }

    // Load master passive definitions
    final dpStr = await rootBundle.loadString('assets/data/damage_passives.json');
    final dpMasterList = json.decode(dpStr) as List<dynamic>;
    final dpMasterMap = <String, DamagePassive>{};
    for (final entry in dpMasterList) {
      final e = entry as Map<String, dynamic>;
      final moveName = (e['move_name'] ?? '') as String;
      final name = (e['name'] ?? '') as String;
      final key = moveName.isEmpty ? name : '$name|$moveName';
      dpMasterMap[key] = _parseDamagePassive(e);
    }

    // Load master passives data
    final mpStr = await rootBundle.loadString('assets/data/master_passives.json');
    final mpList = json.decode(mpStr) as List<dynamic>;
    final mpMap = <String, List<MasterPassiveData>>{};
    for (final entry in mpList) {
      final e = entry as Map<String, dynamic>;
      final pairName = (e['syncPair'] ?? '') as String;
      mpMap.putIfAbsent(pairName, () => []).add(MasterPassiveData(
        name: (e['passiveName'] ?? '') as String,
        theme: (e['theme'] ?? '') as String,
        category: (e['category'] ?? 'any') as String,
        appliesToSync: e['appliesToSync'] == true,
        basePowerUpPct: (e['basePowerUpPct'] as num?)?.toInt() ?? 10,
        perAdditionalAllyPct: (e['perAdditionalAllyPct'] as num?)?.toInt() ?? 5,
        maxPowerUpPct: (e['maxPowerUpPct'] as num?)?.toInt() ?? 20,
      ));
    }

    final pairs =
        jsonList
            .map((entry) => _parsePair(entry as Map<String, dynamic>, scalingMap, dpMasterMap, mpMap))
            .toList()
          ..sort((left, right) {
            final leftDate = left.releaseDate ?? DateTime(2000);
            final rightDate = right.releaseDate ?? DateTime(2000);
            return rightDate.compareTo(leftDate);
          });

    return ParsedData(pairs: pairs);
  }

  SyncPairData _parsePair(Map<String, dynamic> jsonMap, Map<String, MoveScaling> scalingMap, Map<String, DamagePassive> dpMasterMap, Map<String, List<MasterPassiveData>> mpMap) {
    final pairName = (jsonMap['displayName'] ?? '') as String;
    final pairType = (jsonMap['type'] ?? '') as String;
    final pairRole = (jsonMap['role'] ?? '') as String;
    final exRole = (jsonMap['exRole'] ?? '') as String;
    final weakness = (jsonMap['weakness'] ?? '') as String;

    final cells = (jsonMap['cells'] as List? ?? const [])
        .map((entry) => _parseCell(entry as Map<String, dynamic>))
        .toList();

    final moves = (jsonMap['moves'] as List? ?? const [])
        .map(
          (entry) =>
              _parseMove(entry as Map<String, dynamic>, pairType: pairType, pairName: pairName, scalingMap: scalingMap),
        )
        .toList();

    final passives = (jsonMap['passives'] as List? ?? const [])
        .map((entry) => _parsePassive(entry as Map<String, dynamic>))
        .toList();

    final teraPassives = (jsonMap['teraPassives'] as List? ?? const [])
        .map((entry) => _parsePassive(entry as Map<String, dynamic>))
        .toList();

    final pairTags = <PairTag>[
      if (pairType.isNotEmpty) PairTag(category: 'type', value: pairType),
      if (pairRole.isNotEmpty) PairTag(category: 'role', value: pairRole),
      if (exRole.isNotEmpty) PairTag(category: 'ex_role', value: exRole),
      if (weakness.isNotEmpty) PairTag(category: 'weakness', value: weakness),
      ..._extractThemeTags(jsonMap),
      ..._extractMoveEffectTags(moves),
      ..._extractPassiveTags(passives),
    ];

    final rules = [
      for (final passive in passives) passive.rule,
      for (final passive in teraPassives) passive.rule,
    ];

    return SyncPairData(
      number: (jsonMap['number'] as num?)?.toInt() ?? 0,
      displayName: (jsonMap['displayName'] ?? '') as String,
      role: pairRole,
      exRole: exRole,
      type: pairType,
      weakness: weakness,
      rarity: (jsonMap['rarity'] as num?)?.toInt() ?? 5,
      hasEx: jsonMap['hasEx'] == true,
      hasSuperAwakening: jsonMap['hasSuperAwakening'] == true,
      cells: cells,
      releaseDate: DateTime.tryParse((jsonMap['releaseDate'] ?? '') as String),
      syncMoveName: (jsonMap['syncMoveName'] ?? '') as String,
      moves: moves,
      passives: passives,
      description: '',
      hasTera: jsonMap['hasTera'] == true,
      teraMove: _parseOptionalMove(jsonMap['teraMove'], pairType: pairType, pairName: pairName, scalingMap: scalingMap),
      teraPassives: teraPassives,
      stats: _parseNestedStats(jsonMap['stats'] as Map<String, dynamic>?),
      teraStatMultiplier: _parseTeraStatMultiplier(jsonMap),
      megaStatMultiplier: _parseMegaStatMultiplier(
        jsonMap['megaStatMultiplier'] as Map<String, dynamic>?,
      ),
      megaStats: _parseNestedStats(
        jsonMap['megaStats'] as Map<String, dynamic>?,
      ),
      formStats: _parseFormStats(jsonMap['formStats'] as Map<String, dynamic>?),
      variations: _parseVariations(jsonMap['variations'] as List?, pairName: pairName, scalingMap: scalingMap),
      tags: _dedupeTags(pairTags),
      rules: rules
          .where(
            (rule) => rule.conditions.isNotEmpty || rule.effects.isNotEmpty,
          )
          .toList(),
      damagePassives: _resolveDamagePassives(jsonMap['damagePassives'] as List? ?? const [], dpMasterMap),
      masterPassives: mpMap[pairName] ?? const [],
    );
  }

  GridCellData _parseCell(Map<String, dynamic> jsonMap) {
    final title = (jsonMap['title'] ?? '') as String;
    final colorKind = (jsonMap['colorKind'] ?? 'Unknown') as String;
    final subPassivesRaw = jsonMap['subPassives'] as List? ?? const [];
    final subPassives = subPassivesRaw
        .map((e) => SubPassiveData(
              name: (e as Map<String, dynamic>)['name'] as String? ?? '',
              description: e['description'] as String? ?? '',
              value: (e['value'] as num?)?.toInt() ?? 0,
            ))
        .toList();

    final Map<String, int> statBonus;
    final Map<String, int> powerBonus;

    if (jsonMap.containsKey('statBonus')) {
      statBonus = (jsonMap['statBonus'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, (v as num).toInt()));
      powerBonus = (jsonMap['powerBonus'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, (v as num).toInt()));
    } else {
      // Fallback for cells without pre-computed bonus fields
      statBonus = <String, int>{};
      powerBonus = <String, int>{};
      final titleLower = title.toLowerCase();
      final match = RegExp(r'(\d+)$').firstMatch(title);
      if (match != null) {
        final val = int.tryParse(match.group(1)!);
        if (val != null) {
          if (titleLower.contains('hp')) statBonus['hp'] = val;
          else if (titleLower.contains('sp.atk') || titleLower.contains('sp.attack')) statBonus['spa'] = val;
          else if (titleLower.contains('attack')) statBonus['atk'] = val;
          else if (titleLower.contains('defense')) statBonus['def'] = val;
          else if (titleLower.contains('sp.def') || titleLower.contains('sp.defense')) statBonus['spd'] = val;
          else if (titleLower.contains('speed')) statBonus['spe'] = val;
          else if (titleLower.contains(': power')) {
            final moveName = title.split(':')[0].trim();
            powerBonus[moveName] = val;
          }
        }
      }
    }

    return GridCellData(
      cellNumber: (jsonMap['cellNumber'] as num?)?.toInt() ?? 0,
      q: (jsonMap['q'] as num?)?.toInt() ?? 0,
      r: (jsonMap['r'] as num?)?.toInt() ?? 0,
      s: (jsonMap['s'] as num?)?.toInt() ?? 0,
      energyCost: (jsonMap['energyCost'] as num?)?.toInt() ?? 0,
      orbCost: (jsonMap['orbCost'] as num?)?.toInt() ?? 0,
      title: title,
      description: (jsonMap['description'] ?? '') as String,
      colorKind: colorKind,
      moveLevel: (jsonMap['moveLevel'] as num?)?.toInt() ?? 1,
      tags: _dedupeTags([
        PairTag(category: 'grid_kind', value: colorKind),
        ..._tileTags(title, colorKind),
      ]),
      effects: powerBonus.entries
          .map((e) => PassiveEffect(
                kind: EffectKind.powerModifier,
                scope: EntityScope.self,
                value: e.value.toDouble(),
                flag: colorKind,
              ))
          .toList(),
      subPassives: subPassives,
      statBonus: statBonus,
      powerBonus: powerBonus,
    );
  }

  MoveData _parseMove(
    Map<String, dynamic> jsonMap, {
    required String pairType,
    required String pairName,
    required Map<String, MoveScaling> scalingMap,
  }) {
    final name = (jsonMap['name'] ?? '') as String;
    final type = (jsonMap['type'] ?? '') as String;
    final category = (jsonMap['category'] ?? '') as String;
    final description = (jsonMap['description'] ?? '') as String;
    final scalingKey = '$pairName|$name';

    return MoveData(
      name: name,
      type: type,
      category: category,
      power: (jsonMap['power'] ?? '') as String,
      accuracy: (jsonMap['accuracy'] ?? '') as String,
      gauge: (jsonMap['gauge'] ?? '') as String,
      target: (jsonMap['target'] ?? '') as String,
      description: description,
      isSync: jsonMap['isSync'] == true,
      slot: jsonMap['slot'] as int?,
      scaling: scalingMap[scalingKey],
      isExtendedRange: jsonMap['isExtendedRange'] == true,
      tags: _dedupeTags([
        if (type.isNotEmpty) PairTag(category: 'move_type', value: type),
        if (category.isNotEmpty)
          PairTag(category: 'move_category', value: category),
        if (name.isNotEmpty) PairTag(category: 'move_name', value: name),
        if (type.isNotEmpty && type == pairType)
          PairTag(category: 'stab', value: 'true'),
        ..._effectTagsFromText(description),
      ]),
      effects: _effectsFromMoveDescription(description),
    );
  }

  MoveData? _parseOptionalMove(dynamic raw, {required String pairType, required String pairName, required Map<String, MoveScaling> scalingMap}) {
    if (raw is! Map<String, dynamic>) {
      return null;
    }
    return _parseMove(raw, pairType: pairType, pairName: pairName, scalingMap: scalingMap);
  }

  PassiveData _parsePassive(Map<String, dynamic> jsonMap) {
    final name = (jsonMap['name'] ?? '') as String;
    final description = (jsonMap['description'] ?? '') as String;
    final subPassivesRaw = jsonMap['subPassives'] as List? ?? const [];
    final subPassives = subPassivesRaw
        .map((e) => SubPassiveData(
              name: (e as Map<String, dynamic>)['name'] as String? ?? '',
              description: e['description'] as String? ?? '',
              value: (e['value'] as num?)?.toInt() ?? 0,
            ))
        .toList();
    return PassiveData(
      name: name,
      description: description,
      subPassives: subPassives,
      tags: _dedupeTags([
        PairTag(category: 'passive_name', value: name),
        ..._effectTagsFromText(name),
        ..._effectTagsFromText(description),
      ]),
      rule: _ruleFromPassiveText(name, description),
      locked: jsonMap['locked'] == true,
    );
  }

  List<VariationData> _parseVariations(List? rawList, {required String pairName, required Map<String, MoveScaling> scalingMap}) {
    return (rawList ?? const []).map((entry) {
      final variation = entry as Map<String, dynamic>;
      final moves = (variation['moves'] as List? ?? const [])
          .map(
            (move) => _parseMove(
              move as Map<String, dynamic>,
              pairType: (move['type'] ?? '') as String,
              pairName: pairName,
              scalingMap: scalingMap,
            ),
          )
          .toList();
      final passives = (variation['passives'] as List? ?? const [])
          .map((passive) => _parsePassive(passive as Map<String, dynamic>))
          .toList();
      return VariationData(
        formName: (variation['formName'] ?? 'Variation') as String,
        moves: moves,
        passives: passives,
      );
    }).toList();
  }

  Map<String, Map<String, int>> _parseNestedStats(Map<String, dynamic>? raw) {
    final result = <String, Map<String, int>>{};
    for (final entry in (raw ?? const <String, dynamic>{}).entries) {
      final valueMap = entry.value as Map<String, dynamic>;
      result[entry.key] = valueMap.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      );
    }
    return result;
  }

  Map<String, Map<String, Map<String, int>>> _parseFormStats(
    Map<String, dynamic>? raw,
  ) {
    final result = <String, Map<String, Map<String, int>>>{};
    for (final entry in (raw ?? const <String, dynamic>{}).entries) {
      result[entry.key] = _parseNestedStats(
        entry.value as Map<String, dynamic>?,
      );
    }
    return result;
  }

  Map<String, double> _parseDoubleMap(Map<String, dynamic>? raw) {
    return (raw ?? const <String, dynamic>{}).map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );
  }

  Map<String, double> _parseMegaStatMultiplier(Map<String, dynamic>? raw) {
    return (raw ?? const <String, dynamic>{}).map((key, value) {
      final parsed = (value as num).toDouble();
      return MapEntry(key, double.parse(parsed.toStringAsFixed(2)));
    });
  }

  Map<String, double> _parseTeraStatMultiplier(Map<String, dynamic> jsonMap) {
    return _parseDoubleMap(jsonMap['teraStatMultiplier'] as Map<String, dynamic>?);
  }

  List<PairTag> _extractThemeTags(Map<String, dynamic> jsonMap) {
    final output = <PairTag>[];
    final textFields = <String>[
      (jsonMap['displayName'] ?? '') as String,
      for (final move in jsonMap['moves'] as List? ?? const [])
        (move as Map<String, dynamic>)['description'] as String? ?? '',
      for (final passive in jsonMap['passives'] as List? ?? const [])
        (passive as Map<String, dynamic>)['description'] as String? ?? '',
    ];

    for (final text in textFields) {
      final lower = text.toLowerCase();
      if (lower.contains('kanto')) {
        output.add(const PairTag(category: 'theme_skill', value: 'Kanto'));
      }
      if (lower.contains('johto')) {
        output.add(const PairTag(category: 'theme_skill', value: 'Johto'));
      }
      if (lower.contains('paldea')) {
        output.add(const PairTag(category: 'theme_skill', value: 'Paldea'));
      }
      if (lower.contains('pasio')) {
        output.add(const PairTag(category: 'theme_skill', value: 'Pasio'));
      }
    }
    return output;
  }

  List<PairTag> _extractMoveEffectTags(List<MoveData> moves) {
    return [for (final move in moves) ...move.tags];
  }

  List<PairTag> _extractPassiveTags(List<PassiveData> passives) {
    return [for (final passive in passives) ...passive.tags];
  }

  List<PairTag> _effectTagsFromText(String text) {
    final lower = text.toLowerCase();
    final tags = <PairTag>[];

    void addIfFound(String needle, String category, String value) {
      if (lower.contains(needle)) {
        tags.add(PairTag(category: category, value: value));
      }
    }

    addIfFound('burn', 'effect', 'burn');
    addIfFound('sleep', 'effect', 'sleep');
    addIfFound('freeze', 'effect', 'freeze');
    addIfFound('paraly', 'effect', 'paralysis');
    addIfFound('poison', 'effect', 'poison');
    addIfFound('confus', 'effect', 'confusion');
    addIfFound('flinch', 'effect', 'flinch');
    addIfFound('trap', 'effect', 'trap');
    addIfFound('restrain', 'effect', 'restrain');
    addIfFound('lowers the target', 'effect', 'debuff');
    addIfFound('raises the user', 'effect', 'self_buff');
    addIfFound('raises the allied field', 'effect', 'field_buff');
    addIfFound('zone', 'field', 'zone');
    addIfFound('terrain', 'field', 'terrain');
    addIfFound('weather', 'field', 'weather');
    addIfFound('circle', 'field', 'circle');

    return tags;
  }

  List<PairTag> _tileTags(String title, String colorKind) {
    final tags = <PairTag>[PairTag(category: 'grid_kind', value: colorKind)];
    final lower = title.toLowerCase();
    if (lower.contains('power')) {
      tags.add(const PairTag(category: 'tile_effect', value: 'power'));
    }
    if (lower.contains('accuracy')) {
      tags.add(const PairTag(category: 'tile_effect', value: 'accuracy'));
    }
    if (lower.contains('refresh')) {
      tags.add(const PairTag(category: 'tile_effect', value: 'refresh'));
    }
    if (lower.contains('move gauge')) {
      tags.add(const PairTag(category: 'tile_effect', value: 'gauge'));
    }
    return tags;
  }

  List<PassiveEffect> _effectsFromMoveDescription(String description) {
    final lower = description.toLowerCase();
    final effects = <PassiveEffect>[];
    if (lower.contains('lowers the target')) {
      effects.add(
        const PassiveEffect(
          kind: EffectKind.statModifier,
          scope: EntityScope.enemy,
          flag: 'debuff',
        ),
      );
    }
    if (lower.contains('raises the user')) {
      effects.add(
        const PassiveEffect(
          kind: EffectKind.statModifier,
          scope: EntityScope.self,
          flag: 'self_buff',
        ),
      );
    }
    if (lower.contains('weather') ||
        lower.contains('terrain') ||
        lower.contains('zone')) {
      effects.add(
        const PassiveEffect(
          kind: EffectKind.fieldEffect,
          scope: EntityScope.field,
        ),
      );
    }
    return effects;
  }

  PassiveRule _ruleFromPassiveText(String name, String description) {
    final text = '$name $description'.toLowerCase();
    final conditions = <PassiveCondition>[];
    final effects = <PassiveEffect>[];

    if (text.contains('when it enters a battle')) {
      conditions.add(
        const PassiveCondition(
          kind: ConditionKind.always,
          subject: 'battle_entry',
        ),
      );
    }
    if (text.contains('while') && text.contains('weather')) {
      conditions.add(
        const PassiveCondition(
          kind: ConditionKind.fieldActive,
          value: 'weather',
        ),
      );
    }
    if (text.contains('while') && text.contains('terrain')) {
      conditions.add(
        const PassiveCondition(
          kind: ConditionKind.fieldActive,
          value: 'terrain',
        ),
      );
    }
    if (text.contains('while') && text.contains('zone')) {
      conditions.add(
        const PassiveCondition(kind: ConditionKind.fieldActive, value: 'zone'),
      );
    }
    if (text.contains('burned')) {
      conditions.add(
        const PassiveCondition(
          kind: ConditionKind.userHasStatus,
          value: 'burned',
        ),
      );
    }

    if (text.contains('raises')) {
      effects.add(
        const PassiveEffect(
          kind: EffectKind.statModifier,
          scope: EntityScope.self,
        ),
      );
    }
    if (text.contains('powers up')) {
      effects.add(
        const PassiveEffect(
          kind: EffectKind.powerModifier,
          scope: EntityScope.self,
        ),
      );
    }
    if (text.contains('team') || text.contains('allied')) {
      effects.add(
        const PassiveEffect(
          kind: EffectKind.passiveToggle,
          scope: EntityScope.team,
        ),
      );
    }

    return PassiveRule(conditions: conditions, effects: effects);
  }

  List<PairTag> _dedupeTags(List<PairTag> tags) {
    final byKey = <String, PairTag>{};
    for (final tag in tags) {
      byKey[tag.key] = tag;
    }
    return byKey.values.toList();
  }

  List<DamagePassive> _resolveDamagePassives(List refs, Map<String, DamagePassive> masterMap) {
    final result = <DamagePassive>[];
    for (final ref in refs) {
      final r = ref as Map<String, dynamic>;
      final name = (r['name'] ?? '') as String;
      final moveName = (r['moveName'] ?? '') as String;
      final key = moveName.isEmpty ? name : '$name|$moveName';
      final master = masterMap[key];
      if (master == null) continue;
      result.add(DamagePassive(
        source: (r['source'] ?? '') as String,
        name: master.name,
        type: master.type,
        appliesTo: master.appliesTo,
        affects: master.affects,
        mechanism: master.mechanism,
        value: master.value,
        stat: master.stat,
        statTarget: master.statTarget,
        conditions: master.conditions,
        moveName: master.moveName,
        cellNumber: (r['cellNumber'] as num?)?.toInt(),
        subPassives: master.subPassives,
      ));
    }
    return result;
  }

  DamagePassive _parseDamagePassive(Map<String, dynamic> p) {
    final conditions = <List<String>>[];
    for (final c in (p['conditions'] as List? ?? const [])) {
      conditions.add((c as List).map((e) => e.toString()).toList());
    }
    final subPassives = <DamagePassive>[];
    for (final sp in (p['sub_passives'] as List? ?? const [])) {
      subPassives.add(_parseDamageSubPassive(sp as Map<String, dynamic>));
    }
    return DamagePassive(
      source: (p['source'] ?? '') as String,
      name: (p['name'] ?? '') as String,
      type: (p['type'] ?? '') as String,
      appliesTo: (p['applies_to'] ?? '') as String,
      affects: (p['affects'] ?? '') as String,
      mechanism: (p['mechanism'] ?? '') as String,
      value: (p['value'] as num?)?.toInt() ?? (p['sub_value'] as num?)?.toInt() ?? 0,
      stat: (p['stat'] ?? '') as String,
      statTarget: (p['stat_target'] ?? '') as String,
      conditions: conditions,
      moveName: (p['move_name'] ?? '') as String,
      cellNumber: (p['cellNumber'] as num?)?.toInt(),
      subPassives: subPassives,
    );
  }

  DamagePassive _parseDamageSubPassive(Map<String, dynamic> sp) {
    final conditions = <List<String>>[];
    for (final c in (sp['conditions'] as List? ?? const [])) {
      conditions.add((c as List).map((e) => e.toString()).toList());
    }
    return DamagePassive(
      source: 'sub_passive',
      name: (sp['sub_name'] ?? sp['name'] ?? '') as String,
      type: (sp['type'] ?? '') as String,
      appliesTo: (sp['applies_to'] ?? '') as String,
      affects: (sp['affects'] ?? '') as String,
      mechanism: (sp['mechanism'] ?? '') as String,
      value: (sp['sub_value'] as num?)?.toInt() ?? (sp['value'] as num?)?.toInt() ?? 0,
      stat: (sp['stat'] ?? '') as String,
      statTarget: (sp['stat_target'] ?? '') as String,
      conditions: conditions,
      moveName: (sp['move_name'] ?? '') as String,
    );
  }
}
