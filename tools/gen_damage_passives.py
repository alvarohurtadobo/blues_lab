"""
Extract all damage-boosting passives from pomatools data.
Scans: passives, sub-passives (MULTI composites), super awakening,
master passives, and grid passives.
Outputs: assets/data/damage_passives.json
"""
import json, os, re

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
POMA = os.path.join(BASE, 'docs', 'pomatools', 'assets')

def load(path):
    with open(os.path.join(POMA, path), encoding='utf-8') as f:
        return json.load(f)

en = load('i18n/en.json')
skills_data = load('data/skills.json')
pairs_data = load('data/pairs.json')
grids_data = load('data/pairgrids.json')

CHARS = en['DATA']['CHAR']
PKMN = en['DATA']['PKMN']
SKILL_NAMES = en['DATA']['SKILLS']
TYPES = en['MSGS']['TYPES']

STAT_MAP = {
    'STAT_001': 'hp', 'STAT_002': 'atk', 'STAT_004': 'def',
    'STAT_008': 'spa', 'STAT_016': 'spd', 'STAT_032': 'spe',
    'STAT_064': 'accuracy', 'STAT_128': 'evasiveness',
    'STAT_510': 'all_stats', 'STAT_024': 'def+spd',
}

CONDITION_MAP = {
    'WTHR_001': 'sunny', 'WTHR_002': 'rain', 'WTHR_004': 'sandstorm',
    'WTHR_008': 'hail', 'WTHR_015': 'any_weather', 'WTHR_000': 'no_weather',
    'TERR_001': 'electric_terrain', 'TERR_002': 'grassy_terrain',
    'TERR_004': 'misty_terrain', 'TERR_008': 'psychic_terrain',
    'TERR_015': 'any_terrain',
    'ZONE_1': 'normal_zone', 'ZONE_6': 'fighting_zone',
    'ZONE_7': 'flying_zone', 'ZONE_8': 'poison_zone',
    'ZONE_9': 'ground_zone', 'ZONE_10': 'rock_zone',
    'ZONE_12': 'ghost_zone', 'ZONE_13': 'steel_zone',
    'ZONE_14': 'fire_zone', 'ZONE_15': 'water_zone',
    'ZONE_16': 'grass_zone', 'ZONE_17': 'electric_zone',
    'ZONE_18': 'ice_zone',
    'SCPM_003': 'burned', 'SCPM_004': 'frozen', 'SCPM_008': 'paralyzed',
    'SCPM_016': 'poisoned', 'SCPM_032': 'asleep', 'SCPM_063': 'any_status',
    'SCTP_001': 'flinching', 'SCTP_002': 'confused', 'SCTP_004': 'trapped',
    'SCTP_007': 'flinch_confuse_trap', 'SCTP_008': 'any_condition',
    'HP_PINCH': 'hp_low', 'HP_FULL': 'hp_full', 'HP_REDU': 'hp_reduced',
    'HP_HALFULL': 'hp_half_or_more',
    'WTZ': 'any_weather_terrain_zone',
}

SPEC_MAP = {
    'SIMPLE': 'flat_boost', 'GAUGE': 'gauge_cost_boost',
    'RAISE_STAT': 'user_stat_raised', 'LOWER_STAT': 'target_stat_lowered',
    'RAISED': 'stat_is_raised', 'LOWERED': 'stat_is_lowered',
    'UNRSD_STAT': 'stat_not_raised', 'FIFTY': 'fifty_percent',
    'RAISED_30': 'stat_raised_30pct', 'SYNC': 'sync_count_boost',
}

APPLIES_MAP = {
    'MOVE': 'moves', 'SYNC': 'sync_move', 'BOTH': 'moves_and_sync',
    'ALL': 'all', 'PKMN': 'pokemon_moves', 'MAXM': 'max_move',
    'SNMX': 'sync_and_max',
}

AFFECTS_MAP = {
    'TARG_001': 'self', 'TARG_034': 'team', 'TARG_004': 'target',
}

