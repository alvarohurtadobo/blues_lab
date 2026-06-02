#!/usr/bin/env python3
"""
Fix: Connect Champion sync pairs to their Master Passives.

Problem: master_passives.json has 94 entries, but the sync_pairs.json
doesn't have the matching 'masterPassives' field for most of them.
This is because the pairing is done by displayName matching, and the
names must match EXACTLY between the two files.

Also, Ethan (Champion) has no entry at all in master_passives.json.
"""

import json
import os

def main():
    print("Loading files...")
    
    with open('assets/data/master_passives.json', 'r', encoding='utf-8') as f:
        master_list = json.load(f)
    
    with open('assets/data/sync_pairs.json', 'r', encoding='utf-8') as f:
        pairs = json.load(f)
    
    # Build lookup: normalize names for fuzzy matching
    master_entries = {}
    for entry in master_list:
        name = entry['syncPair']
        master_entries[name.lower().strip()] = entry
    
    # Check each pair
    matched = 0
    unmatched = []
    matched_pairs = []
    
    for pair in pairs:
        display_name = pair.get('displayName', '')
        display_lower = display_name.lower().strip()
        
        # Direct match
        matched_entry = None
        if display_lower in master_entries:
            matched_entry = master_entries[display_lower]
        else:
            # Fuzzy match: check if display_name CONTAINS a MP key or vice versa
            for mp_key, mp_val in master_entries.items():
                if mp_key in display_lower or display_lower in mp_key:
                    matched_entry = mp_val
                    break
        
        if matched_entry:
            matched += 1
            matched_pairs.append((pair['number'], display_name, matched_entry['passiveName']))
        else:
            # Only report Champion and Neo Champion that are missing
            if 'Champion' in display_name or 'Neo' in display_name:
                unmatched.append((pair['number'], display_name, pair.get('role', '')))
    
    print(f"\nMatched: {matched} pairs")
    print(f"Unmatched Champion/Neo: {len(unmatched)}")
    
    print("\n=== Matched pairs ===")
    for num, name, mp_name in matched_pairs[:10]:
        print(f"  #{num} {name} -> {mp_name}")
    if len(matched_pairs) > 10:
        print(f"  ... and {len(matched_pairs)-10} more")
    
    print("\n=== UNMATCHED Champions ===")
    for num, name, role in unmatched:
        print(f"  #{num} {name} ({role})")
    
    # Now add the missing master_passives entry for Ethan (Champion)
    print("\n\n=== Adding missing master_passives entries ===")
    added = 0
    
    # Ethan (Champion) & Raikou - "Johto's Thundering Legend"
    new_entry = {
        "syncPair": "Ethan (Champion) & Raikou (Genderless)",
        "passiveName": "Johto's Thundering Legend",
        "theme": "Johto",
        "category": "any",
        "appliesToSync": True,
        "basePowerUpPct": 20,
        "perAdditionalAllyPct": 15,
        "maxPowerUpPct": 50
    }
    
    existing_names = {e['syncPair'] for e in master_list}
    
    if new_entry['syncPair'] not in existing_names:
        master_list.append(new_entry)
        added += 1
        print(f"  Added '{new_entry['syncPair']}' -> '{new_entry['passiveName']}'")
    
    # Add missing Champion entries from docs
    # From 2.69.0 docs: Lyra (Champion) & Entei -> "Johto's Flaming Legend"
    new_entries = [
        {
            "syncPair": "Lyra (Champion) & Entei (Genderless)",
            "passiveName": "Johto's Flaming Legend",
            "theme": "Johto",
            "category": "any",
            "appliesToSync": True,
            "basePowerUpPct": 20,
            "perAdditionalAllyPct": 15,
            "maxPowerUpPct": 50
        },
    ]
    
    for entry in new_entries:
        if entry['syncPair'] not in existing_names:
            master_list.append(entry)
            added += 1
            print(f"  Added '{entry['syncPair']}' -> '{entry['passiveName']}'")
    
    # Save updated master_passives.json
    with open('assets/data/master_passives.json', 'w', encoding='utf-8') as f:
        json.dump(master_list, f, ensure_ascii=False, indent=2)
    print(f"\nSaved master_passives.json ({len(master_list)} entries, {added} new)")
    
    # Update sync_pairs.json: add masterPassives field where missing
    print("\n=== Adding masterPassives fields to sync_pairs.json ===")
    mp_updated = 0
    
    # Rebuild master lookup with added entries
    master_by_name = {}
    for entry in master_list:
        master_by_name[entry['syncPair'].lower().strip()] = entry
    
    for pair in pairs:
        display_name = pair.get('displayName', '')
        display_lower = display_name.lower().strip()
        
        # Skip if already has masterPassives
        if pair.get('masterPassives'):
            continue
        
        # Check if there's a matching master passive
        matched_mp = master_by_name.get(display_lower)
        if not matched_mp:
            # Try fuzzy match
            for mp_key, mp_val in master_by_name.items():
                if mp_key in display_lower or display_lower in mp_key:
                    matched_mp = mp_val
                    break
        
        if matched_mp:
            # Add the masterPassives field
            pair['masterPassives'] = [{
                'name': matched_mp['passiveName'],
                'theme': matched_mp['theme']
            }]
            mp_updated += 1
            if 'Champion' in display_name or 'Arc Suit' in display_name:
                print(f"  Added masterPassives to #{pair['number']} {display_name}")
    
    # Save updated sync_pairs.json
    with open('assets/data/sync_pairs.json', 'w', encoding='utf-8') as f:
        json.dump(pairs, f, ensure_ascii=False, separators=(',', ':'))
    
    sz = os.path.getsize('assets/data/sync_pairs.json')
    print(f"\nSaved sync_pairs.json ({sz:,} bytes, {mp_updated} pairs updated)")
    
    # Verify
    print("\n=== Verification ===")
    with open('assets/data/master_passives.json', 'r', encoding='utf-8') as f:
        mp_v2 = json.load(f)
    with open('assets/data/sync_pairs.json', 'r', encoding='utf-8') as f:
        pairs_v2 = json.load(f)
    
    pairs_with_mp = sum(1 for p in pairs_v2 if p.get('masterPassives'))
    total_mp_refs = sum(len(p.get('masterPassives', [])) for p in pairs_v2)
    mp_names_v2 = {e['syncPair'] for e in mp_v2}
    
    orphans = []
    for pair in pairs_v2:
        for mp_ref in pair.get('masterPassives', []):
            if mp_ref['name'] not in {e['passiveName'] for e in mp_v2}:
                orphans.append((pair['number'], pair['displayName'], mp_ref['name']))
    
    print(f"master_passives.json: {len(mp_v2)} entries")
    print(f"sync_pairs.json: {pairs_with_mp} pairs have masterPassives ({total_mp_refs} total refs)")
    
    if orphans:
        print(f"  WARNING: {len(orphans)} orphan references:")
        for num, name, ref in orphans:
            print(f"    #{num} {name}: '{ref}' not in master_passives.json")
    else:
        print(f"  All references verified! ✓")
    
    # Check Ethan Champion specifically
    ethan = [p for p in pairs_v2 if 'Ethan (Champion)' in p.get('displayName', '')]
    if ethan:
        p = ethan[0]
        print(f"\nEthan (Champion) now has:")
        print(f"  masterPassives: {p.get('masterPassives', 'NONE')}")
        print(f"  damagePassives: {[d['name'] for d in p.get('damagePassives', [])]}")

if __name__ == '__main__':
    main()