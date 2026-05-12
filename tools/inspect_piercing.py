"""Look up Piercing Blows / Piercing Gaze / similar effects in the data."""
import io
import json
import sys
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets" / "data"

with (ASSETS / "sync_pairs.json").open(encoding="utf-8") as fh:
    pairs = json.load(fh)
with (ASSETS / "damage_passives.json").open(encoding="utf-8") as fh:
    dp = json.load(fh)

print("=== damage_passives.json entries matching 'Piercing' ===")
for e in dp:
    if "piercing" in e.get("name", "").lower():
        print(f"\nMASTER: {e.get('name')}")
        print(f"  type={e.get('type')} applies_to={e.get('applies_to')} affects={e.get('affects')}")
        print(f"  mechanism={e.get('mechanism')} value={e.get('value')}")
        print(f"  stat={e.get('stat')} stat_target={e.get('stat_target')}")
        if e.get("sub_passives"):
            for sp in e["sub_passives"]:
                print(f"  sub: {sp.get('name')} mech={sp.get('mechanism')} value={sp.get('value', sp.get('sub_value'))}")

print("\n=== Looking at N & Zekrom passives ===")
for p in pairs:
    if p.get("displayName") == "N & Zekrom":
        for pas in p.get("passives", []):
            print(f"\n{pas.get('name')}")
            print(f"  {pas.get('description')[:300]}")
        print("\nteraPassives:")
        for pas in p.get("teraPassives", []):
            print(f"  {pas.get('name')}: {pas.get('description')[:200]}")
        print("\ndamagePassives:")
        for r in p.get("damagePassives", []):
            print(f"  {r}")
        break

print("\n=== Pairs with passive named exactly 'Piercing Blows' ===")
for p in pairs:
    for pas in p.get("passives", []) + p.get("teraPassives", []):
        if pas.get("name", "").lower() == "piercing blows":
            print(f"- {p['displayName']} → {pas.get('description')[:200]}")
    for v in p.get("variations", []):
        for pas in v.get("passives", []):
            if pas.get("name", "").lower() == "piercing blows":
                print(f"- {p['displayName']} (variation {v.get('formName')}) → {pas.get('description')[:200]}")

print("\n=== Pairs with passive named exactly 'Piercing Gaze' ===")
for p in pairs:
    for pas in p.get("passives", []) + p.get("teraPassives", []):
        if pas.get("name", "").lower() == "piercing gaze":
            print(f"- {p['displayName']} → {pas.get('description')[:200]}")
    for v in p.get("variations", []):
        for pas in v.get("passives", []):
            if pas.get("name", "").lower() == "piercing gaze":
                print(f"- {p['displayName']} (variation {v.get('formName')}) → {pas.get('description')[:200]}")
