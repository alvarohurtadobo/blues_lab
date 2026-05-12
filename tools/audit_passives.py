"""Audit passives, master passives, modifiers across all data files.

Outputs to tools/audit_report.md
"""
import io
import json
import re
import sys
from collections import defaultdict
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets" / "data"
OUT = Path(__file__).resolve().parent / "audit_report.md"


def load(name):
    with (ASSETS / name).open(encoding="utf-8") as fh:
        return json.load(fh)


pairs = load("sync_pairs.json")
dp_master = load("damage_passives.json")
mp_master = load("master_passives.json")
pmod_master = load("passive_modifiers.json")
luckies = load("lucky_skills.json")
mvscaling = load("move_scaling.json")

# === 1. Build sets ===
# damage passive master by (name, move_name) and by name
dp_keys = set()
dp_by_name = {}
for entry in dp_master:
    name = entry.get("name", "")
    move = entry.get("move_name", "")
    dp_keys.add((name, move))
    dp_by_name.setdefault(name, []).append(entry)

# Build sub-passive name index
sub_passive_names = set()
for entry in dp_master:
    for sp in entry.get("sub_passives", []):
        sub_passive_names.add(sp.get("name", ""))

# Master passives lookup
mp_by_pair = defaultdict(list)
for entry in mp_master:
    mp_by_pair[entry.get("syncPair", "")].append(entry)

# Passive modifiers lookup
pmod_by_pair = defaultdict(list)
for entry in pmod_master:
    pmod_by_pair[entry.get("syncPair", "")].extend(entry.get("cells", []))


# === 2. Helpers ===
def innate_passive_likely_dmg(name, desc):
    """Heuristic: does this innate passive give damage/stat/power boost worth being in damage_passives?"""
    n = (name + " " + desc).lower()
    keywords = (
        "powers up",
        "power up",
        "moves ↑",
        "↑",
        "sp↑",
        "additional",
        "again", # multi-hit
        "twice",
        "thrice",
        "x2",
        "no miss",
        "never miss",
        "lands every time",
        "won't miss",
        "always hits",
        "critical",
        "ignores",
        "piercing",
        "raises",
        "lower",
        "boost",
        "reduce",
        "after the user uses",
        "next move",
        "first move",
        "first attack",
        "1st move",
        "1st attack",
        "first turn",
    )
    return any(k in n for k in keywords)


def piercing_text(name, desc):
    """Does this passive imply piercing blows (ignore avoidance / always hits / never misses)?"""
    n = (name + " " + desc).lower()
    return any(
        k in n
        for k in (
            "lands every time",
            "won't miss",
            "wont miss",
            "never miss",
            "always hits",
            "ignores accuracy",
            "ignore accuracy",
            "ignores evasion",
            "ignore evasion",
            "regardless of accuracy",
            "regardless of evasi",
            "even if accuracy",
            "even if evasi",
            "no matter the accuracy",
            "no matter the evasi",
        )
    )


def is_piercing_in_dp_master(name):
    n = name.lower()
    if "piercing" in n:
        return True
    # Check if a damage_passive entry exists and has a sub-passive about piercing
    for e in dp_by_name.get(name, []):
        for sp in e.get("sub_passives", []):
            if "piercing" in sp.get("name", "").lower():
                return True
    return False


# === 3. Audit ===
report = []

def section(title):
    report.append(f"\n## {title}\n")


def line(s):
    report.append(s)


report.append("# Audit Report — Passives, Modifiers, Grid Skills\n")
report.append(f"Source: {len(pairs)} sync pairs, "
              f"{len(dp_master)} damage_passive entries, "
              f"{len(mp_master)} master_passives, "
              f"{len(pmod_master)} passive_modifier groups.\n")

# === 3a. Missing damagePassive references ===
section("3a. damagePassives refs en sync_pairs.json sin entrada master en damage_passives.json")
missing_refs = []
for p in pairs:
    name = p.get("displayName", "")
    for ref in p.get("damagePassives", []):
        rname = ref.get("name", "")
        rmove = ref.get("moveName", "")
        if (rname, rmove) not in dp_keys and rname not in dp_by_name:
            missing_refs.append((name, rname, rmove, ref.get("source", "")))

if not missing_refs:
    line("(ninguna)")
else:
    for pn, rn, rm, src in missing_refs:
        line(f"- **{pn}** → `{rn}` (move=`{rm}`, source=`{src}`) — sin definición en damage_passives.json")

# === 3b. Pairs sin damagePassives (lista posiblemente con omisiones) ===
section("3b. Sync pairs SIN ningún damagePassive ref (¿faltan codificar?)")
nodp = []
for p in pairs:
    if not p.get("damagePassives"):
        # ignore non-strikers / supports (no role check available, but log anyway)
        # Filter to those with any innate passive likely to be damage-related
        suggestive = []
        for pas in p.get("passives", []):
            if innate_passive_likely_dmg(pas.get("name", ""), pas.get("description", "")):
                suggestive.append(pas.get("name", ""))
        if suggestive:
            nodp.append((p.get("displayName", ""), p.get("role", ""), suggestive))

