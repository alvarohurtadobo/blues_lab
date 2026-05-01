"""
Fixes sub_value in damage_passives.json composite passives by cross-referencing
with sync_pairs.json subPassives which have the correct values from the game.

The gen_damage_passives.py script extracts sub_value from PomaTools skill spec
strings, but these are often 0 for SA passives. The real values are in
sync_pairs.json under each passive's subPassives array.
"""
import json, sys, re

sys.stdout.reconfigure(encoding='utf-8')

with open('assets/data/sync_pairs.json', 'r', encoding='utf-8') as f:
    pairs = json.load(f)

with open('assets/data/damage_passives.json', 'rb') as f:
    dp_data = json.loads(f.read())

# Build lookup: pairName -> passiveName -> list of {subName, value}
sub_lookup = {}
for pair in pairs:
    name = pair['displayName']
    for pas in pair['passives']:
        if pas.get('subPassives'):
            key = f"{name}|{pas['name']}"
            subs = []
            for sp in pas['subPassives']:
                subs.append({
                    'name': sp['name'],
                    'value': sp['value'],
                    'description': sp['description'],
                })
            sub_lookup[key] = subs

fixed = 0
for dp_entry in dp_data:
    pair_name = dp_entry['syncPair']
    for pas in dp_entry['passives']:
        if not pas.get('sub_passives'):
            continue
        
        # Find matching passive in sync_pairs.json
        lookup_key = f"{pair_name}|{pas['name']}"
        sp_data = sub_lookup.get(lookup_key)
        if not sp_data:
            continue
        
        for dp_sub in pas['sub_passives']:
            sub_name = dp_sub.get('sub_name', '')
            # Match by name
            for sp in sp_data:
                if sp['name'] == sub_name:
                    old_val = dp_sub.get('sub_value', 0)
                    new_val = sp['value']
                    if old_val != new_val:
                        dp_sub['sub_value'] = new_val
                        fixed += 1
                        print(f'Fixed: {pair_name} | {sub_name} | {old_val} -> {new_val}')
                    break
            else:
                # Try fuzzy match: strip trailing number from sub_name
                base_sub = re.sub(r'\s*\d+\s*$', '', sub_name).strip()
                for sp in sp_data:
                    base_sp = re.sub(r'\s*\d+\s*$', '', sp['name']).strip()
                    if base_sub == base_sp:
                        old_val = dp_sub.get('sub_value', 0)
                        new_val = sp['value']
                        if old_val != new_val:
                            dp_sub['sub_value'] = new_val
                            # Also fix the sub_name to match
                            dp_sub['sub_name'] = sp['name']
                            fixed += 1
                            print(f'Fixed (fuzzy): {pair_name} | {sub_name} -> {sp["name"]} | {old_val} -> {new_val}')
                        break

content = json.dumps(dp_data, indent=2, ensure_ascii=False)
content = content.replace('\n', '\r\n')
with open('assets/data/damage_passives.json', 'wb') as f:
    written = f.write(content.encode('utf-8'))

print(f'\nTotal fixes: {fixed}, bytes written: {written}')
