"""Apply 159 auto-fixes for grid cells with title matching a master entry but no ref.

Buckets:
- A_AUTO_GENERIC (17): title = "<PassiveName>", master generic exists
    add ref {name, source:'grid_skill', cellNumber}
- B_AUTO_MOVE_SPECIFIC (141): title = "<MoveName>: <PassiveName>", master move-specific exists
    add ref {name, moveName, source:'grid_skill', cellNumber}
- C_AUTO_GENERIC_FOR_MOVE (1): title = "<MoveName>: <PassiveName>", only generic master exists
    add ref {name, moveName, source:'grid_skill', cellNumber}

Idempotent: skips if ref already exists for that (cellNumber, name).
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
sp = json.load(open(SP, encoding="utf-8"))
dp = json.load(open(ASSETS / "damage_passives.json", encoding="utf-8"))

dp_by_key = {(e.get('name',''), e.get('move_name','')): e for e in dp}
sub_names = set()
for e in dp:
    for s in e.get('sub_passives', []):
        sub_names.add(s.get('name', ''))


def split_title(title):
    if ':' in title:
        a, b = title.split(':', 1)
        return a.strip(), b.strip()
    return None, title.strip()


added_A = []  # generic
added_B = []  # move-specific
added_C = []  # generic-for-move
skipped = 0

for p in sp:
    pname = p.get('displayName', '')
    refs = p.setdefault('damagePassives', [])
    existing = {(r.get('cellNumber'), r.get('name','')) for r in refs}
    for c in p.get('cells', []):
        if c.get('subPassives') or c.get('statBonus') or c.get('powerBonus'):
            continue
        cn = c['cellNumber']
        # Skip if any ref already mentions this cell
        if any(r.get('cellNumber') == cn for r in refs):
            continue
        title = c.get('title', '')
        kind = c.get('colorKind', '')
        if not title or kind.startswith('Rainbow') or kind.startswith('Blue') or kind.startswith('Green'):
            continue
        desc = c.get('description', '') or ''
        # boost filter
        t = (title + ' ' + desc).lower()
        boost_kw = ('powers up', 'power up', '↑', '↓', 'boost', 'raise', 'rebuff',
                    'never miss', 'always hits', 'lands every', 'ignores',
                    'piercing', 'critical hit', 'crit', 'team', 'zone', 'terrain',
                    'weather', 'rush', 'spirit', 'pride', 'flag bearer', 'circle', 'myth')
        if not any(k in t for k in boost_kw):
            continue

        move, passive = split_title(title)

        # B) move-specific master
        if move and (passive, move) in dp_by_key:
            ref = {'name': passive, 'moveName': move, 'source': 'grid_skill', 'cellNumber': cn}
            if (cn, passive) in existing:
                skipped += 1
                continue
            refs.append(ref)
            existing.add((cn, passive))
            added_B.append((pname, cn, title))
            continue

        # A or C) generic master
        if (passive, '') in dp_by_key:
            ref = {'name': passive, 'source': 'grid_skill', 'cellNumber': cn}
            if move:
                ref['moveName'] = move
            if (cn, passive) in existing:
                skipped += 1
                continue
            refs.append(ref)
            existing.add((cn, passive))
            if move:
                added_C.append((pname, cn, title))
            else:
                added_A.append((pname, cn, title))
            continue

SP.write_text(json.dumps(sp, ensure_ascii=False, indent=2), encoding="utf-8")

print(f"## Refs añadidos por bucket")
print(f"  - A (generic match): {len(added_A)}")
print(f"  - B (move-specific match): {len(added_B)}")
print(f"  - C (generic match, move-scoped): {len(added_C)}")
print(f"  - skipped (already had ref): {skipped}")
print(f"\nsync_pairs.json reescrito ({SP.stat().st_size:,} bytes)")

print(f"\n## Detalle A — generic match\n")
for pn, cn, t in added_A:
    pname = pn.encode('ascii','replace').decode('ascii')
    title = t.encode('ascii','replace').decode('ascii')
    print(f"  - {pname} cell#{cn} `{title}`")

print(f"\n## Detalle B — move-specific match (primeros 30)\n")
for pn, cn, t in added_B[:30]:
    pname = pn.encode('ascii','replace').decode('ascii')
    title = t.encode('ascii','replace').decode('ascii')
    print(f"  - {pname} cell#{cn} `{title}`")
if len(added_B) > 30:
    print(f"  ... y {len(added_B)-30} más")

print(f"\n## Detalle C — generic match scoped to move\n")
for pn, cn, t in added_C:
    pname = pn.encode('ascii','replace').decode('ascii')
    title = t.encode('ascii','replace').decode('ascii')
    print(f"  - {pname} cell#{cn} `{title}`")
