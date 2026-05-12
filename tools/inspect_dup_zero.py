"""Identify which value=0 entries can be safely auto-fixed from name digits,
and which are unnamed or duplicates needing review.
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

NEEDS_VAL = {
    "flat_boost", "user_stat_raised", "target_stat_lowered",
    "stat_is_raised", "stat_is_lowered", "stat_not_raised",
    "gauge_cost_boost", "PMUN", "SMUN", "stat_raised_30pct",
}

# Find ALL value=0 entries needing a value, with their index in dp
candidates = []  # (idx, name, mech, has_digit_suffix, suggested_value)
for i, e in enumerate(dp):
    if e.get("type") == "composite":
        for j, sp in enumerate(e.get("sub_passives", [])):
            mech = sp.get("mechanism", "")
            val = sp.get("value", 0) or sp.get("sub_value", 0)
            if mech in NEEDS_VAL and val == 0:
                nm = sp.get("name", "")
                m = re.search(r"(\d+)$", nm)
                digit = int(m.group(1)) if m else None
                candidates.append((f"{i}.{j}", f"{e['name']}→{nm}", mech, digit))
        continue
    mech = e.get("mechanism", "")
    val = e.get("value", 0)
    if mech in NEEDS_VAL and val == 0:
        nm = e.get("name", "")
        m = re.search(r"(\d+)$", nm)
        digit = int(m.group(1)) if m else None
        candidates.append((str(i), nm, mech, digit))

auto = [c for c in candidates if c[3] is not None]
manual = [c for c in candidates if c[3] is None]
print(f"Total value=0 a fixar: {len(candidates)}")
print(f"  Auto-fix (trailing digit): {len(auto)}")
print(f"  Necesitan revisión manual: {len(manual)}\n")

print("## Auto-fixable\n")
for idx, nm, mech, d in sorted(auto, key=lambda x: x[1]):
    print(f"- `{nm}` mech={mech} → value={d}")

print("\n## Manual (sin dígito)\n")
# Group by name to spot duplicates
by_name = defaultdict(list)
for idx, nm, mech, d in manual:
    by_name[nm].append((idx, mech))
for nm in sorted(by_name):
    occs = by_name[nm]
    if len(occs) > 1:
        print(f"- `{nm}` × {len(occs)} entradas (probable duplicado) {occs}")
    else:
        print(f"- `{nm}` mech={occs[0][1]}")

# Check for true duplicate entries (same name + same mechanism)
print("\n## Duplicados por (name, mechanism, applies_to) ya existentes en master:\n")
key_count = defaultdict(list)
for i, e in enumerate(dp):
    if e.get("type") == "composite":
        continue
    key = (e.get("name", ""), e.get("mechanism", ""), e.get("applies_to", ""))
    key_count[key].append(i)
dups = {k: v for k, v in key_count.items() if len(v) > 1}
for (n, m, a), idxs in sorted(dups.items()):
    print(f"- `{n}` mech={m} applies_to={a} × {len(idxs)} → indexes {idxs}")
