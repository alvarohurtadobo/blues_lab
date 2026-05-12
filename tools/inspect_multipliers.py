"""Inspect how 'value' is used in damage_passives.json.

Compare entries that have value!=0 with similar mechanisms.
"""
import io
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets" / "data"
with (ASSETS / "damage_passives.json").open(encoding="utf-8") as fh:
    dp = json.load(fh)

# Group by mechanism, show entries WITH value
by_mech = defaultdict(list)
for e in dp:
    if e.get("type") == "composite":
        for sp in e.get("sub_passives", []):
            mech = sp.get("mechanism", "")
            val = sp.get("value", 0) or sp.get("sub_value", 0)
            if mech:
                by_mech[mech].append((f"{e['name']}→{sp.get('name','')}", val, sp))
        continue
    mech = e.get("mechanism", "")
    val = e.get("value", 0)
    if mech:
        by_mech[mech].append((e['name'], val, e))


for mech, items in sorted(by_mech.items()):
    with_value = [(n, v, e) for n, v, e in items if v != 0]
    without_value = [(n, v, e) for n, v, e in items if v == 0]
    print(f"\n## mechanism = `{mech}`")
    print(f"  con value!=0: {len(with_value)} | con value=0: {len(without_value)}")
    # Print a few samples WITH value to understand pattern
    print("  ejemplos CON value:")
    for n, v, e in sorted(with_value, key=lambda x: x[0])[:8]:
        applies_to = e.get('applies_to','')
        stat = e.get('stat', '')
        st = e.get('stat_target','')
        cond = e.get('conditions', [])
        print(f"    - {n} value={v} applies_to={applies_to} stat={stat} stat_target={st} cond={cond}")
    if without_value:
        print("  ejemplos SIN value (primeros 5):")
        for n, v, e in without_value[:5]:
            print(f"    - {n}")
