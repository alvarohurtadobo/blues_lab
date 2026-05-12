"""Fix wrong stat-key names in damage_passives.json so the calc can read them.

- accuracy   -> acc
- evasiveness -> eva
- def+spd    -> spa_spd  (Added Insult, per description "Sp. Atk and Sp. Def")

Touches BOTH top-level entries and sub_passives in composites.
"""
import io
import json
import sys
from pathlib import Path
from collections import defaultdict

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets" / "data"
DP = ASSETS / "damage_passives.json"

# Global key renames (apply to all entries since these are inconsistent)
KEY_RENAMES = {
    "accuracy": "acc",
    "evasiveness": "eva",
}

# Per-name stat overrides (only when name matches)
NAME_STAT_OVERRIDES = {
    "Added Insult": "spa_spd",
}

with DP.open(encoding="utf-8") as fh:
    dp = json.load(fh)

renamed = defaultdict(int)
overridden = defaultdict(int)


def fix_entry(e):
    name = e.get("name", "")
    if name in NAME_STAT_OVERRIDES:
        want = NAME_STAT_OVERRIDES[name]
        if e.get("stat") != want:
            e["stat"] = want
            overridden[name] += 1
            return
    stat = e.get("stat", "")
    if stat in KEY_RENAMES:
        e["stat"] = KEY_RENAMES[stat]
        renamed[(name, stat, KEY_RENAMES[stat])] += 1


for entry in dp:
    if entry.get("type") == "composite":
        for sp in entry.get("sub_passives", []):
            fix_entry(sp)
        continue
    fix_entry(entry)

DP.write_text(json.dumps(dp, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

print(f"## Renombrados de stat-key: {sum(renamed.values())}")
for (name, old, new), n in sorted(renamed.items()):
    suffix = f" × {n}" if n > 1 else ""
    print(f"  - `{name}` stat: {old} -> {new}{suffix}")

print(f"\n## Overrides por nombre: {sum(overridden.values())}")
for name, n in sorted(overridden.items()):
    print(f"  - `{name}` × {n}")

print(f"\ndamage_passives.json reescrito ({DP.stat().st_size:,} bytes)")
