"""Investigate how Super Awakening passives are represented in the data."""
import io
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets" / "data"

with (ASSETS / "sync_pairs.json").open(encoding="utf-8") as fh:
    sp = json.load(fh)

# Pick a few known SA pairs and dump everything passive-related
TARGETS = [
    "Lance & Dragonite",
    "Cynthia & Garchomp",
    "Steven & Metagross",
    "N & Zekrom",
    "Sygna Suit Red & Charizard",
    "Gloria (Alt. 2) & Cinderace",
    "Sygna Suit N & Black Kyurem",
    "Sygna Suit Steven & Deoxys Normal Forme",
    "Bede & Hatterene",
    "Iono & Bellibolt",
]

for tgt in TARGETS:
    p = next((x for x in sp if x.get("displayName") == tgt), None)
    if not p:
        print(f"!! {tgt} not found")
        continue
    print(f"\n=== {tgt} (hasSA={p.get('hasSuperAwakening')}) ===")
    print("passives:")
    for pas in p.get("passives", []):
        nm = pas.get("name", "")
        desc = pas.get("description", "")[:200]
        locked = pas.get("locked", False)
        print(f"  [{'L' if locked else ' '}] {nm}: {desc}")
    print("damagePassives:")
    for r in p.get("damagePassives", []):
        print(f"  - {r}")
    # Look for cells that might encode SA (cell #51 / #52 in Sync Grid Expanded)
    print("cells of interest (high cellNumber or 'Super Awakening' / SA in title):")
    for c in p.get("cells", []):
        title = c.get("title", "")
        cn = c.get("cellNumber", 0)
        if cn >= 50 or "awak" in title.lower() or "SA " in title:
            print(f"  cell#{cn}: '{title}' kind={c.get('colorKind','')}")
            for sub in c.get("subPassives", []):
                print(f"      sub: {sub.get('name','')}: {sub.get('description','')[:160]}")
