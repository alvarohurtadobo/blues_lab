"""Inspect the 8 multi-form pairs to decide statMultiplier needs."""
import io, json, sys
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets" / "data"
sp = json.load(open(ASSETS / "sync_pairs.json", encoding="utf-8"))

for p in sp:
    if not p.get('variations'):
        continue
    pname = p['displayName']
    pn = pname.encode('ascii','replace').decode('ascii')
    print(f"\n=== {pn} ===")
    print(f"  base type: {p.get('type','')}, role: {p.get('role','')}")
    print(f"  base stats:")
    for level, stats in p.get('stats', {}).items():
        if level == '125':
            print(f"    L{level}: {stats}")
    for i, v in enumerate(p['variations'], 1):
        fname = v.get('formName','?').encode('ascii','replace').decode('ascii')
        statm = v.get('statMultiplier', {})
        moves = v.get('moves', [])
        passives = v.get('passives', [])
        print(f"\n  Variation {i}: '{fname}'")
        print(f"    statMultiplier: {statm or '(empty)'}")
        # If statMultiplier is empty, summarize what the variation contains
        if not statm:
            new_moves = [m.get('name','') for m in moves]
            new_pass = [pa.get('name','') for pa in passives]
            print(f"    moves changes: {new_moves}")
            print(f"    passive changes: {new_pass}")
