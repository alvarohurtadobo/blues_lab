#!/usr/bin/env python3
"""Investigate 3 issues:
1. Earth-Shaking Roar (Ethan Champion) - +20% on Electric Terrain not working
2. Sync buff scaling for Lyra Champion - should be 10% innato
3. Missing grid/move damage passives
"""

import json

with open('assets/data/sync_pairs.json', 'r', encoding='utf-8') as f:
    pairs = json.load(f)
with open('assets/data/damage_passives.json', 'r', encoding='utf-8') as f:
    dp_master = json.load(f)

print("=" * 60)
print("ISSUE 1: Earth-Shaking Roar - Ethan (Champion)")
print("=" * 60)

ethan = [p for p in pairs if 'Ethan (Champion)' in p.get('displayName', '')]
if ethan:
    p = ethan[0]
    print(f"\nPair: {p['displayName']}")
    print(f"damagePassives: {[d['name'] for d in p.get('damagePassives', [])]}")
    
    # Earth-Shaking Roar = "Powers up moves/sync moves on Electric Terrain, reduces damage"
    # This needs damage passives entries!
    # Check if any existing entries cover what we need
    existing_names = {e['name'] for e in dp_master}
    needed = [
        "Earth-Shaking Roar (Moves)",
        "Earth-Shaking Roar (Sync)",
        "Earth-Shaking Roar (DR)",
    ]
    for n in needed:
        if n in existing_names:
            print(f"  EXISTS: {n}")
        else:
            print(f"  MISSING: {n}")
    
    # Check current Terrain related team passives
    for e in dp_master:
        if 'earth' in e['name'].lower() or 'electric_terrain' in ' '.join(c[0] for c in e.get('conditions',[])):
            pass
    # Check what team effects already exist for electric terrain
    team_on_terrain = [e for e in dp_master if e.get('affects') == 'team' and 
                      any(c[0] == 'electric_terrain' for c in e.get('conditions',[]))]
    print(f"\nExisting team effects on Electric Terrain:")
    for e in team_on_terrain:
        print(f"  {e['name']} -> type={e['type']} value={e['value']}")

print("\n" + "=" * 60)
print("ISSUE 2: Lyra (Champion) & Entei - Sync Buff Scaling")
print("=" * 60)

lyra = [p for p in pairs if 'Lyra (Champion)' in p.get('displayName', '')]
if lyra:
    p = lyra[0]
    print(f"\nPair: {p['displayName']}")
    print(f"masterPassives: {p.get('masterPassives', [])}")
    print(f"damagePassives: {[d['name'] for d in p.get('damagePassives', [])]}")
    print(f"Passives:")
    for ps in p.get('passives', []):
        print(f"  - {ps['name']}")
        for sp in ps.get('subPassives', []):
            print(f"      sub: {sp['name']}")

    # Check master_passives entry
    with open('assets/data/master_passives.json', 'r', encoding='utf-8') as f:
        mp = json.load(f)
    for m in mp:
        if 'Lyra (Champion)' in m['syncPair'] or lyra[0]['displayName'] == m['syncPair']:
            print(f"\nMaster Passive entry: {json.dumps(m, ensure_ascii=False)}")
        if 'Entei' in m['syncPair']:
            print(f"Entei entry: {json.dumps(m, ensure_ascii=False)}")

print("\n" + "=" * 60)
print("ISSUE 3: Missing grid passives and passive effects within moves")
print("=" * 60)

# Check the Calculator for what applies damagePassives
# Find all passive names in damage_passives that have move_name set (move-specific)
move_passives = [e for e in dp_master if e.get('move_name')]
print(f"\nDamage passives tied to specific moves: {len(move_passives)}")
for mp in move_passives[:5]:
    print(f"  {mp['name']} -> move: {mp['move_name']}")

# Check how the calc processes damage passives
# Search for patterns where conditions are checked
print("\nAll unique conditions used:")
all_conds = set()
for e in dp_master:
    for cond_list in e.get('conditions', []):
        for cond in cond_list:
            all_conds.add(cond)
print(f"Total unique conditions: {len(all_conds)}")
for c in sorted(all_conds):
    cnt = sum(1 for e in dp_master if any(c in cl for cl in e.get('conditions',[])))
    print(f"  {c}: {cnt} entries")