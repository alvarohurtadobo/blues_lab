"""Re-audit Piercing Blows correctly.

True Piercing Blows definition (the one that matters for calc):
- "Ignores the target's passive skills that would reduce the damage of attacks"
- "Ignores the target's passive skills that would protect the target against a critical hit"
- "Ignores the target's Enduring effect"

Piercing GAZE = "Moves never miss" — irrelevant to damage calculator.
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

with (ASSETS / "sync_pairs.json").open(encoding="utf-8") as fh:
    pairs = json.load(fh)
with (ASSETS / "damage_passives.json").open(encoding="utf-8") as fh:
    dp = json.load(fh)

PIERCING_BLOWS_KEYS = (
    "ignores the target's passive skills that would reduce the damage",
    "ignores the target’s passive skills that would reduce the damage",
    "ignores the target's passive skills that would protect the target against a critical",
    "ignores the target’s passive skills that would protect the target against a critical",
    "ignores the target's enduring effect",
    "ignores the target’s enduring effect",
)


def is_piercing_blows_concept(desc):
    if not desc:
        return False
    d = desc.lower()
    return any(k in d for k in PIERCING_BLOWS_KEYS)


print("# Piercing Blows — re-audit\n")

# 1. Is there a master entry for Piercing Blows?
master_exists = any(e.get("name", "").lower() == "piercing blows" for e in dp)
print(f"Master entry 'Piercing Blows' present in damage_passives.json: **{master_exists}**\n")

# 2. Pairs with explicit Piercing Blows passive (innate, tera, or variation)
explicit_pb = []
for p in pairs:
    nm = p["displayName"]
    for pas in p.get("passives", []):
        if pas.get("name", "").lower() == "piercing blows":
            explicit_pb.append((nm, "innate"))
    for pas in p.get("teraPassives", []):
        if pas.get("name", "").lower() == "piercing blows":
            explicit_pb.append((nm, "tera"))
    for v in p.get("variations", []):
        for pas in v.get("passives", []):
            if pas.get("name", "").lower() == "piercing blows":
                explicit_pb.append((nm, f"variation {v.get('formName')}"))

print(f"## Pairs con pasiva literal 'Piercing Blows' ({len(explicit_pb)})\n")
for nm, loc in explicit_pb:
    print(f"- **{nm}** ({loc})")

# 3. Pairs whose passive description contains Piercing Blows wording
# but the passive is named differently
print("\n## Pasivas con efecto de Piercing Blows pero **nombre distinto**\n")
disguised = []
for p in pairs:
    nm = p["displayName"]
    for pas in p.get("passives", []):
        if pas.get("name", "").lower() == "piercing blows":
            continue
        if is_piercing_blows_concept(pas.get("description", "")):
            disguised.append((nm, "innate", pas.get("name"), pas.get("description")[:240]))
    for pas in p.get("teraPassives", []):
        if pas.get("name", "").lower() == "piercing blows":
            continue
        if is_piercing_blows_concept(pas.get("description", "")):
            disguised.append((nm, "tera", pas.get("name"), pas.get("description")[:240]))
    for v in p.get("variations", []):
        for pas in v.get("passives", []):
            if pas.get("name", "").lower() == "piercing blows":
                continue
            if is_piercing_blows_concept(pas.get("description", "")):
                disguised.append((nm, f"var {v.get('formName')}", pas.get("name"), pas.get("description")[:240]))
    for c in p.get("cells", []):
        for sp in c.get("subPassives", []):
            if sp.get("name", "").lower() == "piercing blows":
                continue
            if is_piercing_blows_concept(sp.get("description", "")):
                disguised.append((nm, f"cell#{c.get('cellNumber')}", sp.get("name"), sp.get("description")[:240]))

print(f"Total disfrazadas: {len(disguised)}\n")
for nm, loc, pn, d in disguised:
    print(f"- **{nm}** ({loc}) `{pn}`")
    print(f"  > {d}\n")

# 4. Pairs that DO have Piercing Blows passive — are any referenced in damagePassives?
print("\n## ¿Los pairs con Piercing Blows lo referencian en damagePassives?\n")
for nm, loc in explicit_pb:
    p = next(pp for pp in pairs if pp["displayName"] == nm)
    refs = [r.get("name") for r in p.get("damagePassives", [])]
    has_ref = "Piercing Blows" in refs
    print(f"- {nm} ({loc}) → damagePassives ref={has_ref} | refs presentes: {refs}")

# 5. Drop the FALSE positives I flagged before
print("\n## Falsos positivos que reporté antes (en realidad son Piercing GAZE — irrelevante)\n")
print("- Red (Champion) & Articuno → `Journey from Pallet` — efecto: moves never miss (Piercing Gaze)")
print("- Gladion (Academy) & Porygon-Z → `Attack Program` — efecto: Hyper Beam never misses")
print("- Ash & Pikachu → `Ash's Passion` — efecto: Thunder never misses")
print("- Rose & Copperajah → `Rose's Results` — efecto: moves never miss")
print("- Volo & Togepi → `Piqued Curiosity` — efecto: moves never miss + tipo change")
print("- Sygna Suit Kieran & Furret → `Paldea Willpower` — descripción larga; revisar puntualmente")
