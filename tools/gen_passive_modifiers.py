import json
import os

base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
src = os.path.join(base, 'assets', 'data', 'sync_pairs.json')
dst = os.path.join(base, 'assets', 'data', 'passive_modifiers.json')

data = json.load(open(src, encoding='utf-8'))

pairs_map = {}
for p in data:
    name = p['displayName']
    modifiers = [c for c in p['cells'] if 'Yellow' in c.get('colorKind', '') and c['title'] == 'Modifier']
    if modifiers:
        if name not in pairs_map:
            pairs_map[name] = []
        existing_cells = {e['cellNumber'] for e in pairs_map[name]}
        for c in modifiers:
            if c['cellNumber'] not in existing_cells:
                pairs_map[name].append({
                    'cellNumber': c['cellNumber'],
                    'passiveName': '',
                    'description': '',
                    'numericValue': 0
                })
                existing_cells.add(c['cellNumber'])

result = [{'syncPair': k, 'cells': v} for k, v in pairs_map.items()]

with open(dst, 'w', encoding='utf-8') as f:
    json.dump(result, f, ensure_ascii=False, indent=2)

print(f'Done: {len(result)} pairs, {sum(len(x["cells"]) for x in result)} cells')