def resolve_template(text, value=0):
    if not text or '{{' not in text:
        return text or ''
    chance_map = {1: '10', 2: '30', 3: '40', 4: '50', 5: '60', 9: '100'}
    text = text.replace('{{value}}', str(value))
    text = text.replace('{{chance}}', chance_map.get(value, str(value * 10)))
    text = re.sub(r'\{\{\w+\}\}', str(value), text)
    return text

def get_skill_name(sid, value=0):
    sdata = SKILL_NAMES.get(str(sid), {})
    name = resolve_template(sdata.get('NAME', f'Skill {sid}'), value)
    desc = resolve_template(sdata.get('DESC', ''), value)
    return name, desc

def parse_skill_damage_info(sid):
    """Parse a skill ID and return damage info if it's a POWERUP or REDUCER."""
    s = skills_data.get(str(sid))
    if not s:
        return None

    # Handle MULTI (composite) skills
    if s.get('type') == 'MULTI':
        spec = s.get('spec', '')
        sub_ids = [sp[:7] for sp in spec.split(',') if sp.strip()]
        subs = []
        for sub_raw in spec.split(','):
            sub_raw = sub_raw.strip()
            if not sub_raw:
                continue
            sub_sid = sub_raw[:7]
            sub_val = int(sub_raw[7:9]) if len(sub_raw) >= 9 else 0
            sub_info = parse_skill_damage_info(int(sub_sid))
            if sub_info:
                sub_info['sub_value'] = sub_val
                sn, sd = get_skill_name(int(sub_sid), sub_val)
                sub_info['sub_name'] = sn
                sub_info['sub_description'] = sd
                subs.append(sub_info)
        if subs:
            return {'type': 'composite', 'sub_passives': subs}
        return None

    if s.get('trigger') != 'CALCULATION':
        return None
    if s.get('type') not in ('POWERUP', 'REDUCER', 'MODIFIER'):
        return None

    info = {
        'type': s['type'].lower(),
        'applies_to': APPLIES_MAP.get(s.get('applies', ''), s.get('applies', '')),
        'affects': AFFECTS_MAP.get(s.get('effect', ''), s.get('effect', '')),
    }

    # Parse conditions
    conditions = []
    for cond_group in s.get('conditions', []):
        parsed = []
        for c in cond_group:
            if c.startswith('TARG_'):
                continue  # target specifier, handled elsewhere
            mapped = CONDITION_MAP.get(c)
            if mapped:
                parsed.append(mapped)
            elif c.startswith('TYPE_'):
                parsed.append(f'type_{TYPES.get(c, c)}')
            elif c.startswith('MOVE_'):
                parsed.append(f'move_slot_{c}')
            elif c.startswith('TAGS_'):
                parsed.append(c.lower())
            elif c.startswith('PKMN_'):
                parsed.append(f'pokemon_{c}')
            elif c.startswith('BRRY_'):
                parsed.append('berry_active')
            elif c.startswith('DMFD_'):
                parsed.append(f'damage_field_{c}')
            elif c.startswith('THMP_') or c.startswith('THMD_') or c.startswith('THMS_') or c == 'THM':
                parsed.append(f'theme_{c}')
            elif c.startswith('REBUFF_'):
                parsed.append('has_rebuff')
            elif c.startswith('FILD_'):
                parsed.append(f'field_{c}')
            else:
                parsed.append(c)
        if parsed:
            conditions.append(parsed)
    if conditions:
        info['conditions'] = conditions

    # Parse spec (damage mechanism)
    spec = s.get('spec', '')
    if spec in SPEC_MAP:
        info['mechanism'] = SPEC_MAP[spec]
    elif spec:
        info['mechanism'] = spec

    # Parse stat attribute
    attr = s.get('attribute', '')
    if attr and attr in STAT_MAP:
        info['stat'] = STAT_MAP[attr]

    # Parse stat target
    affects_target = s.get('affects', '')
    if affects_target in AFFECTS_MAP:
        info['stat_target'] = AFFECTS_MAP[affects_target]

    return info

