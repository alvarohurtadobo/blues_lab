"""Port move scaling data from Pomatools to move_scaling.json — SAFE version.

Rules:
- Update existing entry ONLY when Pomatools provides an EXPLICIT numeric param
  (param[3] is a plain integer string). Otherwise leave the existing entry alone.
- Add new entry for moves NOT in our file when Pomatools has:
  (a) explicit numeric param → use those values
  (b) no numeric param → use sync/regular default based on move's isSync flag

Defaults (per damage guide):
- Single-Stat Sync:  step=167, cap=2000   (1 + min(c*0.167, 1.0))
- Multi-Stat Sync:   step=67,  cap=2200   (1 + min(c*0.067, 1.2))
- Regular Multi-Stat: step=1000, cap=12000 (1 + min(c, 11)) — Stored Power/Power Trip
- Regular Single-Stat: not exercised in moves (it's a passive skill mechanic)

Convention: our capPer1000 = max multiplier × 1000 (so cap=2000 means 2.0× max).
Pomatools cap = max additive boost × 1000 (so cap=1000 means +1.0 = 2.0× max).
Translation: our_cap = 1000 + poma_cap.
"""
import io, json, re, sys
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets" / "data"
POMA = ROOT / "legacy" / "Pomatools"

txt = open(POMA / "201.f24e83a2e7226478.js", encoding='utf-8').read()
m = re.search(r"JSON\.parse\(['\"](\{.+?\})['\"]\)", txt)
poma_moves = json.loads(m.group(1).encode().decode('unicode_escape'))
txt2 = open(POMA / "502.9c377325220e1efb.js", encoding='utf-8').read()
name_pat = re.compile(r'"(\d+)":\s*\{[^{}]*?"NAME":"([^"]+)"[^{}]*?"DESC":"([^"]+)"')
poma_names = {k: name for k, name, _ in name_pat.findall(txt2)}

poma_powerup_by_name = {}
for k, v in poma_moves.items():
    pu = v.get('powerup')
    if pu:
        name = poma_names.get(k)
        if name:
            poma_powerup_by_name[name] = pu[0]

# Verified STAT_xxx → our codes (bit-flag scheme)
STAT_MAP = {
    'STAT_001': 'hp', 'STAT_002': 'atk', 'STAT_004': 'def',
    'STAT_008': 'spa', 'STAT_016': 'spd', 'STAT_020': 'def_spd',
    'STAT_032': 'spe', 'STAT_064': 'acc', 'STAT_128': 'eva',
    'STAT_510': 'all_stats',
}

ms = json.load(open(ASSETS / "move_scaling.json", encoding='utf-8'))
existing = {(e['syncPair'], e['moveName']): e for e in ms}
sp = json.load(open(ASSETS / "sync_pairs.json", encoding='utf-8'))


def translate_powerup(pu, is_sync):
    """Translate Pomatools powerup → our schema, only for stat-scaling cases."""
    if not pu or len(pu) < 3:
        return None  # too short — likely Times Modifier handled elsewhere
    targ, code, mech = pu[0], pu[1], pu[2]
    param = pu[3] if len(pu) > 3 else ''
    cap_param = pu[4] if len(pu) > 4 else ''

    who = 'user' if targ == 'TARG_001' else ('target' if targ == 'TARG_004' else None)
    if not who:
        return None

    if mech not in ('RAISE_STAT', 'LOWER_STAT'):
        return None

    stat = STAT_MAP.get(code)
    if stat is None:
        return None

    direction = 'raised' if mech == 'RAISE_STAT' else 'lowered'

    # If param has '|' → threshold table, handle separately (not done here)
    if '|' in str(param):
        return None

    # Numeric param?
    poma_step = None
    if param != '':
        try:
            poma_step = int(param)
        except (ValueError, TypeError):
            return None

    poma_cap = None
    if cap_param != '':
        try:
            poma_cap = int(cap_param)
        except (ValueError, TypeError):
            pass

    if poma_step is not None:
        # Authoritative: use Pomatools values
        result = {
            'stat': stat, 'who': who, 'direction': direction,
            'stepPer1000': poma_step,
        }
        if poma_cap is not None:
            result['capPer1000'] = 1000 + poma_cap
        return result

    # No numeric param — use defaults
    if stat == 'all_stats':
        if is_sync:
            return {'stat': stat, 'who': who, 'direction': direction,
                    'stepPer1000': 67, 'capPer1000': 2200}
        else:
            # Regular Multi-Stat: 1 + min(count, 11) → step=1000, cap=12000
            return {'stat': stat, 'who': who, 'direction': direction,
                    'stepPer1000': 1000, 'capPer1000': 12000}
    # Single-Stat — only sync moves have this innate
    if is_sync:
        return {'stat': stat, 'who': who, 'direction': direction,
                'stepPer1000': 167, 'capPer1000': 2000}
    return None


