"""Add move_scaling.json entries for sync moves whose descriptions imply
Single-Stat or Multi-Stat sync modifiers (Tables 16-17 of the damage guide).

Single-Stat Sync (Table 16): Modifier = 1 + min(count × 0.167, 1.000) → stepPer1000=167, capPer1000=2000
Multi-Stat Sync (Table 17):  Modifier = 1 + min(count × 0.067, 1.200) → stepPer1000=67,  capPer1000=2200

Idempotent: skips if an entry for (syncPair, moveName) already exists.
"""
import io, json, re, sys
from collections import defaultdict
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets" / "data"

SP_PATH = ASSETS / "sync_pairs.json"
MS_PATH = ASSETS / "move_scaling.json"

sp = json.load(open(SP_PATH, encoding="utf-8"))
ms = json.load(open(MS_PATH, encoding="utf-8"))
covered = {(e['syncPair'], e['moveName']) for e in ms}

# Patterns
STAT_NAMES = {
    'attack': 'atk',
    'defense': 'def',
    'sp. atk': 'spa',
    'sp. attack': 'spa',
    'sp. def': 'spd',
    'sp. defense': 'spd',
    'speed': 'spe',
    'accuracy': 'acc',
    'evasiveness': 'eva',
}

# Single-stat user raised pattern: "The more (the )?user('|'s|s) <STAT> is raised"
SINGLE_USER_RAISED = re.compile(
    r"the more (?:the )?user[’'s]+ (attack|defense|sp\.\s*atk|sp\.\s*attack|sp\.\s*def|sp\.\s*defense|speed|accuracy|evasiveness)(?:\s+is)? raised",
    re.IGNORECASE
)
# Single-stat target lowered
SINGLE_TARGET_LOWERED = re.compile(
    r"the more (?:the )?target[’'s]+ (attack|defense|sp\.\s*atk|sp\.\s*attack|sp\.\s*def|sp\.\s*defense|speed|accuracy|evasiveness)(?:\s+is)? lowered",
    re.IGNORECASE
)
# Multi-stat target lowered
MULTI_TARGET_LOWERED = re.compile(
    r"the more (?:the )?target[’'s]+ stats (?:have been|are) lowered",
    re.IGNORECASE
)
# Multi-stat user raised
MULTI_USER_RAISED = re.compile(
    r"the more (?:the )?user[’'s]+ stats (?:have been|are) raised",
    re.IGNORECASE
)


def normalize_stat(s):
    s = s.lower().replace('  ', ' ').strip()
    s = s.replace('sp.atk', 'sp. atk').replace('sp.def', 'sp. def').replace('sp.attack','sp. attack').replace('sp.defense','sp. defense')
    return STAT_NAMES.get(s, s)


added = []
skipped = 0

for p in sp:
    pname = p.get('displayName','')
    all_moves = list(p.get('moves', [])) + list(p.get('teraMoves', []))
    if isinstance(p.get('teraMove'), dict):
        all_moves.append(p['teraMove'])
    for v in p.get('variations', []):
        all_moves.extend(v.get('moves', []))

    for mv in all_moves:
        if not mv.get('isSync'):
            continue
        mname = mv.get('name','')
        if not mname:
            continue
        key = (pname, mname)
        if key in covered:
            skipped += 1
            continue
        desc = mv.get('description','') or ''
        if not desc:
            continue

        entry = None
        m = SINGLE_USER_RAISED.search(desc)
        if m:
            stat = normalize_stat(m.group(1))
            entry = {
                'syncPair': pname, 'moveName': mname,
                'stat': stat, 'who': 'user', 'direction': 'raised',
                'stepPer1000': 167, 'capPer1000': 2000,
            }
        if entry is None:
            m = SINGLE_TARGET_LOWERED.search(desc)
            if m:
                stat = normalize_stat(m.group(1))
                entry = {
                    'syncPair': pname, 'moveName': mname,
                    'stat': stat, 'who': 'target', 'direction': 'lowered',
                    'stepPer1000': 167, 'capPer1000': 2000,
                }
        if entry is None:
            if MULTI_TARGET_LOWERED.search(desc):
                entry = {
                    'syncPair': pname, 'moveName': mname,
                    'stat': 'all_stats', 'who': 'target', 'direction': 'lowered',
                    'stepPer1000': 67, 'capPer1000': 2200,
                }
        if entry is None:
            if MULTI_USER_RAISED.search(desc):
                entry = {
                    'syncPair': pname, 'moveName': mname,
                    'stat': 'all_stats', 'who': 'user', 'direction': 'raised',
                    'stepPer1000': 67, 'capPer1000': 2200,
                }

        if entry is not None:
            ms.append(entry)
            covered.add(key)
            added.append(entry)

MS_PATH.write_text(json.dumps(ms, ensure_ascii=False, indent=4) + "\n", encoding="utf-8")

# Summarize
print(f"## Auto-fix aplicado: +{len(added)} entradas en move_scaling.json (skipped existentes: {skipped})\n")
by_dir = defaultdict(list)
for e in added:
    key = f"{e['who']}_{e['direction']}_{e['stat']}"
    by_dir[key].append(e)
for key in sorted(by_dir):
    items = by_dir[key]
    print(f"\n### {key} ({len(items)})")
    for e in items[:15]:
        pn = e['syncPair'].encode('ascii','replace').decode('ascii')
        mn = e['moveName'].encode('ascii','replace').decode('ascii')
        print(f"  - {pn} → `{mn}`  (step={e['stepPer1000']}/1000, cap={e['capPer1000']}/1000)")
    if len(items) > 15:
        print(f"  ... y {len(items)-15} más")
