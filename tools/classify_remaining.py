"""Classify the 41 remaining passive names against the damage guide tables.

Look up each passive's description from sync_pairs.json to pinpoint the formula.
"""
import io
import json
import sys
from collections import defaultdict
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets" / "data"

with (ASSETS / "sync_pairs.json").open(encoding="utf-8") as fh:
    pairs = json.load(fh)
with (ASSETS / "damage_passives.json").open(encoding="utf-8") as fh:
    dp = json.load(fh)

REMAINING = {
    "Added Insult", "Blind Spot", "Bob and Weave", "Brainpower", "Brainteaser",
    "Brutal Clarity", "Brute Wits", "Burning Dance", "Cakewalk",
    "Destructive Instinct", "Devastation", "Dizzying Power", "Easy Target",
    "Factory Knowledge", "Furious Brawn", "Good Form", "Haymaker", "Hide and Sync",
    "Hunter’s Instinct", "Inertia", "Insult to Injury", "Journey from Pallet",
    "New Teacher’s Quick Wit", "Overpower", "Pecking Order", "Power Loving",
    "Power Play", "Power Posture", "Ramming Speed", "Relentless", "Rising Tide",
    "Rose’s Results", "Royal Fortune", "Smart Cookie", "Smarty-Pants",
    "Sync Power Flux", "Team Moves ↑ as Stats ↑", "The Will to Protect",
    "Tough Cookie", "Towering Force", "Wide Open",
}

# Map each name to its description from sync_pairs.json (look in passives, subPassives, cells)
desc_map = defaultdict(set)
for p in pairs:
    for pas in p.get("passives", []) + p.get("teraPassives", []):
        if pas.get("name") in REMAINING:
            desc_map[pas["name"]].add(pas.get("description", "")[:240])
    for c in p.get("cells", []):
        for sp in c.get("subPassives", []):
            if sp.get("name") in REMAINING:
                desc_map[sp["name"]].add(sp.get("description", "")[:240])
    for v in p.get("variations", []):
        for pas in v.get("passives", []):
            if pas.get("name") in REMAINING:
                desc_map[pas["name"]].add(pas.get("description", "")[:240])

# Also from damage_passives sub_passives
for e in dp:
    if e.get("type") == "composite":
        for sp in e.get("sub_passives", []):
            if sp.get("name") in REMAINING:
                # composites don't store descriptions
                pass

for nm in sorted(REMAINING):
    print(f"\n## {nm}")
    descs = desc_map.get(nm, set())
    if not descs:
        print("  (sin descripción encontrada en sync_pairs.json — posiblemente solo en composites)")
        continue
    for d in list(descs)[:2]:
        print(f"  > {d}")
