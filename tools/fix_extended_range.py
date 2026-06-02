#!/usr/bin/env python3
"""Fix all moves with extended range descriptions but missing isExtendedRange=true."""
import json

with open('assets/data/sync_pairs.json', 'r', encoding='utf-8') as f:
    pairs = json.load(f)

fixed = 0
already = 0
missing_desc = 0

for p in pairs:
    for m in p.get('moves', []):
        ext = m.get('isExtendedRange')
        desc = m.get('description', '')
        target = m.get('target', '')
        
        # Check if description says power is not lowered
        has_ext_desc = 'power of this move is not lowered' in desc.lower() or \
                       'not lowered even if there are multiple' in desc.lower()
        
        if has_ext_desc:
            if ext is True:
                already += 1
            else:
                # Missing or false, set it to True
                m['isExtendedRange'] = True
                fixed += 1
                if ext is None:
                    print(f"  FIXED: #{p['number']} {m['name']} ({p['displayName'][:40]}) - was unset")
                else:
                    print(f"  FIXED: #{p['number']} {m['name']} ({p['displayName'][:40]}) - was {ext}")

# Also check AoE moves that have isExtendedRange flag from import
for p in pairs:
    for m in p.get('moves', []):
        ext = m.get('isExtendedRange')
        target = m.get('target', '')
        if ext is True and 'All opponents' not in target:
            print(f"  WARNING: #{p['number']} {m['name']} has extendedRange but target={target}")

print(f"\nSummary:")
print(f"  Already set correctly: {already}")
print(f"  Fixed (was missing/wrong): {fixed}")
print(f"  Total extended range moves: {already + fixed}")

# Save
with open('assets/data/sync_pairs.json', 'w', encoding='utf-8') as f:
    json.dump(pairs, f, ensure_ascii=False, separators=(',', ':'))

import os
sz = os.path.getsize('assets/data/sync_pairs.json')
print(f"Saved sync_pairs.json ({sz:,} bytes)")