"""Mass-port conditional power-up modifiers from Pomatools to move_scaling.json.

Pomatools condition tag → calc condition string mapping:
  SCPM_003 → poisoned
  SCPM_004 → burned
  SCPM_008 → paralyzed
  SCPM_016 → frozen
  SCPM_032 → asleep
  SCPM_063 → any_status
  SC       → any_condition
  SCTP_001 → confused
  SCTP_002 → flinching
  SCTP_004 → trapped
  SCTP_007 → flinch_confuse_trap
  SCTP_008 → restrained
  WTHR_001 → rain
  WTHR_002 → sunny
  WTHR_004 → sandstorm
  WTHR_008 → hail
  WTHR_015 → any_weather
  TERR_001 → electric_terrain
  TERR_002 → grassy_terrain
  TERR_15  → any_terrain
  ZONE_xxx → <type>_zone (per ZONE_MAP below)
  DMFD_NN  → damage_field_DMFD_NN
  REBUFF_ANY → target_rebuff_lowered
  UNRSD_STAT → no_target_stats_raised
  REVENGE  → SKIP (needs prev_move_failed flag)
  SYNC     → SKIP (needs target_sync_buff flag)
  HP_HALF  → SKIP (already handled as target_hp_half stat)
  HP_PINCH → SKIP (custom per-pair)
  BMPS/BRRY/GAUGE → SKIP (custom mechanics)

Step (boost when condition holds, /1000):
  - If Pomatools provides a numeric param → use that
  - Else try to extract "increases N%" or "doubled" from description
  - Default → 1000 (×2)

Idempotent.
"""
import io, json, re, sys
from pathlib import Path
from collections import defaultdict

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets" / "data"
POMA = ROOT / "legacy" / "Pomatools"

txt = open(POMA / "201.f24e83a2e7226478.js", encoding='utf-8').read()
m = re.search(r"JSON\.parse\(['\"](\{.+?\})['\"]\)", txt)
poma_moves = json.loads(m.group(1).encode().decode('unicode_escape'))
txt2 = open(POMA / "502.9c377325220e1efb.js", encoding='utf-8').read()
np = re.compile(r'"(\d+)":\s*\{[^{}]*?"NAME":"([^"]+)"')
poma_names = {k: n for k, n in np.findall(txt2)}
poma_powerup_by_name = {}
for k, v in poma_moves.items():
    pu = v.get('powerup')
    if pu:
        name = poma_names.get(k)
        if name and name not in poma_powerup_by_name:
            poma_powerup_by_name[name] = pu[0]

# Condition tag → cond string
COND_MAP = {
    'SCPM_003': 'poisoned',
    'SCPM_004': 'burned',
    'SCPM_008': 'paralyzed',
    'SCPM_016': 'frozen',
    'SCPM_032': 'asleep',
    'SCPM_063': 'any_status',
    'SC': 'any_condition',
    'SCTP_001': 'confused',
    'SCTP_002': 'flinching',
    'SCTP_004': 'trapped',
    'SCTP_007': 'flinch_confuse_trap',
    'SCTP_008': 'restrained',
    'WTHR_001': 'rain',
    'WTHR_002': 'sunny',
    'WTHR_004': 'sandstorm',
    'WTHR_008': 'hail',
    'WTHR_015': 'any_weather',
    'TERR_001': 'electric_terrain',
    'TERR_002': 'grassy_terrain',
    'TERR_15':  'any_terrain',
    'REBUFF_ANY': 'target_rebuff_lowered',
    'UNRSD_STAT': 'no_target_stats_raised',
}

# Zone IDs map to type names (Pomatools encoding)
ZONE_MAP = {
    'ZONE_001': 'normal_zone',
    'ZONE_002': 'fire_zone',
    'ZONE_003': 'water_zone',
    'ZONE_004': 'electric_zone',
    'ZONE_005': 'grass_zone',
    'ZONE_006': 'ice_zone',
    'ZONE_007': 'fighting_zone',
    'ZONE_008': 'poison_zone',
    'ZONE_009': 'ground_zone',
    'ZONE_010': 'flying_zone',
    'ZONE_011': 'psychic_zone',
    'ZONE_012': 'bug_zone',
    'ZONE_013': 'rock_zone',
    'ZONE_014': 'ghost_zone',
    'ZONE_015': 'dragon_zone',
    'ZONE_016': 'dark_zone',
    'ZONE_017': 'steel_zone',
    'ZONE_018': 'fairy_zone',
}

