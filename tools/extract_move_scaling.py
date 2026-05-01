import json, sys, re

sys.stdout.reconfigure(encoding='utf-8')

with open('legacy/Pomatools/201.f24e83a2e7226478.js', 'r', encoding='utf-8') as f:
    content = f.read()

match = re.search(r"JSON\.parse\('(.+?)'\)", content)
raw = match.group(1).replace('\\"', '"')
moves = json.loads(raw)

results = []
for mid, d in moves.items():
    for pu in d.get('powerup', []):
        if len(pu) < 3:
            continue
        stat = pu[1] if len(pu) > 1 else ''
        if not stat.startswith('STAT_'):
            continue
        direction = pu[2]
        if direction not in ('RAISE_STAT', 'LOWER_STAT'):
            continue
        # pu[3] can be "250" or "100,1000|50,800|33,650|0,550" (threshold table)
        raw_step = pu[3] if len(pu) > 3 else '0'
        raw_cap = pu[4] if len(pu) > 4 else '0'
        
        # Parse step: simple int or threshold table
        if '|' in str(raw_step):
            step_type = 'threshold_table'
            step_value = str(raw_step)
        else:
            step_type = 'per_stage'
            step_value = int(raw_step)
        
        results.append({
            'moveId': int(mid),
            'power': d['power'],
            'target': pu[0],
            'stat': stat,
            'direction': direction,
            'stepType': step_type,
            'stepValue': step_value,
            'cap': int(raw_cap) if str(raw_cap).isdigit() else 0,
        })

results.sort(key=lambda x: x['moveId'])
print(json.dumps(results, indent=2, ensure_ascii=False))