line(f"Total sync pairs sin damagePassives: {sum(1 for p in pairs if not p.get('damagePassives'))}")
line(f"De esos, con pasivas que aparentan ofensivas/relevantes: {len(nodp)}")
line("")
for pn, role, sug in nodp[:120]:
    sug_str = ", ".join(sug[:4])
    line(f"- **{pn}** (role=`{role}`) → pasivas detectadas: {sug_str}")
if len(nodp) > 120:
    line(f"\n_(+{len(nodp) - 120} más, truncados)_")

# === 3c. Innate passives by name not present in damage_passives master ===
section("3c. Pasivas innatas (innate / sub passives) cuyo NOMBRE no aparece en damage_passives.json")
missing_innate = defaultdict(list)
for p in pairs:
    for pas in p.get("passives", []):
        nm = pas.get("name", "")
        # strip trailing numbers e.g. " 5"
        if nm and nm not in dp_by_name:
            # also try stripping trailing digits
            base = re.sub(r"\s+\d+$", "", nm)
            if base in dp_by_name:
                continue
            if innate_passive_likely_dmg(nm, pas.get("description", "")):
                missing_innate[nm].append(p.get("displayName", ""))

line(f"Pasivas innatas no encontradas (ofensivas/relevantes): {len(missing_innate)}\n")
for nm, owners in sorted(missing_innate.items())[:80]:
    line(f"- `{nm}` — usada por: {', '.join(owners[:5])}{' (+'+str(len(owners)-5)+')' if len(owners)>5 else ''}")
if len(missing_innate) > 80:
    line(f"\n_(+{len(missing_innate) - 80} más)_")

# === 3d. Sub-passives en cells.subPassives sin master entry ===
section("3d. Cell sub-passives ofensivas sin entrada en damage_passives.json")
missing_subs = defaultdict(list)
for p in pairs:
    for c in p.get("cells", []):
        for sp in c.get("subPassives", []):
            nm = sp.get("name", "")
            if not nm:
                continue
            if nm in dp_by_name or nm in sub_passive_names:
                continue
            base = re.sub(r"\s+\d+$", "", nm)
            if base in dp_by_name or base in sub_passive_names:
                continue
            if innate_passive_likely_dmg(nm, sp.get("description", "")):
                missing_subs[nm].append(p.get("displayName", ""))

line(f"Sub-passives huérfanas (ofensivas): {len(missing_subs)}\n")
for nm, owners in sorted(missing_subs.items())[:80]:
    line(f"- `{nm}` — cell de: {', '.join(owners[:5])}{' (+'+str(len(owners)-5)+')' if len(owners)>5 else ''}")
if len(missing_subs) > 80:
    line(f"\n_(+{len(missing_subs) - 80} más)_")

# === 3e. Piercing blows tagging ===
section("3e. Piercing Blows — pasivas con efecto pero sin tag/nombre que lo refleje")
pierce_findings = []
for p in pairs:
    pname = p.get("displayName", "")
    for pas in p.get("passives", []) + p.get("teraPassives", []):
        nm = pas.get("name", "")
        desc = pas.get("description", "")
        if piercing_text(nm, desc) and not is_piercing_in_dp_master(nm) and "piercing" not in nm.lower():
            pierce_findings.append((pname, nm, desc[:120]))
    for c in p.get("cells", []):
        for sp in c.get("subPassives", []):
            nm = sp.get("name", "")
            desc = sp.get("description", "")
            if piercing_text(nm, desc) and "piercing" not in nm.lower():
                pierce_findings.append((pname, f"cell #{c.get('cellNumber')}: {nm}", desc[:120]))

line(f"Posibles piercing blows sin tag: {len(pierce_findings)}\n")
for pn, nm, desc in pierce_findings[:60]:
    line(f"- **{pn}** → `{nm}`\n    > {desc}")
if len(pierce_findings) > 60:
    line(f"\n_(+{len(pierce_findings) - 60} más)_")

