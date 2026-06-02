#!/usr/bin/env python3
"""
Fix 3 remaining issues:
1. Earth-Shaking Roar (Ethan Champion) - missing Electric Terrain team damage passives
2. Lyra (Champion) & Entei - missing sync buff scaling and Burn Synergy move-specific
3. Check for missing grid/move damage passives
"""

import json
import os

with open('assets/data/damage_passives.json', 'r', encoding='utf-8') as f:
    dp = json.load(f)

with open('assets/data/sync_pairs.json', 'r', encoding='utf-8') as f:
    pairs = json.load(f)

existing_names = {e['name'] for e in dp}

# ===== ISSUE 1: Earth-Shaking Roar =====
print("=" * 60)
print("ISSUE 1: Earth-Shaking Roar - Adding Electric Terrain team effects")
print("=" * 60)

new_entries = [
    {
        "name": "Earth-Shaking Roar (Moves)",
        "type": "powerup",
        "applies_to": "pokemon_moves",
        "affects": "team",
        "mechanism": "flat_boost",
        "value": 2,
        "stat": "",
        "stat_target": "",
        "conditions": [["electric_terrain"]],
        "move_name": "",
        "sub_passives": []
    },
    {
        "name": "Earth-Shaking Roar (Sync)",
        "type": "powerup",
        "applies_to": "sync_move",
        "affects": "team",
        "mechanism": "flat_boost",
        "value": 2,
        "stat": "",
        "stat_target": "",
        "conditions": [["electric_terrain"]],
        "move_name": "",
        "sub_passives": []
    },
    {
        "name": "Earth-Shaking Roar (DR)",
        "type": "reducer",
        "applies_to": "pokemon_moves",
        "affects": "team",
        "mechanism": "",
        "value": 2,
        "stat": "",
        "stat_target": "",
        "conditions": [["electric_terrain"]],
        "move_name": "",
        "sub_passives": []
    },
]

for entry in new_entries:
    if entry['name'] not in existing_names:
        dp.append(entry)
        print(f"  Added: {entry['name']}")
        existing_names.add(entry['name'])
    else:
        print(f"  Already exists: {entry['name']}")

# Add them as damagePassives to Ethan (Champion)
for p in pairs:
    if 'Ethan (Champion)' in p.get('displayName', ''):
        existing_refs = {r['name'] for r in p.get('damagePassives', [])}
        added = 0
        for entry in new_entries:
            if entry['name'] not in existing_refs:
                p['damagePassives'].append({
                    "name": entry['name'],
                    "source": "passive",
                    "cellNumber": None
                })
                added += 1
        print(f"  Added {added} new damagePassive refs to Ethan (Champion)")
        break

# ===== ISSUE 2: Lyra (Champion) & Entei =====
print("\n" + "=" * 60)
print("ISSUE 2: Lyra (Champion) & Entei - Move passives")
print("=" * 60)

for p in pairs:
    if 'Lyra (Champion)' in p.get('displayName', ''):
        existing_refs = {r['name'] for r in p.get('damagePassives', [])}
        print(f"Current damagePassives: {existing_refs}")
        
        # Need to add Burn Synergy for Reigning Sacred Fire (move-specific)
        # And Superduper Effective for sync move
        # These already exist, let's check
        needed = [
            {"name": "Burn Synergy 3", "source": "passive", "cellNumber": None},
            {"name": "Superduper Effective 1", "source": "passive", "cellNumber": None},
            {"name": "Haymaker", "source": "passive", "cellNumber": None},
        ]
        added = 0
        for n in needed:
            if n['name'] not in existing_refs:
                p['damagePassives'].append(n)
                added += 1
                print(f"  Added: {n['name']}")
        if added == 0:
            print("  All needed passives already present!")
        break

# ===== ISSUE 3: Check for missing move-specific passives =====
print("\n" + "=" * 60)
print("ISSUE 3: Checking for missing grid passive references")
print("=" * 60)

# Find damagePassives in sync_pairs that don't exist in damage_passives.json
all_refs = set()
for pair in pairs:
    for d in pair.get('damagePassives', []):
        all_refs.add(d['name'])

missing = all_refs - existing_names
if missing:
    print(f"WARNING: {len(missing)} references still missing in damage_passives.json:")
    for m in sorted(missing):
        # Find which pairs reference it
        refs = []
        for pair in pairs:
            for d in pair.get('damagePassives', []):
                if d['name'] == m:
                    refs.append((pair['number'], pair.get('displayName', '')))
        for num, name in refs:
            print(f"  '{m}' referenced by #{num} {name}")
else:
    print(f"ALL {len(all_refs)} references verified! ✓")

# Save damage_passives.json
with open('assets/data/damage_passives.json', 'w', encoding='utf-8') as f:
    json.dump(dp, f, ensure_ascii=False, indent=2)
print(f"\nSaved damage_passives.json ({len(dp)} entries)")

# Save sync_pairs.json
with open('assets/data/sync_pairs.json', 'w', encoding='utf-8') as f:
    json.dump(pairs, f, ensure_ascii=False, separators=(',', ':'))
sz = os.path.getsize('assets/data/sync_pairs.json')
print(f"Saved sync_pairs.json ({sz:,} bytes)")

print("\nDone!")