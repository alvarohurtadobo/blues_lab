"""Apply Piercing Blows fix.

1) Add 'Piercing Blows' master entry to damage_passives.json (modifier, affects=PIERCING_BLOWS).
2) Add `{"name": "Piercing Blows", "source": "passive"}` to sync_pairs.json damagePassives for:
   - 10 pairs with literal 'Piercing Blows' innate/tera/variation passive
   - 3 disguised pairs whose passive contains the wording but is named differently

Idempotent: re-running won't duplicate entries.
"""
import io
import json
import sys
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets" / "data"

DP_PATH = ASSETS / "damage_passives.json"
SP_PATH = ASSETS / "sync_pairs.json"

PIERCING_BLOWS_MASTER = {
    "name": "Piercing Blows",
    "type": "modifier",
    "applies_to": "pokemon_moves",
    "affects": "PIERCING_BLOWS",
    "mechanism": "",
    "value": 1,
    "stat": "",
    "stat_target": "",
    "conditions": [],
    "move_name": "",
    "sub_passives": []
}

# 13 target pairs: 10 explicit + 3 disguised
TARGET_PAIRS = [
    "Erika (Palentine's 2025) & Lurantis",
    "Bianca (Champion) & Virizion",
    "Gloria (Alt. 2) & Cinderace",
    "N & Zekrom",
    "N (Anniversary 2021) & Reshiram",
    "Sygna Suit N & Black Kyurem",
    "Sygna Suit Piers & Toxtricity Low Key Form",
    "Leon (Alt.) & Dragapult",
    "Victor & Rillaboom",
    "Petrel & Weezing",
    # disguised
    "Hilbert (Champion) & White Kyurem ★",
    "Adaman (Palentine's 2026) & Sylveon ★",
    "Larry & Dudunsparce",
]

# === 1. damage_passives.json ===
with DP_PATH.open(encoding="utf-8") as fh:
    dp = json.load(fh)

already = any(e.get("name") == "Piercing Blows" for e in dp)
if already:
    print("[skip] Piercing Blows ya existe en damage_passives.json")
else:
    # Insert keeping rough alphabetical-ish order: place after Piercing Gaze if present
    idx = None
    for i, e in enumerate(dp):
        if e.get("name") == "Piercing Gaze":
            idx = i + 1
            break
    if idx is None:
        dp.append(PIERCING_BLOWS_MASTER)
    else:
        dp.insert(idx, PIERCING_BLOWS_MASTER)
    DP_PATH.write_text(json.dumps(dp, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"[ok] Piercing Blows insertado en damage_passives.json (entries totales: {len(dp)})")

# === 2. sync_pairs.json ===
with SP_PATH.open(encoding="utf-8") as fh:
    pairs = json.load(fh)

names_lower = {n.lower() for n in TARGET_PAIRS}
hits = []
misses = []
for p in pairs:
    nm = p.get("displayName", "")
    if nm.lower() not in names_lower:
        continue
    refs = p.setdefault("damagePassives", [])
    if any(r.get("name") == "Piercing Blows" for r in refs):
        print(f"[skip] {nm} ya tiene ref a Piercing Blows")
    else:
        refs.append({"name": "Piercing Blows", "source": "passive"})
        hits.append(nm)
        print(f"[ok] añadido ref en {nm}")

# Detect any target name not found
found_lower = {p.get("displayName", "").lower() for p in pairs}
for n in TARGET_PAIRS:
    if n.lower() not in found_lower:
        misses.append(n)

if misses:
    print("\n⚠ Pairs no encontrados:")
    for n in misses:
        print(f"  - {n}")

# Write back. Use compact form (no indent) to keep file size reasonable,
# but the existing format uses minified JSON. Let's inspect first.
# Probe the existing format: if first 1KB starts with `[{"...":...,"...":...}` no indent → minified
sample_old = SP_PATH.read_text(encoding="utf-8")[:200]
indent = None if ("\n " not in sample_old[:200] and "\n\t" not in sample_old[:200]) else 2

SP_PATH.write_text(json.dumps(pairs, ensure_ascii=False, indent=indent), encoding="utf-8")
print(f"\n[ok] sync_pairs.json reescrito ({SP_PATH.stat().st_size:,} bytes, indent={indent})")
print(f"Hits: {len(hits)} / {len(TARGET_PAIRS)}")