# === 3f. Master passives - pairs missing entry ===
section("3f. Master Passives — sync pairs sin entrada en master_passives.json")
# Identify which pairs SHOULD have a master passive — typically rarity 5 EX or known champion/banner
no_mp = []
for p in pairs:
    pname = p.get("displayName", "")
    if pname in mp_by_pair:
        continue
    # Heuristic: a master passive is given to many pairs. Only flag those that
    # mention common theme keywords in display name or in passives, or that are EX-ready
    name_l = pname.lower()
    has_indicator = any(k in name_l for k in (
        "champion", "(alt.)", "anniversary", "(spirit)", "(pride)",
        "(flag bearer)", "sygna suit",
    ))
    # Also check if any passive's description mentions Pride/Spirit/Flag Bearer/Rush
    if not has_indicator:
        for pas in p.get("passives", []):
            t = pas.get("name", "") + " " + pas.get("description", "")
            if any(k in t.lower() for k in ("pride", "spirit", "flag bearer", "rush", "myth", "teamwork")):
                has_indicator = True
                break
    if has_indicator:
        no_mp.append((pname, p.get("role", "")))

line(f"Sin master_passives.json (potencial): {len(no_mp)}\n")
for pn, role in no_mp[:120]:
    line(f"- **{pn}** (role=`{role}`)")
if len(no_mp) > 120:
    line(f"\n_(+{len(no_mp) - 120} más)_")

# === 3g. Master passive theme/category sanity ===
section("3g. Master Passives — chequeo de consistencia theme/category")
mp_issues = []
for e in mp_master:
    sp = e.get("syncPair", "")
    cat = e.get("category", "")
    if cat not in ("any", "physical", "special"):
        mp_issues.append(f"- **{sp}** → category inválido `{cat}`")
    if e.get("basePowerUpPct", 0) > e.get("maxPowerUpPct", 0):
        mp_issues.append(f"- **{sp}** → basePowerUpPct > maxPowerUpPct")
    # Match: if name contains 'Rush' should be appliesToSync=true ideally
    nm = e.get("passiveName", "").lower()
    if "rush" in nm and not e.get("appliesToSync"):
        mp_issues.append(f"- **{sp}** → Rush passive sin appliesToSync (revisar)")
    if "spirit" in nm and e.get("category") != "special":
        mp_issues.append(f"- **{sp}** → Spirit pero category='{e.get('category')}' (esperado 'special')")
    if "pride" in nm and e.get("category") != "physical":
        mp_issues.append(f"- **{sp}** → Pride pero category='{e.get('category')}' (esperado 'physical')")
    if "flag bearer" in nm and e.get("category") != "any":
        mp_issues.append(f"- **{sp}** → Flag Bearer pero category='{e.get('category')}' (esperado 'any')")

if not mp_issues:
    line("(sin incidencias)")
else:
    for s in mp_issues:
        line(s)

# === 3h. Pairs with variations and type changes ===
section("3h. Pairs con variaciones / cambio de tipo de movimiento")
var_findings = []
for p in pairs:
    if not p.get("variations"):
        continue
    pname = p.get("displayName", "")
    pair_type = p.get("type", "")
    forms = []
    for v in p.get("variations", []):
        # Detect any move whose type differs from base move (same name) — or differs from pair_type
        type_changes = []
        for m in v.get("moves", []):
            mt = m.get("type", "")
            mn = m.get("name", "")
            # find base move with same name
            base = next((bm for bm in p.get("moves", []) if bm.get("name") == mn), None)
            if base and base.get("type") != mt and mt and base.get("type"):
                type_changes.append(f"{mn}: {base.get('type')} → {mt}")
            elif not base and mt and mt != pair_type:
                # new move not in base list with off-type
                type_changes.append(f"(nuevo) {mn} ({mt})")
        statm = v.get("statMultiplier", {})
        forms.append((v.get("formName", "?"), type_changes, bool(statm)))
    var_findings.append((pname, pair_type, forms))

line(f"Pairs con variaciones: {len(var_findings)}\n")
for pn, pt, forms in var_findings:
    line(f"\n### {pn} (base type=`{pt}`)")
    for fname, tc, has_mult in forms:
        line(f"- Forma `{fname}` — statMultiplier={'sí' if has_mult else '—'}")
        for change in tc:
            line(f"    - cambio tipo: {change}")

# === 3i. Cells without proper coding (empty subPassives + look offensive) ===
section("3i. Celdas con título ofensivo pero sin subPassives ni statBonus/powerBonus")
empty_offensive = []
for p in pairs:
    pname = p.get("displayName", "")
    for c in p.get("cells", []):
        if c.get("subPassives") or c.get("statBonus") or c.get("powerBonus"):
            continue
        title = c.get("title", "")
        desc = c.get("description", "")
        if not title:
            continue
        # Heuristic
        t = (title + " " + desc).lower()
        looks_offensive = any(k in t for k in (
            "power up", "powers up", "boost", "↑", "raise", "lower",
            "increase", "decrease", "no miss", "lands every", "critical",
            "ignore", "piercing", "team", "ally", "sync move",
        ))
        if looks_offensive:
            empty_offensive.append((pname, c.get("cellNumber"), title))

line(f"Celdas posiblemente sin codificar: {len(empty_offensive)}\n")
for pn, cn, t in empty_offensive[:80]:
    line(f"- **{pn}** cell #{cn}: `{t}`")
