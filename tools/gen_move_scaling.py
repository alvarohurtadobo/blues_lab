"""
Generates assets/data/move_scaling.json

Cross-references PomaTools move database (201.*.js) with sync_pairs.json
to produce a lookup of innate move power scaling keyed by sync pair + move name.

Only includes non-sync moves with STAT_ powerup (RAISE_STAT / LOWER_STAT).
Sync moves use a standard formula and are handled separately.
"""
import json, sys, re

sys.stdout.reconfigure(encoding='utf-8')

# --- 1. Parse PomaTools move DB ---
with open('legacy/Pomatools/201.f24e83a2e7226478.js', 'r', encoding='utf-8') as f:
    content = f.read()

match = re.search(r"JSON\.parse\('(.+?)'\)", content)
raw = match.group(1).replace('\\"', '"')
poma_moves = json.loads(raw)

# Collect powerup entries with STAT_ scaling (non-sync only: kind == MV)
poma_scaling = {}  # moveId -> scaling info
for mid, d in poma_moves.items():
    if d.get('kind') != 'MV':
        continue
    for pu in d.get('powerup', []):
        if len(pu) < 3:
            continue
        stat = pu[1] if len(pu) > 1 else ''
        if not stat.startswith('STAT_'):
            continue
        direction = pu[2]
        if direction not in ('RAISE_STAT', 'LOWER_STAT'):
            continue
        raw_step = str(pu[3]) if len(pu) > 3 else '0'
        raw_cap = str(pu[4]) if len(pu) > 4 else '0'

        if '|' in raw_step:
            step_type = 'threshold_table'
            step_value = raw_step
        else:
            step_type = 'per_stage'
            step_value = int(raw_step)

        poma_scaling[int(mid)] = {
            'target': pu[0],
            'stat': stat,
            'direction': direction,
            'stepType': step_type,
            'stepValue': step_value,
            'cap': int(raw_cap) if raw_cap.isdigit() else 0,
            'power': d['power'],
        }

# --- 2. STAT code -> human-readable stat keys ---
STAT_MAP = {
    'STAT_001': 'hp',
    'STAT_002': 'atk',
    'STAT_004': 'def',
    'STAT_008': 'spa',
    'STAT_016': 'spd',
    'STAT_020': 'def_spd',   # combined Def + Sp.Def
    'STAT_032': 'spe',
    'STAT_064': 'acc',
    'STAT_128': 'eva',
    'STAT_510': 'all_stats',
}

TARGET_MAP = {
    'TARG_001': 'user',
    'TARG_004': 'target',
    'TARG_008': 'target',
}

# --- 3. Load sync_pairs.json and match moves ---
with open('assets/data/sync_pairs.json', 'r', encoding='utf-8') as f:
    pairs = json.load(f)

# Build a map: move power string containing STAT_ -> pair + move info
output = []
for pair in pairs:
    pair_name = pair['displayName']
    for move in pair['moves']:
        power_str = move.get('power', '')
        if 'STAT_' not in power_str or move.get('isSync', False):
            continue

        # Extract STAT_ code from power string like "100 (1)/STAT_020 (5↑ MAX)"
        stat_match = re.search(r'(STAT_\d+)', power_str)
        if not stat_match:
            continue
        stat_code = stat_match.group(1)

        # Extract base power
        base_match = re.search(r'^(\d+)', power_str)
        base_power = int(base_match.group(1)) if base_match else 0

        # Try to find matching poma entry by checking description for direction
        desc = move.get('description', '').lower()
        is_raised = 'raised' in desc
        is_lowered = 'lowered' in desc
        direction = 'RAISE_STAT' if is_raised else 'LOWER_STAT' if is_lowered else 'unknown'

        # Find the poma scaling entry that matches this stat + direction
        # We search by stat code since we can't reliably map move names to poma IDs
        matched_step = None
        matched_cap = 0
        matched_step_type = 'per_stage'
        for pid, ps in poma_scaling.items():
            if ps['stat'] == stat_code and ps['direction'] == direction and ps['power'] == base_power:
                matched_step = ps['stepValue']
                matched_cap = ps['cap']
                matched_step_type = ps['stepType']
                break

        # Default steps based on game mechanics if not found in poma
        if matched_step is None or matched_step == 0:
            if stat_code == 'STAT_510':
                # All stats: 20 per stage for pokemon moves (Stored Power style)
                matched_step = 20
            elif stat_code == 'STAT_020':
                # Combined def+spd: 250 per stage (Guzzlord)
                matched_step = 250
            else:
                # Single stat: standard is 100% per stage for pokemon moves
                matched_step = 1000

        stat_key = STAT_MAP.get(stat_code, stat_code)
        who = 'user' if is_raised else 'target'

        entry = {
            'syncPair': pair_name,
            'moveName': move['name'],
            'basePower': base_power,
            'stat': stat_key,
            'who': who,
            'direction': 'raised' if is_raised else 'lowered',
            'stepPer1000': matched_step if matched_step_type == 'per_stage' else 0,
        }

        if matched_step_type == 'threshold_table':
            entry['thresholdTable'] = matched_step
            entry['stepPer1000'] = 0

        if matched_cap > 0:
            entry['capPer1000'] = matched_cap

        output.append(entry)

output.sort(key=lambda x: (x['syncPair'], x['moveName']))

with open('assets/data/move_scaling.json', 'w', encoding='utf-8') as f:
    json.dump(output, f, indent=2, ensure_ascii=False)
    f.write('\n')

print(f'Generated {len(output)} entries in assets/data/move_scaling.json')
