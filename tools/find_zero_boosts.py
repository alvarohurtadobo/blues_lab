import json, sys
sys.stdout.reconfigure(encoding='utf-8')
data = json.load(open('assets/data/damage_passives.json', 'r', encoding='utf-8'))
zeros = []
for p in data:
    for pas in p['passives']:
        if pas.get('mechanism') == 'flat_boost' and pas.get('value', 0) == 0:
            zeros.append(f"{p['syncPair']} | {pas['name']} | main")
        for sp in pas.get('sub_passives', []):
            v = sp.get('sub_value', sp.get('value', 0))
            if sp.get('mechanism') == 'flat_boost' and v == 0:
                zeros.append(f"{p['syncPair']} | {sp.get('sub_name', '')} | sub")
print(f'Total flat_boost with value 0: {len(zeros)}')
for z in zeros:
    print(z)