INCREASE_PCT_RE = re.compile(r'power\s+(?:increases?|is increased(?:\s+by)?)\s+(\d+)%', re.IGNORECASE)
DOUBLED_RE = re.compile(r"power\s+is\s+doubled", re.IGNORECASE)


def detect_step_from_desc(desc):
    """Return stepPer1000 inferred from move description, or None."""
    if not desc:
        return None
    m_pct = INCREASE_PCT_RE.search(desc)
    if m_pct:
        return int(m_pct.group(1)) * 10  # 50% → 500
    if DOUBLED_RE.search(desc):
        return 1000
    return None


def translate(pu, desc):
    """Translate Pomatools powerup → (cond, step) or None."""
    if not pu or len(pu) < 2:
        return None
    targ, code = pu[0], pu[1]
    rest = pu[2:] if len(pu) > 2 else []

    # Skip stat-scaling (RAISE_STAT/LOWER_STAT) — handled by other port
    if len(rest) >= 1 and rest[0] in ('RAISE_STAT', 'LOWER_STAT'):
        return None
    # Skip mechanisms we don't yet support
    if len(rest) >= 1 and rest[0] in ('COUNTER', 'REVENGE', 'HP_HALF', 'HP_PINCH'):
        return None
    if code in ('SYNC', 'REVENGE', 'BMPS', 'BRRY', 'GAUGE'):
        return None
    if code.startswith('MOVE_'):
        return None

    cond = COND_MAP.get(code) or ZONE_MAP.get(code)
    if not cond:
        if code.startswith('DMFD_'):
            cond = f"damage_field_{code}"
        else:
            return None

    # Step
    step = None
    for elem in rest:
        if isinstance(elem, str) and elem.isdigit():
            step = int(elem)
            break
    if step is None:
        step = detect_step_from_desc(desc) or 1000

    return (cond, step)


ms = json.load(open(ASSETS / "move_scaling.json", encoding='utf-8'))
existing = {(e['syncPair'], e['moveName']) for e in ms}
sp = json.load(open(ASSETS / "sync_pairs.json", encoding='utf-8'))

added = []
skipped_no_match = []

def process(pname, mv):
    mn = mv.get('name', '')
    if not mn:
        return
    pu = poma_powerup_by_name.get(mn)
    if not pu:
        return
    desc = mv.get('description', '') or ''
    t = translate(pu, desc)
    if t is None:
        return
    cond, step = t
    key = (pname, mn)
    if key in existing:
        return
    entry = {
        'syncPair': pname,
        'moveName': mn,
        'stat': f'cond:{cond}',
        'who': 'target' if (cond.endswith('_zone') or 'target' in cond or cond in (
            'paralyzed','burned','frozen','asleep','poisoned','any_status','any_condition',
            'confused','flinching','trapped','restrained','flinch_confuse_trap',
            'no_target_stats_raised','target_rebuff_lowered') or cond.startswith('damage_field_')) else 'user',
        'direction': 'lowered',  # not used for cond:
        'stepPer1000': step,
        'capPer1000': 1000 + step,
    }
    ms.append(entry)
    existing.add(key)
    added.append((pname, mn, cond, step))


for p in sp:
    pn = p.get('displayName', '')
    for mv in p.get('moves', []):
        process(pn, mv)
    if isinstance(p.get('teraMove'), dict):
        process(pn, p['teraMove'])
    for v in p.get('variations', []):
        for mv in v.get('moves', []):
            process(pn, mv)


(ASSETS / "move_scaling.json").write_text(json.dumps(ms, ensure_ascii=False, indent=4) + "\n", encoding="utf-8")

print(f"## Mass port from Pomatools: +{len(added)} new entries")
print(f"## Total entries: {len(ms)}\n")
# Group by cond
by_cond = defaultdict(list)
for pn, mn, c, s in added:
    by_cond[c].append((pn, mn, s))
for c in sorted(by_cond):
    items = by_cond[c]
    print(f"\n### cond:{c}  ({len(items)})")
    for pn, mn, s in items[:10]:
        pp = pn.encode('ascii','replace').decode('ascii')
        mm = mn.encode('ascii','replace').decode('ascii')
        print(f"  + {pp} | `{mm}` step={s}")
    if len(items) > 10:
        print(f"  ... y {len(items)-10} más")
