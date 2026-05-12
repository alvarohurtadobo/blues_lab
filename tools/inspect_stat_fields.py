"""Verify the stat/stat_target/applies_to fields for the 41 stage-scaled
passives we just touched. Show entries with bad/missing stat fields."""
import io
import json
import sys
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets" / "data"
with (ASSETS / "damage_passives.json").open(encoding="utf-8") as fh:
    dp = json.load(fh)

# Expected stat per Table 9 + dual/multi
EXPECTED = {
    # name -> (mechanism, stat, stat_target, applies_to)
    # Single-Stat User Raised → Regular Moves
    "Furious Brawn":    ("user_stat_raised", "atk", "self", "moves"),
    "Tough Cookie":     ("user_stat_raised", "def", "self", "moves"),
    "Furious Brain":    ("user_stat_raised", "spa", "self", "moves"),
    "Smart Cookie":     ("user_stat_raised", "spd", "self", "moves"),
    "Ramming Speed":    ("user_stat_raised", "spe", "self", "moves"),
    "Bob and Weave":    ("user_stat_raised", "eva", "self", "moves"),
    "Brutal Clarity":   ("user_stat_raised", "acc", "self", "moves"),
    # Single-Stat User Raised → Sync
    "Haymaker":         ("user_stat_raised", "atk", "self", "sync_move"),
    "Towering Force":   ("user_stat_raised", "def", "self", "sync_move"),
    "Brainpower":       ("user_stat_raised", "spa", "self", "sync_move"),
    "Brute Wits":       ("user_stat_raised", "spd", "self", "sync_move"),
    "Inertia":          ("user_stat_raised", "spe", "self", "sync_move"),
    "Blind Spot":       ("user_stat_raised", "eva", "self", "sync_move"),
    # Single-Stat Target Lowered → Regular
    "Power Posture":    ("target_stat_lowered", "atk", "target", "moves"),
    "Insult to Injury": ("target_stat_lowered", "def", "target", "moves"),
    "Overpower":        ("target_stat_lowered", "spa", "target", "moves"),
    "Brainteaser":      ("target_stat_lowered", "spd", "target", "moves"),
    "Hunter’s Instinct":("target_stat_lowered", "spe", "target", "moves"),
    "Wide Open":        ("target_stat_lowered", "eva", "target", "moves"),
    "Dizzying Power":   ("target_stat_lowered", "acc", "target", "moves"),
    # Single-Stat Target Lowered → Sync
    "Pecking Order":    ("target_stat_lowered", "atk", "target", "sync_move"),
    "Relentless":       ("target_stat_lowered", "def", "target", "sync_move"),
    "Devastation":      ("target_stat_lowered", "spa", "target", "sync_move"),
    "Smarty-Pants":     ("target_stat_lowered", "spd", "target", "sync_move"),
    "Cakewalk":         ("target_stat_lowered", "spe", "target", "sync_move"),
    "Easy Target":      ("target_stat_lowered", "eva", "target", "sync_move"),
    "Hide and Sync":    ("target_stat_lowered", "acc", "target", "sync_move"),
    # Multi-Stat
    "Good Form":        ("user_stat_raised", "all_stats", "self", "moves"),
    "Rising Tide":      ("user_stat_raised", "all_stats", "self", "sync_move"),
    "Power Loving":     ("target_stat_lowered", "all_stats", "target", "moves"),
    "Power Play":       ("target_stat_lowered", "all_stats", "target", "sync_move"),
    # Dual-Stat (SpA + SpD). Calc currently doesn't model dual; mark as all_stats for now
    "Added Insult":     ("target_stat_lowered", "spa_spd", "target", "moves"),
}

# Names that don't use stat scaling (flat_boost / PMUN / SMUN / gauge etc.)
NON_SCALED = {
    "Burning Dance", "Destructive Instinct", "Factory Knowledge",
    "Journey from Pallet", "New Teacher’s Quick Wit",
    "Rose’s Results", "Royal Fortune", "Sync Power Flux",
    "Team Moves ↑ as Stats ↑", "The Will to Protect",
}

issues = []
ok = []
for i, e in enumerate(dp):
    if e.get("type") == "composite":
        for j, sp in enumerate(e.get("sub_passives", [])):
            nm = sp.get("name", "")
            if nm in EXPECTED:
                want = EXPECTED[nm]
                got = (sp.get("mechanism",""), sp.get("stat",""), sp.get("stat_target",""), sp.get("applies_to",""))
                if got != want:
                    issues.append((f"composite#{i}.{j}", nm, got, want))
                else:
                    ok.append(nm)
        continue
    nm = e.get("name", "")
    if nm in EXPECTED:
        want = EXPECTED[nm]
        got = (e.get("mechanism",""), e.get("stat",""), e.get("stat_target",""), e.get("applies_to",""))
        if got != want:
            issues.append((f"#{i}", nm, got, want))
        else:
            ok.append(nm)

print(f"## Entradas correctas: {len(ok)}")
print(f"## Entradas con campos incorrectos: {len(issues)}\n")

# Group issues by name
from collections import defaultdict
by_name = defaultdict(list)
for idx, nm, got, want in issues:
    by_name[nm].append((idx, got, want))

for nm in sorted(by_name):
    occs = by_name[nm]
    print(f"\n### `{nm}` ({len(occs)} entradas mal)")
    print(f"   actual: {occs[0][1]}")
    print(f"   esperado: {occs[0][2]}")
    print(f"   indexes: {[o[0] for o in occs]}")
