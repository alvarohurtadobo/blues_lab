#!/usr/bin/env python3
"""Audit all moves with extended range (power not lowered vs multiple targets)."""
import json

with open('assets/data/sync_pairs.json', 'r', encoding='utf-8') as f:
    pairs = json.load(f)

extended = []
for p in pairs:
    for m in p.get('moves', []):
        desc = m.get('description', '')
        if 'power of this move is not lowered' in desc.lower() or \
           'not lowered even if there are multiple' in desc.lower():
            extended.append({
                'pair_num': p.get('number', 0),
                'pair_name': p.get('displayName', ''),
                'move_name': m.get('name', ''),
                'power_base': m.get('power', [0, 0])[0] if isinstance(m.get('power'), list) else m.get('power', 0),
                'power_max': m.get('power', [0, 0])[1] if isinstance(m.get('power'), list) else 0,
                'move_type': m.get('type', ''),
                'category': m.get('category', ''),
                'gauge': m.get('gauge', 0),
                'target': m.get('target', ''),
                'desc': desc[:120],
            })

print(f"Total moves with extended range: {len(extended)}\n")
print(f"{'Move':<35} {'Type':<8} {'Pow':<6} {'Gauge':<6} {'Target':<18} {'Pair'}")
print("-" * 110)

for e in extended:
    power = f"{e['power_base']}" if e['power_max'] == 0 else f"{e['power_base']}/{e['power_max']}"
    print(f"{e['move_name']:<35} {e['move_type']:<8} {power:<6} {e['gauge']:<6} {e['target']:<18} #{e['pair_num']} {e['pair_name'][:40]}")

print(f"\n\n=== By target type ===")
by_target = {}
for e in extended:
    t = e['target']
    if t not in by_target:
        by_target[t] = []
    by_target[t].append(e)

for t, moves in sorted(by_target.items()):
    print(f"\n{t} ({len(moves)} moves):")
    for m in moves:
        print(f"  {m['move_name']} (power={m['power_base']}) - {m['pair_name']}")