if len(empty_offensive) > 80:
    line(f"\n_(+{len(empty_offensive) - 80} más)_")

# === 3j. passive_modifiers.json with empty fields (no asignar) ===
section("3j. passive_modifiers.json — entradas con campos vacíos (sin pasiva asignada)")
empty_pmod = []
for e in pmod_master:
    sp = e.get("syncPair", "")
    for cell in e.get("cells", []):
        if not (cell.get("passiveName") or "").strip():
            empty_pmod.append((sp, cell.get("cellNumber")))

line(f"Entradas vacías en passive_modifiers: {len(empty_pmod)}\n")
groups = defaultdict(list)
for sp, cn in empty_pmod:
    groups[sp].append(cn)
for sp, cns in sorted(groups.items())[:80]:
    line(f"- **{sp}** → cells {sorted(cns)}")
if len(groups) > 80:
    line(f"\n_(+{len(groups) - 80} más)_")

# === 3k. Multiplicadores faltantes: damage_passives sin value? ===
section("3k. damage_passives con value=0 y mecanismo que requiere multiplicador")
zero_dp = []
needs_value_mechanism = {
    "flat_boost", "user_stat_raised", "target_stat_lowered",
    "stat_is_raised", "stat_is_lowered", "stat_not_raised",
    "gauge_cost_boost", "PMUN", "SMUN", "stat_raised_30pct",
}
for e in dp_master:
    if e.get("type") == "composite":
        # check each sub
        for sp in e.get("sub_passives", []):
            if sp.get("mechanism") in needs_value_mechanism and (sp.get("value", 0) == 0 and sp.get("sub_value", 0) == 0):
                zero_dp.append(f"composite `{e.get('name')}` → sub `{sp.get('name','')}` mech=`{sp.get('mechanism','')}` value=0")
        continue
    if e.get("mechanism") in needs_value_mechanism and (e.get("value", 0) == 0):
        zero_dp.append(f"`{e.get('name')}` mech=`{e.get('mechanism')}` applies_to=`{e.get('applies_to')}` value=0")

line(f"Posibles multipliers sin configurar: {len(zero_dp)}\n")
for s in zero_dp[:120]:
    line(f"- {s}")
if len(zero_dp) > 120:
    line(f"\n_(+{len(zero_dp) - 120} más)_")

# === 3l. Move scaling — moves with scaling not in move_scaling.json? ===
section("3l. Moves con descripción de escalado/HP pero sin entrada en move_scaling.json")
scaling_keys = {(s.get("syncPair", ""), s.get("moveName", "")) for s in mvscaling}
scaling_missing = []
SCALING_HINTS = (
    "more powerful the more",
    "more powerful the lower",
    "more powerful as the user",
    "scales with",
    "increases in power",
    "more its stats are raised",
    "more its stats are lowered",
    "increases with each stat",
)
for p in pairs:
    pname = p.get("displayName", "")
    for m in p.get("moves", []):
        desc = (m.get("description", "") or "").lower()
        if any(h in desc for h in SCALING_HINTS):
            if (pname, m.get("name", "")) not in scaling_keys:
                scaling_missing.append((pname, m.get("name", ""), desc[:120]))

line(f"Moves probable escalado sin entry: {len(scaling_missing)}\n")
for pn, mn, d in scaling_missing[:80]:
    line(f"- **{pn}** → `{mn}`\n    > {d}")
if len(scaling_missing) > 80:
    line(f"\n_(+{len(scaling_missing) - 80} más)_")

# === 3m. Super Awakening passives present? ===
section("3m. Super Awakening — pares con hasSuperAwakening=true y sus pasivas SA")
sa_pairs = [p for p in pairs if p.get("hasSuperAwakening")]
line(f"Total con hasSuperAwakening: {len(sa_pairs)}\n")

# Check if any has explicit super_awakening source in damagePassives
sa_with_coded = 0
sa_without_coded = []
for p in sa_pairs:
    has_sa_dp = any(ref.get("source", "") == "super_awakening" for ref in p.get("damagePassives", []))
    if has_sa_dp:
        sa_with_coded += 1
    else:
        # check if any cell has SA-ish description?
        sa_without_coded.append(p.get("displayName", ""))

line(f"  - Con damagePassive source=`super_awakening`: {sa_with_coded}")
line(f"  - Sin SA codificada: {len(sa_without_coded)}\n")
for pn in sa_without_coded[:80]:
    line(f"- {pn}")
if len(sa_without_coded) > 80:
    line(f"\n_(+{len(sa_without_coded) - 80} más)_")

# === Write report ===
OUT.write_text("\n".join(report), encoding="utf-8")
print(f"Report written: {OUT} ({OUT.stat().st_size} bytes)")
