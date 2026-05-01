"""Audit all damage-boosting passives across all pairs."""
import json, os, re, sys

sys.stdout.reconfigure(encoding='utf-8')
BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
POMA = os.path.join(BASE, 'docs', 'pomatools', 'assets')

def load(path):
    with open(os.path.join(POMA, path), encoding='utf-8') as f:
        return json.load(f)

skills = load('data/skills.json')
en = load('i18n/en.json')
pairs_raw = load('data/pairs.json')
grids = load('data/pairgrids.json')
moves_data = load('data/moves.json')
CHARS = en['DATA']['CHAR']
PKMN = en['DATA']['PKMN']
SNAMES = en['DATA']['SKILLS']
MNAMES = en['DATA']['MOVES']

sync_pairs = json.load(open(os.path.join(BASE, 'assets', 'data', 'sync_pairs.json'), encoding='utf-8'))
sp_by_name = {}
for sp in sync_pairs:
    sp_by_name[sp['displayName']] = sp

def resolve(text, val):
    if '{{' not in text: return text
    chance = {1:'10',2:'30',3:'40',4:'50',5:'60',9:'100'}
    return text.replace('{{value}}', str(val)).replace('{{chance}}', chance.get(val, str(val*10)))

def get_pair_name(p):
    base = [pk for pk in p['pokemon'] if pk['kind']=='BASE']
    if not base: return None
    return f"{CHARS.get(p['trainerId'],'?')} & {PKMN.get(base[0]['id'],'?')}"

def is_powerup(sid):
    s = skills.get(str(sid), {})
    return s.get('trigger') == 'CALCULATION' and s.get('type') in ('POWERUP',)

def get_multi_powerup_subs(sid):
    s = skills.get(str(sid), {})
    if s.get('type') != 'MULTI': return []
    spec = s.get('spec', '')
    result = []
    for part in spec.split(','):
        part = part.strip()
        if len(part) < 8: continue
        sub_id = part[:7]
        try:
            sub_val = int(part[7:])
        except ValueError:
            continue
        if is_powerup(int(sub_id)):
            sub_s = skills.get(sub_id, {})
            sub_name = resolve(SNAMES.get(sub_id, {}).get('NAME', '?'), sub_val)
            result.append((sub_id, sub_val, sub_name, sub_s.get('applies','')))
    return result

# ============================================================
# 1. AUDIT SA PAIRS
# ============================================================
print("=" * 60)
print("1. SA PAIRS WITH DAMAGE SUB-PASSIVES")
print("=" * 60)
sa_count = 0
sa_issues = []
for p in pairs_raw:
    awk = p.get('awakeningSkill', 0)
    if not awk: continue
    name = get_pair_name(p)
    if not name: continue
    subs = get_multi_powerup_subs(awk)
    if not subs: continue
    sa_count += 1
    # Check if JSON has subPassives
    sp = sp_by_name.get(name)
    if not sp:
        sa_issues.append(f"  MISSING IN JSON: {name}")
        continue
    sa_passive = sp['passives'][0] if sp['passives'] else None
    json_subs = sa_passive.get('subPassives', []) if sa_passive else []
    has_all = True
    for sub_id, sub_val, sub_name, applies in subs:
        found = any(s['value'] == sub_val and sub_name[:20] in s['name'] for s in json_subs)
        status = 'OK' if found else 'MISSING'
        if not found: has_all = False
        print(f"  {name}: {sub_name} val={sub_val} applies={applies} [{status}]")
    if not has_all:
        sa_issues.append(f"  INCOMPLETE: {name}")

print(f"\nTotal SA with damage subs: {sa_count}")
if sa_issues:
    print("ISSUES:")
    for i in sa_issues: print(i)

