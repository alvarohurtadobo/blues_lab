"""For each entry in move_scaling.json, look up the corresponding Pomatools move
and compare stepPer1000/capPer1000.
"""
import io, json, re, sys
from collections import defaultdict
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets" / "data"
POMA = ROOT / "legacy" / "Pomatools"

# Load Pomatools moves
txt = open(POMA / "201.f24e83a2e7226478.js", encoding='utf-8').read()
m = re.search(r"JSON\.parse\(['\"](\{.+?\})['\"]\)", txt)
moves_data = json.loads(m.group(1).encode().decode('unicode_escape'))

# Load Pomatools names
txt2 = open(POMA / "502.9c377325220e1efb.js", encoding='utf-8').read()
name_pat = re.compile(r'"(\d+)":\s*\{[^{}]*?"NAME":"([^"]+)"[^{}]*?"DESC":"([^"]+)"')
poma_names = {}
for k, name, desc in name_pat.findall(txt2):
    poma_names[k] = name

# Build poma_by_name index: name -> (id, powerup_array)
poma_by_name = {}
for k, v in moves_data.items():
    if not v.get('powerup'):
        continue
    name = poma_names.get(k)
    if not name:
        continue
    poma_by_name[name] = v['powerup']

# Load move_scaling
ms = json.load(open(ASSETS / "move_scaling.json", encoding='utf-8'))

# Stat code mapping (Pomatools → our codes)
STAT_MAP = {
    'STAT_001': 'hp',
    'STAT_004': 'atk',
    'STAT_008': 'spa',
    'STAT_016': 'spd',
    'STAT_020': 'spe',
    'STAT_032': 'spe',  # speed alt code? check
    'STAT_064': 'def',
    'STAT_128': 'eva',
    'STAT_256': 'acc',
    'STAT_510': 'all_stats',
}

mismatches = []
missing_in_poma = []
for entry in ms:
    pn = entry['syncPair']
    mn = entry['moveName']
    pu = poma_by_name.get(mn)
    if not pu:
        missing_in_poma.append((pn, mn))
        continue
    flat = pu[0]
    # Try to extract poma_step/cap
    if len(flat) < 3:
        continue  # likely status/condition, not stat-scaling
    # 4th element (index 3) is the step (e.g. '250' or threshold table '100,1000|...')
    if len(flat) >= 4:
        param = flat[3]
        # If it's a threshold table format, skip
        if '|' in param or ',' in param:
            continue
        try:
            poma_step = int(param)
        except ValueError:
            continue
        # 5th element (index 4) might be cap
        poma_cap = 0
        if len(flat) >= 5:
            try:
                poma_cap = int(flat[4])
            except ValueError:
                pass
        # Compare
        our_step = entry.get('stepPer1000', 0)
        our_cap = entry.get('capPer1000', 0)
        if our_step != poma_step or (poma_cap and our_cap != poma_cap):
            mismatches.append({
                'pair': pn, 'move': mn,
                'our_step': our_step, 'our_cap': our_cap,
                'poma_step': poma_step, 'poma_cap': poma_cap,
                'poma_powerup': flat,
            })

print(f"Total entries in move_scaling.json: {len(ms)}")
print(f"Mismatches with Pomatools numeric step: {len(mismatches)}")
print(f"Moves not in Pomatools (truly missing): {len(missing_in_poma)}\n")

print("## MISMATCHES (sample)")
for x in mismatches[:30]:
    pn = x['pair'].encode('ascii','replace').decode('ascii')
    mn = x['move'].encode('ascii','replace').decode('ascii')
    print(f"  {pn} / {mn}")
    print(f"    our:  step={x['our_step']}, cap={x['our_cap']}")
    print(f"    poma: step={x['poma_step']}, cap={x['poma_cap']}  (raw={x['poma_powerup']})")
if len(mismatches) > 30:
    print(f"  ... y {len(mismatches)-30} más")
