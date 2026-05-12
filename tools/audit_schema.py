"""Quick schema inspection: explore one pair JSON to understand structure."""
import io
import json
import sys
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets" / "data"

with (ASSETS / "sync_pairs.json").open(encoding="utf-8") as fh:
    pairs = json.load(fh)

print(f"Total pairs: {len(pairs)}")
print()

# Collect top-level keys
key_counts = {}
for p in pairs:
    for k in p.keys():
        key_counts[k] = key_counts.get(k, 0) + 1

print("Top-level field frequency:")
for k, v in sorted(key_counts.items(), key=lambda x: -x[1]):
    print(f"  {k}: {v}")

# Show one fully-featured sample - with super awakening + tera + variations
for p in pairs:
    if p.get("hasSuperAwakening") and p.get("hasTera") and p.get("variations"):
        print(f"\nSample (rich): {p.get('displayName')}")
        print(json.dumps({k: v for k, v in p.items() if k not in ("cells", "moves", "passives", "teraPassives", "teraMoves")}, indent=2)[:1500])
        break

# Sample passive entry
for p in pairs[:5]:
    pas = p.get("passives", [])
    if pas:
        print(f"\nSample passive from {p['displayName']}:")
        print(json.dumps(pas[0], indent=2)[:600])
        break

# Sample damage passive ref
for p in pairs:
    dp = p.get("damagePassives", [])
    if dp:
        print(f"\nSample damagePassives from {p['displayName']}:")
        print(json.dumps(dp, indent=2)[:800])
        break

# Sample cell with subPassives
for p in pairs:
    for c in p.get("cells", []):
        if c.get("subPassives"):
            print(f"\nSample cell w/ subPassives from {p['displayName']}:")
            print(json.dumps(c, indent=2)[:1000])
            break
    else:
        continue
    break

# Sample variation
for p in pairs:
    if p.get("variations"):
        print(f"\nSample variations from {p['displayName']}:")
        print(json.dumps(p["variations"][0], indent=2)[:1500])
        break
