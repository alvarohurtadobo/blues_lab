#!/usr/bin/env python3
"""Investigate how master passives flow through the system."""
import json

with open('assets/data/sync_pairs.json', 'r', encoding='utf-8') as f:
    pairs = json.load(f)
with open('assets/data/master_passives.json', 'r', encoding='utf-8') as f:
    mp = json.load(f)
with open('assets/data/damage_passives.json', 'r', encoding='utf-8') as f:
    dp = json.load(f)

# 1. Find Ethan (Champion) and check his passives
ethan = [p for p in pairs if 'Ethan (Champion)' in p.get('displayName', '')]
if ethan:
    p = ethan[0]
    print(f"=== {p['displayName']} ===")
    print(f"masterPassives: {p.get('masterPassives', 'NOT SET')}")
    print(f"damagePassives: {[d['name'] for d in p.get('damagePassives', [])]}")
    print(f"passives count: {len(p.get('passives', []))}")
    for ps in p.get('passives', []):
        print(f"  - {ps['name']}")
        if ps.get('subPassives'):
            for sp in ps['subPassives']:
                print(f"      sub: {sp['name']}")

# 2. Check which entries in master_passives.json are actually referenced
all_mp_names = {m['passiveName'] for m in mp}
referenced_mp = set()
for pair in pairs:
    for mp_ref in pair.get('masterPassives', []):
        referenced_mp.add(mp_ref['name'])

print(f"\n=== Master passives: {len(all_mp_names)} entries, {len(referenced_mp)} referenced ===")
unreferenced = all_mp_names - referenced_mp
print(f"Unreferenced: {len(unreferenced)}")
for name in sorted(unreferenced)[:10]:
    print(f"  - {name}")

# 3. Check the calculator code
print("\n=== How master passives are calculated ===")
print("_masterPassives reads widget.pair.masterPassives")
print("_masterPassivePowerUp loops over them and uses powerUpForAdditionalAllies")
print("This is added to totalSkillMult in _totalBp")
print()
print("PROBLEM: masterPassives field is empty for ALL pairs!")