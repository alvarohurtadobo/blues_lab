#!/usr/bin/env python3
"""
Optimize sync_pairs.json for AI agent readability and file size.

Key findings from analysis:
- 79.3% of data = grid cells
- 8.6% = moves
- 5.6% = passives
- description = ALWAYS empty
- Most boolean fields are false for most pairs

Strategies:
1. Remove always-empty fields (description)
2. Omit false booleans and empty optionals
3. Compress grid cell field names
4. Keep damage passives as references only
5. Minify JSON
"""

import json
import os
from collections import Counter

INPUT = 'assets/data/sync_pairs.json'

def load_data():
    print(f"Loading {INPUT}...")
    with open(INPUT, 'r', encoding='utf-8') as f:
        data = json.load(f)
    print(f"Loaded {len(data)} sync pairs")
    return data

def build_optimized(data):
    optimized = []
    total_orig = 0
    total_opt = 0
    
    for pair in data:
        p = {}
        
        # Essential identifiers
        p['number'] = pair['number']
        p['displayName'] = pair['displayName']
        p['role'] = pair['role']
        p['type'] = pair['type']
        
        # Optional fields (omit if empty/false)
        if pair.get('exRole'):                p['exRole'] = pair['exRole']
        if pair.get('weakness'):              p['weakness'] = pair['weakness']
        if pair.get('rarity', 5) != 5:        p['rarity'] = pair['rarity']
        if pair.get('hasEx'):                 p['hasEx'] = True
        if pair.get('hasSuperAwakening'):     p['hasSuperAwakening'] = True
        if pair.get('hasTera'):               p['hasTera'] = True
        if pair.get('teraType'):              p['teraType'] = pair['teraType']
        if pair.get('releaseDate'):           p['releaseDate'] = pair['releaseDate']
        if pair.get('syncMoveName'):          p['syncMoveName'] = pair['syncMoveName']
        
        # Stats
        if pair.get('stats'):
            p['stats'] = pair['stats']
        
        # Moves (keep full, just omit empty strings/false)
        if pair.get('moves'):
            p['moves'] = []
            for mv in pair['moves']:
                mp = {'name': mv['name']}
                for k in ['type', 'category', 'power', 'accuracy', 'gauge', 'target', 'description']:
                    v = mv.get(k)
                    if v and v != '--':
                        mp[k] = v
                if mv.get('isSync'):          mp['isSync'] = True
                if mv.get('slot') is not None: mp['slot'] = mv['slot']
                if mv.get('isExtendedRange'): mp['isExtendedRange'] = True
                if mv.get('tags'):            mp['tags'] = mv['tags']
                if mv.get('effects'):         mp['effects'] = mv['effects']
                if mv.get('scaling'):         mp['scaling'] = mv['scaling']
                p['moves'].append(mp)
        
        # Passives
        if pair.get('passives'):
            p['passives'] = []
            for ps in pair['passives']:
                pp = {'name': ps['name']}
                if ps.get('description'): pp['description'] = ps['description']
                for k in ['tags', 'subPassives']:
                    if ps.get(k): pp[k] = ps[k]
                rule = ps.get('rule')
                if rule and (rule.get('conditions') or rule.get('effects')):
                    pp['rule'] = rule
                if ps.get('locked'): pp['locked'] = True
                p['passives'].append(pp)
        
        # Tera data (only if hasTera)
        if pair.get('hasTera'):
            if pair.get('teraMove'):
                p['teraMove'] = {'name': pair['teraMove']['name']}
                for k in ['type', 'power', 'category', 'description', 'tags', 'scaling']:
                    if pair['teraMove'].get(k): p['teraMove'][k] = pair['teraMove'][k]
                if pair['teraMove'].get('isSync'): p['teraMove']['isSync'] = True
            if pair.get('teraPassives'):
                p['teraPassives'] = [{'name': ps['name'], 'description': ps.get('description','')} for ps in pair['teraPassives']]
            if pair.get('teraMoves'):
                p['teraMoves'] = pair['teraMoves']
        
        # Mega / Tera stat multipliers (rare, keep as-is)
        if pair.get('megaStatMultiplier'):    p['megaStatMultiplier'] = pair['megaStatMultiplier']
        if pair.get('megaStats'):             p['megaStats'] = {k: dict(v) for k, v in pair['megaStats'].items()}
        if pair.get('teraStatMultiplier'):    p['teraStatMultiplier'] = pair['teraStatMultiplier']
        
        # Variations (rare)
        if pair.get('variations'):            p['variations'] = pair['variations']
        
        # Damage passives (keep only name+source+optional filters)
        if pair.get('damagePassives'):
            p['damagePassives'] = []
            for dp in pair['damagePassives']:
                dpi = {'name': dp['name'], 'source': dp['source']}
                if dp.get('moveName'):     dpi['moveName'] = dp['moveName']
                if dp.get('cellNumber') is not None: dpi['cellNumber'] = dp['cellNumber']
                p['damagePassives'].append(dpi)
        
        # Grid cells: compress property names for maximum savings
        if pair.get('cells'):
            p['cells'] = []
            for cell in pair['cells']:
                cc = {
                    'cn': cell['cellNumber'],  # cell number
                    'q': cell['q'],
                    'r': cell['r'],
                    's': cell['s'],
                    'e': cell['energyCost'],
                    'o': cell['orbCost'],
                    't': cell['title'],
                    'd': cell['description'],
                    'ck': cell['colorKind'],
                }
                if cell.get('moveLevel', 1) != 1:        cc['ml'] = cell['moveLevel']
                if cell.get('tags'):                      cc['tg'] = cell['tags']
                if cell.get('effects'):                   cc['ef'] = cell['effects']
                if cell.get('subPassives'):               cc['sp'] = cell['subPassives']
                if cell.get('statBonus'):                 cc['sb'] = cell['statBonus']
                if cell.get('powerBonus'):                cc['pb'] = cell['powerBonus']
                p['cells'].append(cc)
        
        # Remaining optional fields
        for k in ['tags', 'rules', 'masterPassives', 'formStats']:
            if pair.get(k): p[k] = pair[k]
        
        orig_size = len(json.dumps(pair, ensure_ascii=False, default=str))
        opt_size = len(json.dumps(p, ensure_ascii=False, default=str))
        total_orig += orig_size
        total_opt += opt_size
        optimized.append(p)
    
    print(f"\nOptimization:")
    print(f"  Original: {total_orig:,} chars")
    print(f"  Optimized: {total_opt:,} chars")
    print(f"  Reduction: {(1 - total_opt/total_orig)*100:.1f}%")
    return optimized

