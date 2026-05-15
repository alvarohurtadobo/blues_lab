"""Audit innate move power-up effects.

Sources of innate move boosts:
1. move_scaling.json — handled by _moveScalingMultiplier (HP/stat/rebuff scaling, threshold tables)
2. Description keywords that imply a Times Modifier (e.g., "power doubled", "x2") — Table 18 in damageguide
3. Description keywords that imply a Single/Multi Stat modifier on sync moves (Tables 16-17)
4. Other modifiers (Counterattack, HP Reduction, Successive Uses, Stored Power, etc.)

For each move (including sync), classify and detect those not covered by move_scaling.json.
"""
import io, json, re, sys
from collections import defaultdict
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets" / "data"

sp = json.load(open(ASSETS / "sync_pairs.json", encoding="utf-8"))
ms = json.load(open(ASSETS / "move_scaling.json", encoding="utf-8"))

# Build set of (syncPair, moveName) already in move_scaling
covered = {(e['syncPair'], e['moveName']) for e in ms}

# Patterns we want to detect in move descriptions
PATTERNS = {
    # Times Modifiers (Table 18)
    'power_doubled': re.compile(r"power\s*is\s*doubled|doubled\s*if|power\s*increases\s*if", re.IGNORECASE),
    'times_2': re.compile(r"\b(twice|two times|2x|×2|x 2)\b", re.IGNORECASE),
    # Sync Move Single Stat Modifier (Table 16)
    'sync_stat_raised': re.compile(r"the more (?:the )?user[’']s (?:attack|defense|sp\.?\s?atk|sp\.?\s?def|speed|sp\.?\s?attack|sp\.?\s?defense)(?:[^.]*?)(?:is|are) raised", re.IGNORECASE),
    'sync_target_lowered': re.compile(r"the more (?:the )?target[’']s (?:attack|defense|sp\.?\s?atk|sp\.?\s?def|speed|sp\.?\s?attack|sp\.?\s?defense)(?:[^.]*?)(?:is|are) lowered", re.IGNORECASE),
    # Multi-stat
    'multi_stat_raised': re.compile(r"the more (?:the )?user[’']s stats (?:have been|are) raised", re.IGNORECASE),
    'multi_stat_lowered': re.compile(r"the more (?:the )?target[’']s stats (?:have been|are) lowered", re.IGNORECASE),
    # HP scaling
    'lower_user_hp_higher_power': re.compile(r"more powerful the lower|more powerful as the user[’']s hp", re.IGNORECASE),
    'lower_target_hp': re.compile(r"more powerful the lower the target[’']s hp|doubled if the target[’']s hp is at half or below", re.IGNORECASE),
    'higher_user_hp': re.compile(r"more powerful the more.*hp", re.IGNORECASE),
    # Type rebuff (newer mechanic)
    'rebuff_lowered': re.compile(r"more powerful the more.*type rebuff.*lowered|the more (?:the )?type rebuff", re.IGNORECASE),
    # Successive uses (Fury Cutter style)
    'consecutive_use': re.compile(r"used\s+consecutively|repeated|used\s+again", re.IGNORECASE),
    # Specific named effects
    'never_miss_attack': re.compile(r"never misses", re.IGNORECASE),  # not damage but flag
}

# Filter words for "innate move-power-affecting effect"
DAMAGE_HINT_KEYWORDS = (
    "power is doubled", "doubled if", "doubled when", "power increases",
    "increases the power", "more powerful", "the more", "consecutive",
    "doubled", "× 2", "x2", "(2× power)", "twice that power",
)

findings = defaultdict(list)  # category -> list
moves_seen = set()

def collect(p, mv, is_variation_form=''):
    pname = p['displayName']
    mname = mv.get('name','')
    if not mname:
        return
    desc = mv.get('description','') or ''
    if not desc:
        return
    # Skip moves already covered
    if (pname, mname) in covered:
        return
    desc_l = desc.lower()

    # Quick reject: no power-up hint
    if not any(k in desc_l for k in DAMAGE_HINT_KEYWORDS):
        return

    # Detect patterns
    for cat, pat in PATTERNS.items():
        if pat.search(desc):
            findings[cat].append({
                'pair': pname,
                'move': mname,
                'type': mv.get('type',''),
                'category': mv.get('category',''),
                'isSync': mv.get('isSync', False),
                'form': is_variation_form,
                'desc': desc[:280],
            })
            moves_seen.add((pname, mname))
            break  # one match is enough

for p in sp:
    for mv in p.get('moves', []):
        collect(p, mv)
    for mv in p.get('teraMoves', []):
        collect(p, mv)
    tm = p.get('teraMove')
    if isinstance(tm, dict):
        collect(p, tm)
    for v in p.get('variations', []):
        for mv in v.get('moves', []):
            collect(p, mv, v.get('formName',''))

print(f"## Moves con power-up innato no cubierto por move_scaling.json: {len(moves_seen)}\n")
for cat in sorted(findings):
    items = findings[cat]
    print(f"\n### Categoría: {cat} ({len(items)})")
    for it in items[:25]:
        pn = it['pair'].encode('ascii','replace').decode('ascii')
        mn = it['move'].encode('ascii','replace').decode('ascii')
        form = f" [form: {it['form']}]" if it['form'] else ''
        sync = ' (sync)' if it['isSync'] else ''
        d = it['desc'].encode('ascii','replace').decode('ascii')
        print(f"  - {pn} → `{mn}`{sync}{form}")
        print(f"    > {d}")
    if len(items) > 25:
        print(f"  ... y {len(items)-25} más")