def get_pair_name(pair):
    base = [pk for pk in pair['pokemon'] if pk['kind'] == 'BASE']
    if not base:
        return 'Unknown'
    trainer = CHARS.get(pair['trainerId'], 'Unknown')
    pokemon = PKMN.get(base[0]['id'], 'Unknown')
    return f'{trainer} & {pokemon}'

# Build the output
output = []

for pair in pairs_data:
    pair_name = get_pair_name(pair)
    number = pair.get('entry', 0) // 100
    base_forms = [pk for pk in pair['pokemon'] if pk['kind'] == 'BASE']
    if not base_forms:
        continue
    base = base_forms[0]

    damage_passives = []

    # 1. Regular passives (skills on BASE form)
    for skill_entry in base.get('skills', []):
        sid = skill_entry[0]
        lock = skill_entry[1]
        if sid == 0:
            continue
        info = parse_skill_damage_info(sid)
        if info:
            name, desc = get_skill_name(sid, lock)
            damage_passives.append({
                'source': 'passive',
                'skillId': sid,
                'name': name,
                'description': desc,
                'locked': lock > 0,
                **info,
            })

    # 2. Super Awakening passive
    awk_id = pair.get('awakeningSkill')
    if awk_id and awk_id != 0:
        info = parse_skill_damage_info(awk_id)
        if info:
            name, desc = get_skill_name(awk_id, 0)
            damage_passives.append({
                'source': 'super_awakening',
                'skillId': awk_id,
                'name': name,
                'description': desc,
                **info,
            })

    # 3. Tera passives
    for pk in pair['pokemon']:
        if not pk['kind'].startswith('TERA'):
            continue
        base_skill_ids = {s[0] for s in base.get('skills', [])}
        for skill_entry in pk.get('skills', []):
            sid = skill_entry[0]
            if sid == 0 or sid in base_skill_ids:
                continue
            info = parse_skill_damage_info(sid)
            if info:
                name, desc = get_skill_name(sid, skill_entry[1])
                damage_passives.append({
                    'source': 'tera_passive',
                    'skillId': sid,
                    'name': name,
                    'description': desc,
                    **info,
                })

    # 4. Grid passives (MODIFIER and SKILL cells with damage skills)
    grid_id = pair.get('gridId', '')
    grid_versions = grids_data.get(grid_id, [])
    cells_by_pos = {}
    for ver in grid_versions:
        for cell in ver.get('cells', []):
            cells_by_pos[cell['position']] = cell

    cell_num = 0
    for pos, cell in cells_by_pos.items():
        cell_num += 1
        kind = cell.get('kind', '')
        skill_id = cell.get('skill', 0)
        value = cell.get('value', 0)

        if kind in ('MODIFIER', 'SKILL') and skill_id != 0:
            info = parse_skill_damage_info(skill_id)
            if info:
                name, desc = get_skill_name(skill_id, value)
                target_move = cell.get('target', '')
                source = 'grid_passive' if kind == 'MODIFIER' else 'grid_skill'
                entry = {
                    'source': source,
                    'skillId': skill_id,
                    'cellNumber': cell_num,
                    'name': name,
                    'description': desc,
                    'value': value,
                    **info,
                }
                if target_move and target_move not in ('PKMN', 'SYNC'):
                    move_name_data = en['DATA']['MOVES'].get(target_move, {})
                    entry['move_name'] = move_name_data.get('NAME', target_move)
                damage_passives.append(entry)

    if damage_passives:
        output.append({
            'syncPair': pair_name,
            'number': number,
            'passives': damage_passives,
        })

# Sort by number
output.sort(key=lambda x: (x['number'], x['syncPair']))

dst = os.path.join(BASE, 'assets', 'data', 'damage_passives.json')
with open(dst, 'w', encoding='utf-8') as f:
    json.dump(output, f, ensure_ascii=False, indent=2)

print(f'Done: {len(output)} pairs with damage passives')
total = sum(len(p['passives']) for p in output)
print(f'Total damage passives: {total}')
sources = {}
for p in output:
    for dp in p['passives']:
        s = dp.get('source', 'unknown')
        sources[s] = sources.get(s, 0) + 1
for s, c in sorted(sources.items()):
    print(f'  {s}: {c}')
