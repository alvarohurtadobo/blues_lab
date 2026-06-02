#!/usr/bin/env python3
"""Inspect specific sync pairs and verify damage passives integrity."""

import json, os, sys

def find_pairs(data, keyword):
    """Search for pairs by keyword in displayName."""
    results = []
    for p in data:
        name = p.get('displayName', '')
        if keyword.lower() in name.lower():
            results.append(p)
    return results

def show_pair(pair):
    """Display a pair's key data (excluding cells)."""
    info = {k: v for k, v in pair.items() if k != 'cells'}
    print(json.dumps(info, ensure_ascii=False, indent=2))

def check_damage_passives(data):
    """Check damage passives completeness."""
    total_pairs = len(data)
    pairs_with_dp = sum(1 for p in data if p.get('damagePassives'))
    total_dp_entries = sum(len(p.get('damagePassives', [])) for p in data)
    
    print(f"Total pairs: {total_pairs}")
    print(f"Pairs with damagePassives: {pairs_with_dp} ({pairs_with_dp/total_pairs*100:.1f}%)")
    print(f"Total damagePassive entries: {total_dp_entries}")
    
    # Load master damage_passives.json
    try:
        with open('assets/data/damage_passives.json', 'r', encoding='utf-8') as f:
            master = json.load(f)
        print(f"Master damage_passives.json entries: {len(master)}")
        
        # Check if all referenced passives exist in master
        missing = []
        ref_names = set()
        for p in data:
            for dp in p.get('damagePassives', []):
                ref_names.add(dp['name'])
        
        master_names = {m['name'] for m in master}
        for ref in sorted(ref_names):
            if ref not in master_names:
                missing.append(ref)
        
        if missing:
            print(f"\n⚠️  {len(missing)} referenced passives NOT in master:")
            for m in missing[:20]:
                print(f"    {m}")
        else:
            print(f"\n✅ All {len(ref_names)} referenced passives found in master")
    except FileNotFoundError:
        print("\n⚠️  damage_passives.json not found")

def check_recent_pairs(data):
    """Find the most recent pairs by release date."""
    with_dates = [(p.get('releaseDate', ''), p) for p in data if p.get('releaseDate')]
    with_dates.sort(key=lambda x: x[0], reverse=True)
    
    print(f"\nMost recent pairs by release date:")
    for date, p in with_dates[:15]:
        dp = p.get('damagePassives', [])
        dp_names = [d['name'] for d in dp]
        print(f"  {date}: #{p['number']} {p['displayName']} ({p['role']}/{p['type']}) - {len(dp)} damage passives")
        if dp_names:
            for n in dp_names:
                print(f"           - {n}")

def check_for_newest_moves(data):
    """Check the newest pairs for their moves and passives."""
    with_dates = [(p.get('releaseDate', ''), p) for p in data if p.get('releaseDate')]
    with_dates.sort(key=lambda x: x[0], reverse=True)
    
    # Pick a recent one to show in detail
    target = 'Ethan'
    for _, p in with_dates:
        if target.lower() in p['displayName'].lower():
            print(f"\n{'='*60}")
            print(f"DETAIL: {p['displayName']} #{p['number']}")
            print(f"{'='*60}")
            info = {k: v for k, v in p.items() if k not in ['cells', 'stats', 'tags']}
            print(json.dumps(info, ensure_ascii=False, indent=2))
            break
    else:
        print(f"\n⚠️  No pair found with '{target}' in name")

def main():
    print("Loading sync_pairs.json...")
    with open('assets/data/sync_pairs.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
    print(f"Loaded {len(data)} pairs\n")
    
    # Search for specific pairs
    for keyword in ['Ethan', 'Champion', 'SS ', 'Neo Champion']:
        results = find_pairs(data, keyword)
        if results:
            print(f"\n'{keyword}': {len(results)} matches")
            for p in results:
                dp = p.get('damagePassives', [])
                dp_str = ', '.join(d['name'] for d in dp[:3])
                if len(dp) > 3:
                    dp_str += f' ...({len(dp)} total)'
                print(f"  #{p['number']} {p['displayName']} ({p['role']}/{p['type']}) - passives: {dp_str or 'NONE'}")
    
    # Check damage passives system
    print(f"\n{'='*60}")
    print("DAMAGE PASSIVES SYSTEM")
    print(f"{'='*60}")
    check_damage_passives(data)
    
    # Check recent pairs
    print(f"\n{'='*60}")
    print("RECENT PAIRS")
    print(f"{'='*60}")
    check_recent_pairs(data)
    
    # Show Ethan (Champion) in detail
    check_for_newest_moves(data)
    
    print(f"\n{'='*60}")
    print("MASTER PASSIVES CHECK")
    print(f"{'='*60}")
    try:
        with open('assets/data/master_passives.json', 'r', encoding='utf-8') as f:
            mp = json.load(f)
        print(f"Master passives entries: {len(mp)}")
        # Check how many pairs reference master passives
        pairs_with_mp = sum(1 for p in data if p.get('masterPassives'))
        print(f"Pairs with masterPassives field: {pairs_with_mp}")
    except FileNotFoundError:
        print("master_passives.json not found")

if __name__ == '__main__':
    main()