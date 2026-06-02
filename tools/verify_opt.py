import json, os

with open('assets/data/sync_pairs.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

print(f'Valid JSON: {len(data)} pairs')
for p in data[:3]:
    num = p['number']
    name = p['displayName']
    role = p['role']
    ptype = p['type']
    cells = len(p.get('cells', []))
    moves = len(p.get('moves', []))
    print(f'  #{num} {name} ({role}/{ptype}) cells={cells} moves={moves}')

backup = os.path.getsize('assets/data/sync_pairs.backup.json')
active = os.path.getsize('assets/data/sync_pairs.json')
pretty = os.path.getsize('assets/data/sync_pairs.pretty.json')

print(f'\nBackup: {backup/1024/1024:.1f} MB')
print(f'Active: {active/1024/1024:.1f} MB')
print(f'Pretty: {pretty/1024/1024:.1f} MB')

import glob
files = glob.glob('assets/data/pairs/**/*.json', recursive=True)
print(f'\nPairs folder: {len(files)} files')