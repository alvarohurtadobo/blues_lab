#!/usr/bin/env python3
"""
Fix broken damage passives references and add missing entries.

Problems found:
1. 5 references in sync_pairs.json point to non-existent entries in damage_passives.json
2. Champion pairs like Ethan (Champion) are missing damagePassives entirely
"""

import json

def main():
    print("Loading sync_pairs.json...")
    with open('assets/data/sync_pairs.json', 'r', encoding='utf-8') as f:
        pairs = json.load(f)
    print(f"Loaded {len(pairs)} pairs")
    
    print("Loading damage_passives.json...")
    with open('assets/data/damage_passives.json', 'r', encoding='utf-8') as f:
        dp_master = json.load(f)
    print(f"Loaded {len(dp_master)} master entries")
    
    master_names = {m['name'] for m in dp_master}
    
    # ===== PROBLEM 1: 5 missing references in damage_passives.json =====
    missing_refs = [
        '1st S-Move: Dragon Zone & Extension 3',
        'Earth Power: Surging Sand 5',
        'Metal Burst: Critical Strike 3',
        'Normal Zone: Team S-Moves ↑ 3',
        'Opp Defense ↓: S-Moves ↑ 9',
    ]
    
    # Find which pairs reference them
    referencing = {ref: [] for ref in missing_refs}
    for pair in pairs:
        for dp in pair.get('damagePassives', []):
            if dp['name'] in missing_refs:
                referencing[dp['name']].append(pair)
    
    print("\n=== PROBLEM 1: Missing references ===")
    for ref, ref_pairs in referencing.items():
        names = [f"#{p['number']} {p['displayName']}" for p in ref_pairs]
        print(f"  '{ref}' referenced by: {', '.join(names) if names else 'NONE'}")
    
    # Add the missing entries to damage_passives.json
    new_entries = [
        {
            "name": "1st S-Move: Dragon Zone & Extension 3",
            "type": "powerup",
            "applies_to": "moves_and_sync",
            "affects": "self",
            "mechanism": "flat_boost",
            "value": 0,
            "stat": "",
            "stat_target": "",
            "conditions": [],
            "move_name": "",
            "sub_passives": []
        },
        {
            "name": "Earth Power: Surging Sand 5",
            "type": "powerup",
            "applies_to": "pokemon_moves",
            "affects": "self",
            "mechanism": "flat_boost",
            "value": 5,
            "stat": "",
            "stat_target": "",
            "conditions": [["sandstorm"]],
            "move_name": "",
            "sub_passives": []
        },
        {
            "name": "Metal Burst: Critical Strike 3",
            "type": "powerup",
            "applies_to": "moves",
            "affects": "self",
            "mechanism": "flat_boost",
            "value": 3,
            "stat": "",
            "stat_target": "",
            "conditions": [["critical"]],
            "move_name": "",
            "sub_passives": []
        },
        {
            "name": "Normal Zone: Team S-Moves ↑ 3",
            "type": "powerup",
            "applies_to": "sync_move",
            "affects": "team",
            "mechanism": "flat_boost",
            "value": 3,
            "stat": "",
            "stat_target": "",
            "conditions": [["normal_zone"]],
            "move_name": "",
            "sub_passives": []
        },
        {
            "name": "Opp Defense ↓: S-Moves ↑ 9",
            "type": "powerup",
            "applies_to": "sync_move",
            "affects": "self",
            "mechanism": "stat_is_lowered",
            "value": 9,
            "stat": "def",
            "stat_target": "target",
            "conditions": [],
            "move_name": "",
            "sub_passives": []
        },
    ]
    
    existing_names = {e['name'] for e in dp_master}
    added = 0
    for entry in new_entries:
        if entry['name'] not in existing_names:
            dp_master.append(entry)
            added += 1
            print(f"  Added '{entry['name']}' to damage_passives.json")
    
    # Save updated damage_passives.json
    with open('assets/data/damage_passives.json', 'w', encoding='utf-8') as f:
        json.dump(dp_master, f, ensure_ascii=False, indent=2)
    print(f"\nSaved damage_passives.json ({len(dp_master)} entries, {added} new)")
    
    # ===== PROBLEM 2: Pairs missing damagePassives =====
    print("\n=== PROBLEM 2: Pairs without damagePassives ===")
    
    # Ethan (Champion) & Raikou - Support with Johto team boost
    # This pair's passives are team-wide boosts that need damagePassive entries
    for pair in pairs:
        if pair.get('displayName', '') == 'Ethan (Champion) & Raikou (Genderless)':
            if not pair.get('damagePassives'):
                pair['damagePassives'] = [
                    {"name": "Johto C (Phys): S-Moves ↑ 9", "source": "passive", "cellNumber": None},
                    {"name": "Johto C (Spec): Team S-Moves ↑ 2", "source": "passive", "cellNumber": None},
                ]
                print(f"  Added damagePassives to #{pair['number']} {pair['displayName']}")
    
    # Save updated sync_pairs.json
    with open('assets/data/sync_pairs.json', 'w', encoding='utf-8') as f:
        json.dump(pairs, f, ensure_ascii=False, separators=(',', ':'))
    
    sz = __import__('os').path.getsize('assets/data/sync_pairs.json')
    print(f"\nSaved sync_pairs.json ({sz:,} bytes)")
    
    # Verify
    print("\n=== Verification ===")
    with open('assets/data/damage_passives.json', 'r', encoding='utf-8') as f:
        dp_master_v2 = json.load(f)
    master_names_v2 = {m['name'] for m in dp_master_v2}
    
    with open('assets/data/sync_pairs.json', 'r', encoding='utf-8') as f:
        pairs_v2 = json.load(f)
    
    still_missing = set()
    for pair in pairs_v2:
        for dp in pair.get('damagePassives', []):
            if dp['name'] not in master_names_v2:
                still_missing.add(dp['name'])
    
    if still_missing:
        print(f"  WARNING: {len(still_missing)} references still missing:")
        for m in sorted(still_missing):
            print(f"    - {m}")
    else:
        print(f"  ALL {len(master_names_v2)} references verified! ✓")
    
    print("\nDone!")

if __name__ == '__main__':
    main()