added = []
updated_via_poma = []

def process_move(pname, mv):
    mn = mv.get('name', '')
    if not mn:
        return
    pu = poma_powerup_by_name.get(mn)
    if not pu:
        return
    is_sync = bool(mv.get('isSync'))
    trans = translate_powerup(pu, is_sync)
    if trans is None:
        return
    trans['syncPair'] = pname
    trans['moveName'] = mn
    key = (pname, mn)
    has_explicit_poma = False
    if len(pu) >= 4 and pu[3] != '' and '|' not in str(pu[3]):
        try:
            int(pu[3])
            has_explicit_poma = True
        except (ValueError, TypeError):
            pass

    if key in existing:
        if not has_explicit_poma:
            # Don't overwrite existing entries when Pomatools has no explicit param
            return
        e = existing[key]
        changed = False
        for k in ('stat', 'who', 'direction', 'stepPer1000', 'capPer1000'):
            if k in trans and e.get(k) != trans[k]:
                changed = True
                break
        if changed:
            old = dict(e)
            e.update(trans)
            updated_via_poma.append((pname, mn, old, trans, pu))
    else:
        ms.append(trans)
        existing[key] = trans
        added.append((pname, mn, trans, pu))


for p in sp:
    pn = p.get('displayName', '')
    for mv in p.get('moves', []):
        process_move(pn, mv)
    if isinstance(p.get('teraMove'), dict):
        process_move(pn, p['teraMove'])
    for v in p.get('variations', []):
        for mv in v.get('moves', []):
            process_move(pn, mv)


(ASSETS / "move_scaling.json").write_text(json.dumps(ms, ensure_ascii=False, indent=4) + "\n", encoding="utf-8")

print(f"## Resultado SAFE port")
print(f"  + {len(added)} entradas nuevas")
print(f"  ~ {len(updated_via_poma)} entradas actualizadas (Pomatools explícito)")
print(f"  Total entries: {len(ms)}\n")

print("### UPDATED via authoritative Pomatools data")
for pn, mn, old, new, pu in updated_via_poma[:30]:
    pp = pn.encode('ascii','replace').decode('ascii')
    mm = mn.encode('ascii','replace').decode('ascii')
    print(f"  - {pp} / `{mm}` poma={pu}")
    print(f"      old: step={old.get('stepPer1000')}, cap={old.get('capPer1000')}, stat={old.get('stat')}")
    print(f"      new: step={new.get('stepPer1000')}, cap={new.get('capPer1000')}, stat={new.get('stat')}")

print(f"\n### ADDED (primeras 30)")
for pn, mn, e, pu in added[:30]:
    pp = pn.encode('ascii','replace').decode('ascii')
    mm = mn.encode('ascii','replace').decode('ascii')
    print(f"  + {pp} / `{mm}` poma={pu} → step={e['stepPer1000']}, cap={e.get('capPer1000')}")
if len(added) > 30:
    print(f"  ... y {len(added)-30} más")
