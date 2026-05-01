import json, sys

sys.stdout.reconfigure(encoding='utf-8')

path = 'assets/data/damage_passives.json'
with open(path, 'rb') as f:
    data = json.loads(f.read())

fixed = 0

# Map of description keywords -> wrong condition -> correct condition
FIXES = [
    ('when the target is confused', 'flinching', 'confused'),
    ('fairy zone', 'ice_zone', 'fairy_zone'),
    ('dragon zone', 'water_zone', 'dragon_zone'),
    ('when the target is burned', 'frozen', 'burned'),
    ('when the target is frozen', 'poisoned', 'frozen'),
    ('when the target is poisoned', 'burned', 'poisoned'),
    ('when the weather is rainy', 'sunny', 'rainy'),
    ('when the weather is sunny', 'rain', 'sunny'),
    ('during a hailstorm', 'hail', 'hail'),  # no-op check
    ('during a sandstorm', 'sandstorm', 'sandstorm'),  # no-op check
]

def fix_conditions(desc, conds, context):
    global fixed
    desc_lower = desc.lower()
    for keyword, wrong, correct in FIXES:
        if keyword in desc_lower and wrong != correct:
            for g in conds:
                for i, c in enumerate(g):
                    if c == wrong:
                        g[i] = correct
                        fixed += 1
                        print(f'Fixed {context}: {keyword} | {wrong} -> {correct}')

for p in data:
    pair_name = p['syncPair']
    for pas in p['passives']:
        # Fix sub_passives
        for sp in pas.get('sub_passives', []):
            desc = sp.get('sub_description', '') or sp.get('description', '')
            conds = sp.get('conditions', [])
            fix_conditions(desc, conds, f'{pair_name} sub:{sp.get("sub_name", "")}')

        # Fix main passive
        desc = pas.get('description', '')
        conds = pas.get('conditions', [])
        fix_conditions(desc, conds, f'{pair_name} main:{pas.get("name", "")}')

content = json.dumps(data, indent=2, ensure_ascii=False)
content = content.replace('\n', '\r\n')
with open(path, 'wb') as f:
    written = f.write(content.encode('utf-8'))

print(f'Total fixes: {fixed}, bytes written: {written}')
