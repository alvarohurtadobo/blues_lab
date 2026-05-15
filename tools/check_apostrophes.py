"""Find apostrophe-mismatch syncPair references across JSON files."""
import io, json, sys
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets" / "data"

sp = json.load(open(ASSETS / "sync_pairs.json", encoding="utf-8"))
mp = json.load(open(ASSETS / "master_passives.json", encoding="utf-8"))
ls = json.load(open(ASSETS / "lucky_skills.json", encoding="utf-8"))
ms = json.load(open(ASSETS / "move_scaling.json", encoding="utf-8"))

pair_names = {p.get('displayName','') for p in sp}

def report(label, broken):
    print(f"\n## {label}: {len(broken)} mismatches")
    for nm, n in broken:
        norm = n.replace(chr(0x2019), "'").replace("'", chr(0x2019))
        sp_match = norm if norm in pair_names else '<no match>'
        nn = nm.encode('ascii','replace').decode('ascii')
        ne = n.encode('ascii','replace').decode('ascii')
        sn = sp_match.encode('ascii','replace').decode('ascii')
        print(f"  ['{nn}']")
        print(f"    file: '{ne}'")
        print(f"    sync_pairs has: '{sn}'")

# Master passives
broken_mp = [('', e['syncPair']) for e in mp if e.get('syncPair','') and e['syncPair'] not in pair_names]
report('master_passives.json', broken_mp)

# Lucky skills
broken_ls = []
for ls_entry in ls:
    pairs = ls_entry.get('restricted_to_pairs') or []
    for pn in pairs:
        if pn not in pair_names:
            broken_ls.append((ls_entry.get('name',''), pn))
report('lucky_skills.json', broken_ls)

# Move scaling
broken_ms = []
for e in ms:
    if e.get('syncPair','') and e['syncPair'] not in pair_names:
        broken_ms.append((e.get('moveName',''), e['syncPair']))
report('move_scaling.json', broken_ms)

# Damage passives references (sync_pairs damagePassives sub-refs) — these reference passives, not pairs
# So skip

# Verify sync_pairs.json has consistent apostrophes for ALL pair names
weird_chars = set()
for p in sp:
    n = p.get('displayName','')
    for ch in n:
        if ord(ch) > 127 and ch not in "★♂♀":
            weird_chars.add(ch)
print(f"\n## Non-ASCII chars in sync_pairs displayNames (excluding ★♂♀): {weird_chars}")
