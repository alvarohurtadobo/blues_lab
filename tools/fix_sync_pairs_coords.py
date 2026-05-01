"""
Fixes sync_pairs.json coordinates for new format pairs.
New format pairs (with Male/Female/Genderless in name) have r and s swapped
compared to PomaTools format. This script swaps them to normalize all pairs
to the same coordinate system.
"""
import json, sys

sys.stdout.reconfigure(encoding='utf-8')

path = 'assets/data/sync_pairs.json'
with open(path, 'rb') as f:
    data = json.loads(f.read())

fixed_pairs = 0
fixed_cells = 0

for pair in data:
    name = pair['displayName']
    if 'Male' not in name and 'Female' not in name and 'Genderless' not in name:
        continue
    
    for cell in pair.get('cells', []):
        old_r = cell['r']
        old_s = cell['s']
        cell['r'] = old_s
        cell['s'] = old_r
        fixed_cells += 1
    
    fixed_pairs += 1
    print(f'Fixed: {name} ({len(pair.get("cells", []))} cells)')

content = json.dumps(data, indent=None, ensure_ascii=False, separators=(',', ':'))
with open(path, 'wb') as f:
    written = f.write(content.encode('utf-8'))

print(f'\nTotal: {fixed_pairs} pairs, {fixed_cells} cells fixed, {written} bytes written')
