import 'dart:convert';
import 'dart:io';

// Stat level indices in pomatools arrays -> level keys in output JSON
const _statLevels = {0: '1', 3: '140', 4: '150', 6: '200'};

late final Map _en;
late final Map _moveData;
late final Map _skillData;
late final Map _chars;
late final Map _pkmn;
late final Map _moveNames;
late final Map _skillNames;
late final Map _types;
late final Map _roles;
late final Map _categories;
late final Map _targets;
late final Map _statLabels;

void main() {
  // Load pomatools data
  _en = _loadJson('docs/pomatools/assets/i18n/en.json');
  _moveData = _loadJson('docs/pomatools/assets/data/moves.json');
  _skillData = _loadJson('docs/pomatools/assets/data/skills.json');
  final pairsData = _loadJson('docs/pomatools/assets/data/pairs.json') as List;
  final gridsData = _loadJson('docs/pomatools/assets/data/pairgrids.json');

  _chars = _en['DATA']['CHAR'];
  _pkmn = _en['DATA']['PKMN'];
  _moveNames = _en['DATA']['MOVES'];
  _skillNames = _en['DATA']['SKILLS'];
  _types = _en['MSGS']['TYPES'];
  _roles = _en['MSGS']['ROLES'];
  _categories = _en['MSGS']['CATEGORIES'];
  _targets = _en['MSGS']['TARGETS'];
  _statLabels = _en['MSGS']['LABEL_STAT'];

  // Group pairs by unique id (trainerId+pokemonId combo)
  final pomatoolsPairs = <Map<String, dynamic>>[];

  for (final p in pairsData) {
    final pair = p as Map<String, dynamic>;
    final gridId = pair['gridId'] as String;
    final gridVersions = gridsData[gridId] as List?;

    final result = _buildSyncPair(pair, gridVersions);
    if (result != null) pomatoolsPairs.add(result);
  }

  // Deduplicate pomatools pairs by displayName (keep first occurrence)
  final seenNames = <String>{};
  final dedupedPairs = <Map<String, dynamic>>[];
  for (final p in pomatoolsPairs) {
    if (seenNames.add(p['displayName'] as String)) dedupedPairs.add(p);
  }
  final pomatoolsPairsDeduped = dedupedPairs;

  // Load existing JSON (from txt files) to merge pairs not in pomatools
  final existingJson = jsonDecode(
    File('assets/data/sync_pairs.json').readAsStringSync(),
  ) as List;

  final pomatoolsNumbers = <int>{};
  for (final p in pomatoolsPairsDeduped) {
    pomatoolsNumbers.add(p['number'] as int);
  }

  // Add txt-only pairs that pomatools doesn't have
  final txtOnlyPairs = <Map<String, dynamic>>[];
  for (final existing in existingJson) {
    final num = existing['number'] as int;
    final name = existing['displayName'] as String;
    if (!pomatoolsNumbers.contains(num) ||
        !pomatoolsPairsDeduped.any((p) => p['number'] == num && p['displayName'] == name)) {
      txtOnlyPairs.add(Map<String, dynamic>.from(existing as Map));
    }
  }

  final allPairs = [...pomatoolsPairsDeduped, ...txtOnlyPairs];
  allPairs.sort((a, b) {
    final cmp = (a['number'] as int).compareTo(b['number'] as int);
    if (cmp != 0) return cmp;
    return (a['displayName'] as String).compareTo(b['displayName'] as String);
  });

  final json = jsonEncode(allPairs);
  File('assets/data/sync_pairs.json').writeAsStringSync(json);
  print('Generated sync_pairs.json: ${allPairs.length} pairs '
      '(${pomatoolsPairsDeduped.length} from pomatools, ${txtOnlyPairs.length} from txt)');
}