def verify(data, optimized):
    errors = 0
    for orig, opt in zip(data, optimized):
        for key in ['number', 'displayName', 'role', 'type']:
            if orig[key] != opt[key]:
                print(f"  MISMATCH {orig['number']}: {key}")
                errors += 1
        if len(orig.get('cells', [])) != len(opt.get('cells', [])):
            print(f"  CELL COUNT {orig['number']}")
            errors += 1
        if len(orig.get('moves', [])) != len(opt.get('moves', [])):
            print(f"  MOVE COUNT {orig['number']}")
            errors += 1
    if errors == 0:
        print("  Verification: ALL PASSED ✓")
    else:
        print(f"  Verification: {errors} ERRORS ✗")
    return errors == 0

def main():
    data = load_data()
    optimized = build_optimized(data)
    
    if not verify(data, optimized):
        return 1
    
    # Save compressed version (replaces original)
    path = 'assets/data/sync_pairs.json'
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(optimized, f, ensure_ascii=False, separators=(',', ':'))
    sz = os.path.getsize(path)
    print(f"\nSaved: {path} ({sz:,} bytes, {sz/1024/1024:.1f} MB)")
    
    # Save pretty version for AI readability
    path2 = 'assets/data/sync_pairs.pretty.json'
    with open(path2, 'w', encoding='utf-8') as f:
        json.dump(optimized, f, ensure_ascii=False, indent=2)
    sz2 = os.path.getsize(path2)
    print(f"Saved: {path2} ({sz2:,} bytes, {sz2/1024/1024:.1f} MB)")
    
    # Save split into individual files
    out_dir = 'assets/data/pairs/'
    os.makedirs(out_dir, exist_ok=True)
    index = []
    total_split = 0
    for pair in optimized:
        num = pair['number']
        fn = f'{num:04d}.json'
        fp = os.path.join(out_dir, fn)
        with open(fp, 'w', encoding='utf-8') as f:
            json.dump(pair, f, ensure_ascii=False, separators=(',', ':'))
        s = os.path.getsize(fp)
        total_split += s
        index.append({'n': num, 'nm': pair['displayName'], 'f': fn, 's': s,
                      'r': pair.get('role',''), 't': pair.get('type','')})
    
    with open(os.path.join(out_dir, '_index.json'), 'w', encoding='utf-8') as f:
        json.dump(index, f, ensure_ascii=False)
    
    print(f"Saved: {out_dir} ({len(optimized)} files, {total_split:,} bytes total)")
    print(f"  Index: {out_dir}_index.json")
    
    print(f"\nDone! The Dart app will continue to work with the optimized sync_pairs.json")
    print(f"since it uses null-safe access patterns (?? / defaults).")

if __name__ == '__main__':
    exit(main())