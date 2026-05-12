"""Auto-fix damage_passives.json entries whose name ends in a digit
and whose mechanism requires a value but value is 0.

For duplicates (same name appearing N times), all occurrences are updated
so the file stays internally consistent.

Idempotent.
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
DP = ASSETS / "damage_passives.json"

NEEDS_VAL = {
    "flat_boost", "user_stat_raised", "target_stat_lowered",
    "stat_is_raised", "stat_is_lowered", "stat_not_raised",
    "gauge_cost_boost", "PMUN", "SMUN", "stat_raised_30pct",
}

with DP.open(encoding="utf-8") as fh:
    dp = json.load(fh)

fixed_log = []
fixed_subs = []
unfix_names = set()

def trailing_digit(name):
    m = re.search(r"(\d+)$", name)
    return int(m.group(1)) if m else None

for i, e in enumerate(dp):
    if e.get("type") == "composite":
        for j, sp in enumerate(e.get("sub_passives", [])):
            mech = sp.get("mechanism", "")
            val = sp.get("value", 0) or sp.get("sub_value", 0)
            if mech in NEEDS_VAL and val == 0:
                nm = sp.get("name", "") or sp.get("sub_name", "")
                d = trailing_digit(nm)
                if d is not None:
                    sp["value"] = d
                    fixed_subs.append((f"{e['name']}→{nm}", mech, d))
                else:
                    unfix_names.add(nm)
        continue
    mech = e.get("mechanism", "")
    val = e.get("value", 0)
    if mech in NEEDS_VAL and val == 0:
        nm = e.get("name", "")
        d = trailing_digit(nm)
        if d is not None:
            e["value"] = d
            fixed_log.append((nm, mech, d))
        else:
            unfix_names.add(nm)

DP.write_text(json.dumps(dp, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

print(f"## Aplicados (top-level): {len(fixed_log)}")
# Group by name + show count
group = defaultdict(int)
for nm, mech, d in fixed_log:
    group[(nm, mech, d)] += 1
for (nm, mech, d), c in sorted(group.items()):
    suffix = f" × {c}" if c > 1 else ""
    print(f"  - `{nm}` mech={mech} → value={d}{suffix}")

print(f"\n## Aplicados (sub-passives en composites): {len(fixed_subs)}")
gsub = defaultdict(int)
for nm, mech, d in fixed_subs:
    gsub[(nm, mech, d)] += 1
for (nm, mech, d), c in sorted(gsub.items()):
    suffix = f" × {c}" if c > 1 else ""
    print(f"  - `{nm}` mech={mech} → value={d}{suffix}")

print(f"\n## Restantes sin auto-fix (necesitan revisión manual): {len(unfix_names)}")
for nm in sorted(unfix_names):
    print(f"  - `{nm}`")

print(f"\ndamage_passives.json reescrito ({DP.stat().st_size:,} bytes)")