Map<String, dynamic>? _buildSyncPair(Map<String, dynamic> pair, List? gridVersions) {
  final pokemon = pair['pokemon'] as List;
  final baseForms = pokemon.where((pk) => pk['kind'] == 'BASE').toList();
  if (baseForms.isEmpty) return null;

  final base = baseForms.first as Map;
  final trainerId = pair['trainerId'] as String;
  final trainerName = _chars[trainerId] ?? 'Unknown';
  final pkId = base['id'] as String;
  final rawPkName = (_pkmn[pkId] ?? 'Unknown') as String;
  // Strip gender markers — male/female forms of the same Pokémon are the same sync pair
  final pkName = rawPkName.replaceAll(RegExp(r'\s*\((?:Male|Female)[♂♀️♂♀]*\)'), '').trim();
  final number = (pair['entry'] as int) ~/ 100;
  final displayName = '$trainerName & $pkName';

  final role = _roles[pair['role']] ?? '';
  final exRole = _roles[pair['exRole']] ?? '';
  final weakness = _types[base['weak']] ?? '';
  final promotion = pair['promotion'] as int;
  final hasEx = pair['exMode'] != null && pair['exMode'] != 0;

  // Awakening skill = super awakening
  final awakeningId = pair['awakeningSkill'];
  final hasSuperAwakening = awakeningId != null && awakeningId != 0;

  // Release date
  final dateTs = pair['date'] as int?;
  String? releaseDate;
  if (dateTs != null && dateTs > 0) {
    final dt = DateTime.fromMillisecondsSinceEpoch(dateTs * 1000, isUtc: true);
    releaseDate = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  // Build moves from BASE form
  final moves = <Map<String, dynamic>>[];
  String syncMoveName = '';
  final baseMoves = base['moves'] as List;
  for (final moveId in baseMoves) {
    if (moveId == -1) continue;
    final mid = moveId.toString();
    final mData = _moveData[mid] as Map?;
    final mNameData = _moveNames[mid] as Map?;
    final name = mNameData?['NAME'] ?? 'Move $mid';
    final desc = mNameData?['DESC'] ?? '';
    final isSync = mData?['kind'] == 'SN';

    if (isSync) syncMoveName = name;

    final type = _types[mData?['type']] ?? '';
    final category = _categories[mData?['category']] ?? '';
    final power = mData?['power'];
    final accuracy = mData?['accuracy'];
    final gauge = mData?['gauge'];
    final target = _targets[mData?['target']] ?? '';

    final move = <String, dynamic>{
      'name': name,
      'type': type == 'Trainer' || type == 'Items' ? '' : type,
      'category': category,
      'power': _formatPower(power, mData?['powerup']),
      'accuracy': accuracy == -1 ? '--' : (accuracy?.toString() ?? '--'),
      'gauge': gauge == 0 ? '--' : (gauge?.toString() ?? '--'),
      'target': target,
      'description': desc,
      'isSync': isSync,
    };
    moves.add(move);
  }

  // Build passives from BASE form skills
  final passives = <Map<String, dynamic>>[];

  // Add awakening skill first if present
  if (hasSuperAwakening && awakeningId != 0) {
    final sData = _skillNames[awakeningId.toString()] as Map?;
    passives.add({
      'name': _resolveSkillTemplate(sData?['NAME'] ?? 'Awakening $awakeningId', 0),
      'description': _resolveSkillTemplate(sData?['DESC'] ?? '', 0),
      'locked': true,
      'subPassives': _buildSubPassives(awakeningId),
    });
  }

  for (final skill in base['skills'] as List) {
    final sid = (skill as List)[0] as int;
    final lock = skill[1] as int;
    if (sid == 0) continue;
    final sData = _skillNames[sid.toString()] as Map?;
    passives.add({
      'name': _resolveSkillTemplate(sData?['NAME'] ?? 'Skill $sid', lock),
      'description': _resolveSkillTemplate(sData?['DESC'] ?? '', lock),
      'locked': lock > 0,
      'subPassives': _buildSubPassives(sid),
    });
  }

  // Build stats
  final stats = <String, Map<String, int>>{};
  final baseStats = base['stats'] as List;
  for (final entry in _statLevels.entries) {
    if (entry.key < baseStats.length) {
      final s = baseStats[entry.key] as List;
      stats[entry.value] = {
        'hp': s[0] as int,
        'atk': s[1] as int,
        'def': s[2] as int,
        'spa': s[3] as int,
        'spd': s[4] as int,
        'spe': s[5] as int,
      };
    }
  }

  // Mega stats & multiplier
  final megaStats = <String, Map<String, int>>{};
  final megaStatMultiplier = <String, double>{};
  final megaForms = pokemon.where((pk) => pk['kind'] == 'MEGA').toList();
  if (megaForms.isNotEmpty) {
    final mega = megaForms.first as Map;
    final megaStatArr = mega['stats'] as List;
    // MEGA form has percentage stats in index 0
    if (megaStatArr.isNotEmpty) {
      final pcts = megaStatArr[0] as List;
      for (final entry in {'atk': 1, 'def': 2, 'spa': 3, 'spd': 4, 'spe': 5}.entries) {
        final pct = pcts[entry.value] as int;
        if (pct != 100) {
          megaStatMultiplier[entry.key] = double.parse((pct / 100.0).toStringAsFixed(2));
        }
      }
    }
    // Build mega stats at each level from base * multiplier
    if (megaStatMultiplier.isNotEmpty) {
      for (final lvEntry in stats.entries) {
        final base = lvEntry.value;
        megaStats[lvEntry.key] = {
          'hp': base['hp']!,
          'atk': (base['atk']! * (megaStatMultiplier['atk'] ?? 1.0)).round(),
          'def': (base['def']! * (megaStatMultiplier['def'] ?? 1.0)).round(),
          'spa': (base['spa']! * (megaStatMultiplier['spa'] ?? 1.0)).round(),
          'spd': (base['spd']! * (megaStatMultiplier['spd'] ?? 1.0)).round(),
          'spe': (base['spe']! * (megaStatMultiplier['spe'] ?? 1.0)).round(),
        };
      }
    }
  }

  // Tera data
  final teraForms = pokemon.where((pk) => (pk['kind'] as String).startsWith('TERA')).toList();
  final hasTera = teraForms.isNotEmpty;
  Map<String, dynamic>? teraMove;
  final teraPassives = <Map<String, dynamic>>[];
  final teraStatMultiplier = <String, double>{};

  if (hasTera) {
    final tera = teraForms.first as Map;
    // Tera moves
    for (final moveId in tera['moves'] as List) {
      if (moveId == -1) continue;
      final mid = moveId.toString();
      final mData = _moveData[mid] as Map?;
      final mNameData = _moveNames[mid] as Map?;
      if (mData == null) continue;
      // The tera-specific move (not shared with base)
      if (!baseMoves.contains(moveId)) {
        final name = mNameData?['NAME'] ?? 'Move $mid';
        final desc = mNameData?['DESC'] ?? '';
        final type = _types[mData['type']] ?? '';
        final category = _categories[mData['category']] ?? '';
        final power = mData['power'];
        final accuracy = mData['accuracy'];
        final gauge = mData['gauge'];
        final target = _targets[mData['target']] ?? '';
        teraMove ??= {
          'name': name,
          'type': type == 'Trainer' || type == 'Items' ? '' : type,
          'category': category,
          'power': _formatPower(power, mData['powerup']),
          'accuracy': accuracy == -1 ? '--' : (accuracy?.toString() ?? '--'),
          'gauge': gauge == 0 ? '--' : (gauge?.toString() ?? '--'),
          'target': target,
          'description': desc,
        };
      }
    }
    // Tera passives (skills not in base)
    final baseSkillIds = (base['skills'] as List).map((s) => (s as List)[0]).toSet();
    for (final skill in tera['skills'] as List) {
      final sid = (skill as List)[0] as int;
      if (sid == 0 || baseSkillIds.contains(sid)) continue;
      final sData = _skillNames[sid.toString()] as Map?;
      teraPassives.add({
        'name': _resolveSkillTemplate(sData?['NAME'] ?? 'Skill $sid', skill[1] as int),
        'description': _resolveSkillTemplate(sData?['DESC'] ?? '', skill[1] as int),
        'subPassives': _buildSubPassives(sid),
      });
    }
    // Tera stat multiplier from tera stats
    final teraStats = tera['stats'] as List;
    if (teraStats.isNotEmpty) {
      final pcts = teraStats[0] as List;
      for (final entry in {'atk': 1, 'def': 2, 'spa': 3, 'spd': 4, 'spe': 5}.entries) {
        final pct = pcts[entry.value] as int;
        if (pct != 100) {
          teraStatMultiplier[entry.key] = double.parse((pct / 100.0).toStringAsFixed(2));
        }
      }
    }
  }

  // Variations (non-BASE, non-MEGA, non-TERA, non-DMAX forms)
  final variations = <Map<String, dynamic>>[];
  final variationKinds = pokemon.where((pk) {
    final kind = pk['kind'] as String;
    return kind != 'BASE' && kind != 'MEGA' && !kind.startsWith('TERA') && kind != 'DMAX';
  }).toList();

  for (final vForm in variationKinds) {
    final vMoves = <Map<String, dynamic>>[];
    final vPassives = <Map<String, dynamic>>[];
    final formPkName = _pkmn[(vForm as Map)['id']] ?? vForm['kind'];
    int slot = 0;
    for (final moveId in vForm['moves'] as List) {
      slot++;
      if (moveId == -1) continue;
      // Only include moves that differ from base
      if (slot <= baseMoves.length && baseMoves[slot - 1] == moveId) continue;
      final mid = moveId.toString();
      final mData = _moveData[mid] as Map?;
      final mNameData = _moveNames[mid] as Map?;
      final name = mNameData?['NAME'] ?? 'Move $mid';
      final desc = mNameData?['DESC'] ?? '';
      final isSync = mData?['kind'] == 'SN';
      final type = _types[mData?['type']] ?? '';
      final category = _categories[mData?['category']] ?? '';
      vMoves.add({
        'name': name,
        'type': type == 'Trainer' || type == 'Items' ? '' : type,
        'category': category,
        'power': _formatPower(mData?['power'], mData?['powerup']),
        'accuracy': mData?['accuracy'] == -1 ? '--' : (mData?['accuracy']?.toString() ?? '--'),
        'gauge': mData?['gauge'] == 0 ? '--' : (mData?['gauge']?.toString() ?? '--'),
        'target': _targets[mData?['target']] ?? '',
        'description': desc,
        'isSync': isSync,
        'slot': slot,
      });
    }
    // Variation passives different from base
    final baseSkillIds = (base['skills'] as List).map((s) => (s as List)[0]).toSet();
    for (final skill in vForm['skills'] as List) {
      final sid = (skill as List)[0] as int;
      if (sid == 0 || baseSkillIds.contains(sid)) continue;
      final sData = _skillNames[sid.toString()] as Map?;
      vPassives.add({
        'name': _resolveSkillTemplate(sData?['NAME'] ?? 'Skill $sid', skill[1] as int),
        'description': _resolveSkillTemplate(sData?['DESC'] ?? '', skill[1] as int),
      });
    }
    if (vMoves.isNotEmpty || vPassives.isNotEmpty) {
      variations.add({
        'formName': formPkName,
        'moves': vMoves,
        'passives': vPassives,
      });
    }
  }

  // Build grid cells
  final cells = _buildGridCells(gridVersions);

  // Determine type from first non-status, non-sync BASE move
  String type = '';
  for (final moveId in baseMoves) {
    if (moveId == -1) continue;
    final mData = _moveData[moveId.toString()] as Map?;
    if (mData == null) continue;
    final kind = mData['kind'] as String;
    final cat = mData['category'] as String;
    if (kind == 'MV' && cat != 'CATE_004') {
      type = _types[mData['type']] ?? '';
      break;
    }
  }
  // Fallback: use sync move type
  if (type.isEmpty) {
    for (final moveId in baseMoves) {
      if (moveId == -1) continue;
      final mData = _moveData[moveId.toString()] as Map?;
      if (mData?['kind'] == 'SN') {
        type = _types[mData!['type']] ?? '';
        break;
      }
    }
  }

  return {
    'number': number,
    'displayName': displayName,
    'role': role,
    'exRole': exRole,
    'type': type,
    'weakness': weakness,
    'rarity': promotion,
    'hasEx': hasEx,
    'hasSuperAwakening': hasSuperAwakening,
    'syncMoveName': syncMoveName,
    'releaseDate': releaseDate,
    'moves': moves,
    'passives': passives,
    'hasTera': hasTera,
    'teraMove': teraMove,
    'teraPassives': teraPassives,
    'stats': stats,
    'teraStatMultiplier': teraStatMultiplier,
    'megaStatMultiplier': megaStatMultiplier,
    'megaStats': megaStats,
    'variations': variations,
    'cells': cells,
  };
}

List<Map<String, dynamic>> _buildGridCells(List? gridVersions) {
  if (gridVersions == null || gridVersions.isEmpty) return [];

  // Merge all versions: later versions override/add cells by position
  final cellsByPos = <String, Map>{};
  for (final ver in gridVersions) {
    for (final cell in (ver as Map)['cells'] as List) {
      cellsByPos[cell['position'] as String] = cell as Map;
    }
  }

  final cells = <Map<String, dynamic>>[];
  int cellNum = 0;
  for (final entry in cellsByPos.entries) {
    cellNum++;
    final cell = entry.value;
    final pos = entry.key;
    final qrs = _posToQRS(pos);
    final kind = cell['kind'] as String;
    final target = cell['target'] as String;
    final value = cell['value'] as int;
    final skillId = cell['skill'] as int;
    final level = cell['level'] as int;
    final orbs = cell['orbs'] as int;

    // Calculate energy cost from orbs (orbs / 12, but inner ring = 0)
    final energy = orbs <= 5 ? 0 : (orbs / 12).round();

    final titleDesc = _buildCellTitle(kind, target, value, skillId);
    final colorKind = _buildColorKind(kind, target, skillId);

    final statBonus = <String, int>{};
    final powerBonus = <String, int>{};
    if (kind == 'STAT') {
      final key = _statKeyFromTarget(target);
      if (key != null) statBonus[key] = value;
    } else if (kind == 'POWERUP') {
      final moveName = (_moveNames[target] as Map?)?['NAME'] as String? ?? target;
      powerBonus[moveName] = value;
    }

    final cellEntry = <String, dynamic>{
      'cellNumber': cellNum,
      'q': qrs[0],
      'r': qrs[1],
      's': qrs[2],
      'energyCost': energy,
      'orbCost': orbs,
      'title': titleDesc[0],
      'description': titleDesc[0] == titleDesc[1] ? '' : titleDesc[1],
      'colorKind': colorKind,
      'moveLevel': level,
      'statBonus': statBonus,
      'powerBonus': powerBonus,
    };
    if (skillId != 0) {
      final subs = _buildSubPassives(skillId);
      if (subs.isNotEmpty) cellEntry['subPassives'] = subs;
    }
    cells.add(cellEntry);
  }
  return cells;
}

List<int> _posToQRS(String pos) {
  final col = pos.codeUnitAt(0) - 'E'.codeUnitAt(0);
  final row = pos.codeUnitAt(1) - 'G'.codeUnitAt(0);
  final q = col;
  final parity = ((col % 2) + 2) % 2;
  final r = row - ((col - parity) ~/ 2);
  final s = -q - r;
  return [q, r, s];
}

List<String> _buildCellTitle(String kind, String target, int value, int skillId) {
  switch (kind) {
    case 'STAT':
      final statName = _statLabels[target] ?? target;
      return ['$statName $value', '$statName $value'];
    case 'POWERUP':
      final moveName = (_moveNames[target] as Map?)?['NAME'] ?? target;
      return ['$moveName: Power $value', '$moveName: Power ↑ $value'];
    case 'SKILL':
      final skillName = _resolveSkillTemplate(
        (_skillNames[skillId.toString()] as Map?)?['NAME'] ?? 'Skill $skillId', value);
      final skillDesc = _resolveSkillTemplate(
        (_skillNames[skillId.toString()] as Map?)?['DESC'] ?? '', value);
      if (target == 'PKMN' || target == 'SYNC') {
        return [skillName, skillDesc];
      }
      final moveName = (_moveNames[target] as Map?)?['NAME'] ?? target;
      return ['$moveName: $skillName', skillDesc];
    case 'MODIFIER':
      final skillName = _resolveSkillTemplate(
        (_skillNames[skillId.toString()] as Map?)?['NAME'] ?? 'Modifier', value);
      final skillDesc = _resolveSkillTemplate(
        (_skillNames[skillId.toString()] as Map?)?['DESC'] ?? '', value);
      return [skillName, skillDesc];
    case 'LEARN':
      final moveName = (_moveNames[target] as Map?)?['NAME'] ?? target;
      return ['Learn: $moveName', 'Unlocks $moveName'];
    default:
      return [kind, ''];
  }
}

String _buildColorKind(String kind, String target, int skillId) {
  switch (kind) {
    case 'STAT':
      return 'Blue (Stat)';
    case 'POWERUP':
      // Check if it's a sync move powerup
      final mData = _moveData[target] as Map?;
      if (mData?['kind'] == 'SN') return 'Rainbow (Sync Move)';
      return 'Green (Move Boost)';
    case 'SKILL':
      if (target == 'PKMN' || target == 'SYNC') return 'Yellow (Passive)';
      return 'Red (Move Effect)';
    case 'MODIFIER':
      return 'Yellow (Passive)';
    case 'LEARN':
      return 'Purple (Learn)';
    default:
      return 'Unknown';
  }
}

String _formatPower(dynamic power, dynamic powerup) {
  if (power == null || power == 0) return '--';
  final base = power as int;
  // powerup is a list of [level, power] pairs OR a stat-scaling formula with string tokens
  if (powerup != null && powerup is List && powerup.isNotEmpty) {
    final maxPower = powerup.last;
    // Stat-scaling formula: inner list contains non-integer tokens (e.g. ['TARG_004', 'STAT_510', ...])
    // These moves scale with stat stages — just return base power; scaling is in move_scaling.json
    if (maxPower is List && maxPower.any((e) => e is! int)) {
      return base.toString();
    }
    if (maxPower is List && maxPower.length >= 2) {
      return '$base (1)/${maxPower[1]} (5↑ MAX)';
    }
    if (maxPower is int && maxPower != base) {
      return '$base (1)/$maxPower (5↑ MAX)';
    }
  }
  return base.toString();
}

String _resolveSkillTemplate(String text, int value) {
  if (!text.contains('{{')) return text;
  return text
      .replaceAll('{{value}}', value.toString())
      .replaceAll('{{chance}}', _chanceFromValue(value))
      .replaceAll('{{heal}}', _healFromValue(value))
      .replaceAll('{{sheal}}', _healFromValue(value))
      .replaceAll(RegExp(r'\{\{\w+\}\}'), value.toString());
}

String _chanceFromValue(int value) {
  // Common chance mappings in Pokemon Masters
  const map = {1: '10', 2: '30', 3: '40', 4: '50', 5: '60', 9: '100'};
  return map[value] ?? '${value * 10}';
}

String _healFromValue(int value) {
  const map = {1: '20', 2: '30', 3: '40', 4: '40', 5: '50', 9: '60'};
  return map[value] ?? '${value * 10}';
}

List<Map<String, dynamic>> _buildSubPassives(int skillId) {
  final skill = _skillData[skillId.toString()] as Map?;
  if (skill == null || skill['type'] != 'MULTI') return const [];
  final spec = skill['spec'] as String? ?? '';
  if (spec.isEmpty) return const [];
  final result = <Map<String, dynamic>>[];
  for (final part in spec.split(',')) {
    final trimmed = part.trim();
    if (trimmed.length < 8) continue;
    final subId = trimmed.substring(0, 7);
    final subVal = int.tryParse(trimmed.substring(7)) ?? 0;
    final sData = _skillNames[subId] as Map?;
    result.add({
      'name': _resolveSkillTemplate(sData?['NAME'] ?? 'Sub $subId', subVal),
      'description': _resolveSkillTemplate(sData?['DESC'] ?? '', subVal),
      'value': subVal,
    });
  }
  return result;
}

String? _statKeyFromTarget(String target) {
  const map = {
    'STAT_001': 'hp',
    'STAT_002': 'atk',
    'STAT_004': 'def',
    'STAT_008': 'spa',
    'STAT_016': 'spd',
    'STAT_032': 'spe',
  };
  return map[target];
}

dynamic _loadJson(String path) {
  return jsonDecode(File(path).readAsStringSync());
}
