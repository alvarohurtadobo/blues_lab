"""Re-tag the SA passive in each pair's damagePassives.

Convention (from home_screen.dart:802-808):
  pair.passives[0] is the Super Awakening passive when hasSuperAwakening=true.

For each of the 119 SA pairs:
  - get passives[0].name (call it `sa_name`)
  - find the ref in damagePassives where name == sa_name
  - if found and source=='passive' → switch source to 'super_awakening'
  - if found and source already 'super_awakening' → skip (idempotent)
  - if not found → log (no damage-relevant SA passive to gate)

Idempotent.
"""
import io
import json
import sys
from collections import defaultdict
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets" / "data"
SP = ASSETS / "sync_pairs.json"

with SP.open(encoding="utf-8") as fh:
    sp = json.load(fh)

updated = []          # (pair_name, sa_name)
already_tagged = []   # (pair_name, sa_name)
no_damage_ref = []    # (pair_name, sa_name)
no_passives = []      # (pair_name,)
unexpected = []       # (pair_name, sa_name, current_source)

for p in sp:
    if not p.get("hasSuperAwakening"):
        continue
    pname = p.get("displayName", "")
    passives = p.get("passives", [])
    if not passives:
        no_passives.append(pname)
        continue
    sa_name = passives[0].get("name", "")
    refs = p.get("damagePassives", [])
    ref = next((r for r in refs if r.get("name", "") == sa_name), None)
    if ref is None:
        no_damage_ref.append((pname, sa_name))
        continue
    src = ref.get("source", "")
    if src == "super_awakening":
        already_tagged.append((pname, sa_name))
        continue
    if src != "passive":
        unexpected.append((pname, sa_name, src))
        continue
    ref["source"] = "super_awakening"
    updated.append((pname, sa_name))

SP.write_text(json.dumps(sp, ensure_ascii=False, indent=2), encoding="utf-8")

print(f"## SA passives re-tagged: {len(updated)}")
for pname, name in updated[:200]:
    sn = name.encode('ascii', 'replace').decode('ascii')
    pn = pname.encode('ascii', 'replace').decode('ascii')
    print(f"  - {pn} → '{sn}'")

print(f"\n## Ya tagged como super_awakening (idempotente): {len(already_tagged)}")
for pname, name in already_tagged:
    print(f"  - {pname.encode('ascii', 'replace').decode('ascii')}")

print(f"\n## Pares SA cuya passives[0] NO aparece en damagePassives (no hay boost que gatear): {len(no_damage_ref)}")
for pname, name in no_damage_ref:
    sn = name.encode('ascii', 'replace').decode('ascii')
    pn = pname.encode('ascii', 'replace').decode('ascii')
    print(f"  - {pn} → SA passive '{sn}'")

if no_passives:
    print(f"\n## Pares SA sin passives[]: {len(no_passives)}")
    for n in no_passives:
        print(f"  - {n}")

if unexpected:
    print(f"\n## Inesperado (source no era 'passive' ni 'super_awakening'): {len(unexpected)}")
    for pname, name, src in unexpected:
        print(f"  - {pname} → '{name}' source='{src}'")

print(f"\nsync_pairs.json reescrito ({SP.stat().st_size:,} bytes)")