# ============================================================
# 2. AUDIT REGULAR PASSIVES (non-SA, non-grid)
# ============================================================
print("\n" + "=" * 60)
print("2. REGULAR PASSIVES WITH DAMAGE BOOST (POWERUP type)")
print("=" * 60)
reg_count = 0
for p in pairs_raw:
    name = get_pair_name(p)
    if not name: continue
    base = [pk for pk in p['pokemon'] if pk['kind']=='BASE'][0]
    for skill_entry in base.get('skills', []):
        sid = skill_entry[0]
        if sid == 0: continue
        # Direct POWERUP
        if is_powerup(sid):
            sname = resolve(SNAMES.get(str(sid), {}).get('NAME', '?'), skill_entry[1])
            applies = skills.get(str(sid), {}).get('applies', '?')
            print(f"  {name}: {sname} applies={applies}")
            reg_count += 1
        # MULTI with POWERUP subs
        subs = get_multi_powerup_subs(sid)
        for sub_id, sub_val, sub_name, applies in subs:
            print(f"  {name}: {sub_name} val={sub_val} applies={applies} (from MULTI)")
            reg_count += 1

print(f"\nTotal regular passive damage boosts: {reg_count}")

# ============================================================
# 3. AUDIT GRID PASSIVES
# ============================================================
print("\n" + "=" * 60)
print("3. GRID MULTI PASSIVES WITH DAMAGE SUB-PASSIVES")
print("=" * 60)
grid_multi_count = 0
for p in pairs_raw:
    name = get_pair_name(p)
    if not name: continue
    grid_id = p.get('gridId', '')
    versions = grids.get(grid_id, [])
    for ver in versions:
        for cell in ver.get('cells', []):
            sid = cell.get('skill', 0)
            if sid == 0: continue
            subs = get_multi_powerup_subs(sid)
            if not subs: continue
            cell_name = resolve(SNAMES.get(str(sid), {}).get('NAME', '?'), cell.get('value', 0))
            for sub_id, sub_val, sub_name, applies in subs:
                print(f"  {name}: grid [{cell_name}] -> {sub_name} val={sub_val} applies={applies}")
                grid_multi_count += 1

print(f"\nTotal grid MULTI damage sub-passives: {grid_multi_count}")

# ============================================================
# 4. AUDIT SYNC MOVE MULTIPLIERS
# ============================================================
print("\n" + "=" * 60)
print("4. SYNC MOVE POWER MULTIPLIERS (from description)")
print("=" * 60)
patterns = [
    (r'the more the (user|target).+?(raised|lowered).+?greater the power', 'stat_scaling'),
    (r"power.+?increases?\s+(\d+)%\s+when", 'pct_conditional'),
    (r"power.+?multiplied by (\d+)", 'multiplied_by'),
    (r"the more.+?greater the power", 'generic_scaling'),
]
sync_mult_count = 0
for sp in sync_pairs:
    for move in sp.get('moves', []):
        if not move.get('isSync'): continue
        desc = move.get('description', '')
        if not desc: continue
        for pat, kind in patterns:
            m = re.search(pat, desc, re.IGNORECASE)
            if m:
                print(f"  {sp['displayName']}: [{kind}] {desc[:120]}")
                sync_mult_count += 1
                break

print(f"\nTotal sync moves with power multipliers: {sync_mult_count}")

# ============================================================
# 5. AUDIT MOVE POWER MULTIPLIERS (non-sync)
# ============================================================
print("\n" + "=" * 60)
print("5. REGULAR MOVE POWER MULTIPLIERS (from description)")
print("=" * 60)
move_mult_count = 0
for sp in sync_pairs:
    for move in sp.get('moves', []):
        if move.get('isSync'): continue
        desc = move.get('description', '')
        if not desc: continue
        for pat, kind in patterns:
            m = re.search(pat, desc, re.IGNORECASE)
            if m:
                print(f"  {sp['displayName']}: {move['name']} [{kind}] {desc[:120]}")
                move_mult_count += 1
                break

print(f"\nTotal regular moves with power multipliers: {move_mult_count}")

# ============================================================
# 6. CHECK SYNC MOVE DESCRIPTIONS NOT CAUGHT
# ============================================================
print("\n" + "=" * 60)
print("6. SYNC MOVES WITH 'POWER' IN DESC (potential misses)")
print("=" * 60)
for sp in sync_pairs:
    for move in sp.get('moves', []):
        if not move.get('isSync'): continue
        desc = move.get('description', '').lower()
        if 'power' not in desc: continue
        if 'no additional effect' in desc: continue
        caught = False
        for pat, kind in patterns:
            if re.search(pat, desc, re.IGNORECASE):
                caught = True
                break
        if not caught:
            print(f"  {sp['displayName']}: {move.get('description','')[:150]}")
