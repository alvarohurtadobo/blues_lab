#!/usr/bin/env python3
"""Check all Champion/Sygna Suit/Arc Suit pairs have their master passives."""
import json

with open('assets/data/sync_pairs.json', 'r', encoding='utf-8') as f:
    pairs = json.load(f)

with open('assets/data/master_passives.json', 'r', encoding='utf-8') as f:
    mp = json.load(f)

mp_names = {e['syncPair'].lower().strip() for e in mp}

# Champion pairs from 2.68.0 and 2.69.0 update docs
targets = [
    'Arc Suit Korrina & Lucario (Male)',
    'Arc Suit Sabrina & Alakazam (Male)',
    'Sygna Suit Kris & Suicune',
    'Sygna Suit Ethan & Lugia',
    'Cheren (Champion) & Tornadus',
    'Bianca (Champion) & Virizion',
]

print("Checking Champion/Sygna Suit/Arc Suit pairs...")
found = 0
for p in pairs:
    name = p.get('displayName', '').lower()
    # Check if this is a champion/arc/sygna suit pair
    is_special = any(t.lower() in name for t in targets) or \
                 'champion' in name or \
                 'arc suit' in name or \
                 'sygna suit' in name
    
    if is_special:
        has = bool(p.get('masterPassives'))
        if has:
            refs = [r['name'] for r in p['masterPassives']]
            status = f"OK: {', '.join(refs)}"
        else:
            status = "MISSING!"
            # Check if name matches in master_passives
            if name in mp_names:
                status = "MP EXISTS but not connected!"
            else:
                # Close match?
                close = [m for m in mp_names if name[:20] in m or m[:20] in name]
                if close:
                    status = f"MP close match: {close[0]}"
        
        found += 1
        flag = "✓" if has else "✗"
        print(f"  {flag} #{p['number']} {p['displayName']}: {status}")

print(f"\nTotal checked: {found}")