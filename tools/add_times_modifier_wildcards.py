"""Add Option A wildcard entries to move_scaling.json for Times Modifier moves
and per-pair variants found in Pomatools.

Wildcard (syncPair='*'): generic moves shared by many pairs.
Per-pair: variant moves named with the pair's flavor (e.g. 'Tried-and-True Hex').

Multiplier convention: stepPer1000 = additive boost ×1000.
   step=1000 → +1.0 → ×2.0
   step=500  → +0.5 → ×1.5

Idempotent.
"""
import io, json, re, sys
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets" / "data"
POMA = ROOT / "legacy" / "Pomatools"

# Pomatools data
txt = open(POMA / "201.f24e83a2e7226478.js", encoding='utf-8').read()
m = re.search(r"JSON\.parse\(['\"](\{.+?\})['\"]\)", txt)
poma_moves = json.loads(m.group(1).encode().decode('unicode_escape'))
txt2 = open(POMA / "502.9c377325220e1efb.js", encoding='utf-8').read()
name_pat = re.compile(r'"(\d+)":\s*\{[^{}]*?"NAME":"([^"]+)"[^{}]*?"DESC":"([^"]+)"')
poma_names = {k: name for k, name, _ in name_pat.findall(txt2)}

# Build name → powerup mapping (first entry only)
poma_powerup_by_name = {}
for k, v in poma_moves.items():
    pu = v.get('powerup')
    if pu:
        name = poma_names.get(k)
        if name and name not in poma_powerup_by_name:
            poma_powerup_by_name[name] = pu[0]

# Map Pomatools condition codes → our stat values
def translate_to_conditional(pu):
    """Returns (stat, step) for a Times Modifier powerup, or None."""
    if not pu or len(pu) < 2:
        return None
    targ = pu[0]
    code = pu[1]
    mech = pu[2] if len(pu) > 2 else ''

    # Status condition codes
    if code in ('SCPM_063', 'SC'):
        # Any status condition
        if targ == 'TARG_004':
            return ('target_status_any', 1000)
        elif targ == 'TARG_001':
            return ('user_status_any', 1000)
    if code == 'SCPM_003':
        # Poisoned/badly poisoned
        if targ == 'TARG_004':
            return ('target_status_poison', 1000)
    if code == 'STAT_001' and mech == 'HP_HALF':
        # Target HP at half or below → ×2 (Brine)
        if targ == 'TARG_004':
            return ('target_hp_half', 1000)
    # Don't handle SYNC, REVENGE, COUNTER yet (need state flags)
    return None


ms = json.load(open(ASSETS / "move_scaling.json", encoding='utf-8'))
existing_keys = {(e['syncPair'], e['moveName']) for e in ms}

# Find all moves in sync_pairs.json and check if Pomatools encodes them as Times Modifier
sp = json.load(open(ASSETS / "sync_pairs.json", encoding='utf-8'))
all_move_names = set()
for p in sp:
    for mv in p.get('moves', []):
        all_move_names.add(mv.get('name', ''))
    if isinstance(p.get('teraMove'), dict):
        all_move_names.add(p['teraMove'].get('name', ''))
    for v in p.get('variations', []):
        for mv in v.get('moves', []):
            all_move_names.add(mv.get('name', ''))

# Identify all candidates: move-name → (stat, step) if Pomatools has Times Modifier
candidates = {}
for mn in all_move_names:
    pu = poma_powerup_by_name.get(mn)
    if not pu:
        continue
    t = translate_to_conditional(pu)
    if t:
        candidates[mn] = t

print(f"## Times Modifier moves identified: {len(candidates)}")
added_wildcard = []
added_pair = []

# For each candidate, decide wildcard vs per-pair.
# Heuristic: if Pomatools name == standard short name (e.g. 'Hex'), use wildcard.
# If pair-specific flavor name (e.g. 'Rising Flames Hex'), use per-pair entry.

# Standard short names of common Times Modifier moves
STANDARD_NAMES = {'Hex', 'Facade', 'Venoshock', 'Brine', 'Avalanche', 'Mirror Coat',
                  'Metal Burst', 'Counter', 'Stomping Tantrum', 'Behemoth Blade',
                  'Behemoth Bash'}

for mn, (stat, step) in candidates.items():
    if mn in STANDARD_NAMES:
        key = ('*', mn)
        if key in existing_keys:
            continue
        entry = {
            'syncPair': '*',
            'moveName': mn,
            'stat': stat,
            'who': 'target' if stat.startswith('target_') else 'user',
            'direction': 'raised' if 'raise' in stat else 'lowered',
            'stepPer1000': step,
            'capPer1000': 1000 + step,
        }
        ms.append(entry)
        existing_keys.add(key)
        added_wildcard.append(entry)
    else:
        # Pair-specific named variant — find which pair uses this move
        for p in sp:
            pname = p.get('displayName','')
            pair_moves = [mv.get('name','') for mv in p.get('moves', [])]
            if isinstance(p.get('teraMove'), dict):
                pair_moves.append(p['teraMove'].get('name',''))
            for v in p.get('variations', []):
                pair_moves.extend(mv.get('name','') for mv in v.get('moves', []))
            if mn not in pair_moves:
                continue
            key = (pname, mn)
            if key in existing_keys:
                continue
            entry = {
                'syncPair': pname,
                'moveName': mn,
                'stat': stat,
                'who': 'target' if stat.startswith('target_') else 'user',
                'direction': 'raised' if 'raise' in stat else 'lowered',
                'stepPer1000': step,
                'capPer1000': 1000 + step,
            }
            ms.append(entry)
            existing_keys.add(key)
            added_pair.append((pname, entry))


(ASSETS / "move_scaling.json").write_text(json.dumps(ms, ensure_ascii=False, indent=4) + "\n", encoding="utf-8")

print(f"\n## Wildcard entries added: {len(added_wildcard)}")
for e in added_wildcard:
    print(f"  + * | `{e['moveName']}` stat={e['stat']} step={e['stepPer1000']}")

print(f"\n## Per-pair entries added: {len(added_pair)}")
for pn, e in added_pair[:30]:
    pp = pn.encode('ascii','replace').decode('ascii')
    mm = e['moveName'].encode('ascii','replace').decode('ascii')
    print(f"  + {pp} | `{mm}` stat={e['stat']}")
if len(added_pair) > 30:
    print(f"  ... y {len(added_pair)-30} más")

print(f"\nTotal entries: {len(ms)}")
