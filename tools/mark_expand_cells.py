"""One-off data prep: ensure sync-grid expansion cells exist in sync_pairs.json and
are flagged with "isExpand": true.

Expansions are the cells the doc files mark with a "Grid Expand Unlock" line. The
JSON has no unlock field, so we cross-reference by (pair name, cellNumber); cellNumber
is stable between docs and JSON even when axial coords drift. The "No. N" in the docs
is a banner index, NOT the JSON `number`, so we match on the normalized display name.

Two actions:
  1. For pairs whose expansion cells already exist in JSON -> set isExpand=true.
  2. For the handful whose JSON grid stops at cell 48 -> parse the expansion cells
     from docs/grids.txt and insert them (with isExpand=true).

The app does not need an importer at runtime; this just backfills the asset.
Run from repo root:  python tools/mark_expand_cells.py [--dry-run]
"""
import glob
import json
import re
import sys

sys.stdout.reconfigure(encoding="utf-8")

DOCS = "docs"
GRIDS = "docs/grids.txt"
JSON_PATH = "assets/data/sync_pairs.json"

HEADER = re.compile(r"^No\.\s*\d+\s+(.*?)\s*$")
SUMMARY_LINE = re.compile(r"^\d+\.\s")
CELL_HEAD = re.compile(
    r"^Cell\s+(\d+)\s*\|\s*🎯\s*Cord\s*\(\s*(-?\d+)\s*,\s*(-?\d+)\s*,\s*(-?\d+)\s*\)"
    r"\s*\|\s*Cost:\s*⚡\s*(\d+)\s*Energy\s*\|\s*🔮\s*(\d+)\s*Sync Orb"
)
GENDER_SUFFIX = re.compile(r"\s*\((?:Genderless|Male♂️|Female♀️|Male|Female)\)\s*$")
TRAILING_JUNK = re.compile(r"\s*(?:-\s*Sync Move\b.*|-\s*Incarnate Forme\b.*|Cell\s+\d+\s*)$")

# Doc display name -> JSON display name for pairs whose form is folded into the JSON
# name. Keyed AFTER normalization (gender suffix + trailing junk removed).
ALIASES = {
    "Cheren (Champion) & Tornadus": "Cheren (Champion) & Tornadus Incarnate Forme",
    "Marnie (Champion) & Moltres": "Marnie (Champion) & Galarian Moltres",
    "Sygna Suit Lusamine & Necrozma": "Sygna Suit Lusamine & Dusk Mane Necrozma",
    "Sygna Suit Serena & Zygarde": "Sygna Suit Serena & Zygarde 50% Forme",
    "Hilbert & Oshawott/Dewott/Samurott": "Hilbert & Oshawott",
}


def norm(name: str) -> str:
    name = TRAILING_JUNK.sub("", name.strip())
    name = GENDER_SUFFIX.sub("", name.strip())
    name = re.sub(r"\s+", " ", name).strip()
    return ALIASES.get(name, name)


def compute_bonus(title: str):
    """Mirror SyncPairRepository._parseCell fallback for statBonus/powerBonus."""
    stat_bonus, power_bonus = {}, {}
    low = title.lower()
    m = re.search(r"(\d+)$", title)
    if not m:
        return stat_bonus, power_bonus
    val = int(m.group(1))
    if "hp" in low:
        stat_bonus["hp"] = val
    elif "sp.atk" in low or "sp.attack" in low:
        stat_bonus["spa"] = val
    elif "attack" in low:
        stat_bonus["atk"] = val
    elif "defense" in low:
        stat_bonus["def"] = val
    elif "sp.def" in low or "sp.defense" in low:
        stat_bonus["spd"] = val
    elif "speed" in low:
        stat_bonus["spe"] = val
    elif ": power" in low:
        power_bonus[title.split(":")[0].strip()] = val
    return stat_bonus, power_bonus


def parse_doc_cell(block: str):
    """Parse one 'Cell N | ...' block from a doc into a JSON-shaped cell dict."""
    lines = block.splitlines()
    h = CELL_HEAD.match(lines[0])
    if not h:
        return None
    cell_num, q, r, s, energy, orb = (int(x) for x in h.groups())

    move_level = 1
    color = ""
    effect_title = ""
    effect_desc = ""
    body = [ln.strip() for ln in lines[1:]]
    for i, ln in enumerate(body):
        if not ln:
            continue
        ml = re.search(r"Move level must be (\d+)", ln)
        if ml:
            move_level = int(ml.group(1))
            continue
        if ln.startswith("Requirements:"):
            continue
        if ln.startswith("Color Grid:"):
            color = re.sub(r"^Color Grid:\s*[🟨🟦🟥🟪🟩🟧⬜🟫⚪]*\s*", "", ln).strip()
            continue
        if ln.startswith("Grid Expand Unlock"):
            continue
        # First non-meta line is the effect title; the line after it is its long text.
        if not effect_title:
            effect_title = ln
            if i + 1 < len(body) and body[i + 1] and not body[i + 1].startswith(
                ("Color Grid:", "Grid Expand Unlock", "Requirements:")
            ):
                effect_desc = body[i + 1]

    title = effect_title
    description = effect_desc or effect_title
    stat_bonus, power_bonus = compute_bonus(title)
    return {
        "cellNumber": cell_num,
        "q": q, "r": r, "s": s,
        "energyCost": energy,
        "orbCost": orb,
        "title": title,
        "description": description,
        "colorKind": color or "Yellow (Passive)",
        "moveLevel": move_level,
        "statBonus": stat_bonus,
        "powerBonus": power_bonus,
        "isExpand": True,
    }


def collect_from_docs():
    """Return {normalized_name: {cellNumber: cell_dict_or_None}} for unlock cells.

    cell_dict is parsed from grids.txt when available so we can insert missing ones;
    other docs only contribute the cell *number* (value None) for flagging.
    """
    result = {}
    # Pass 1: every doc, record which cell numbers are expansions.
    for path in glob.glob(f"{DOCS}/*.txt"):
        text = open(path, encoding="utf-8").read()
        current, cur_cell = None, None
        for line in text.splitlines():
            if SUMMARY_LINE.match(line):
                continue
            h = HEADER.match(line)
            if h:
                current, cur_cell = norm(h.group(1)), None
                continue
            c = re.match(r"^Cell\s+(\d+)\s*\|", line)
            if c:
                cur_cell = int(c.group(1))
                continue
            if "Grid Expand Unlock" in line and current and cur_cell:
                result.setdefault(current, {}).setdefault(cur_cell, None)
    # Pass 2: grids.txt full cell blocks (for insertion).
    text = open(GRIDS, encoding="utf-8").read()
    parts = re.split(r"(?m)^No\.\s*\d+\s+(.*)$", text)
    for i in range(1, len(parts), 2):
        name = norm(parts[i])
        if name not in result:
            continue
        for block in re.split(r"(?m)^(?=Cell \d+ \|)", parts[i + 1]):
            if "Grid Expand Unlock" not in block:
                continue
            cell = parse_doc_cell(block)
            if cell and cell["cellNumber"] in result[name]:
                result[name][cell["cellNumber"]] = cell
    return result


def main():
    expand = collect_from_docs()
    pairs = json.load(open(JSON_PATH, encoding="utf-8"))
    json_names = {p.get("displayName", "") for p in pairs}

    marked = inserted = 0
    insufficient_doc = []
    for pair in pairs:
        cells_by_num = expand.get(pair.get("displayName", ""))
        if not cells_by_num:
            continue
        have = {c["cellNumber"] for c in pair["cells"]}
        for num in sorted(cells_by_num):
            if num in have:
                for c in pair["cells"]:
                    if c["cellNumber"] == num:
                        c["isExpand"] = True
                        marked += 1
            else:
                cell = cells_by_num[num]
                if cell is None:
                    insufficient_doc.append(f"{pair['displayName']} cell {num}")
                    continue
                pair["cells"].append(cell)
                inserted += 1
        pair["cells"].sort(key=lambda c: c["cellNumber"])

    missing_roster = sorted(n for n in expand if n not in json_names)

    print(f"Flagged existing expansion cells: {marked}")
    print(f"Inserted missing expansion cells: {inserted}")
    if insufficient_doc:
        print(f"WARN could not parse full cell from grids.txt ({len(insufficient_doc)}):")
        for n in insufficient_doc:
            print("   ", n)
    if missing_roster:
        print(f"NOTE doc pairs absent from JSON roster ({len(missing_roster)}):")
        for n in missing_roster:
            print("   ", n)

    if "--dry-run" in sys.argv:
        print("(dry-run) not writing")
        return
    with open(JSON_PATH, "w", encoding="utf-8") as f:
        json.dump(pairs, f, ensure_ascii=False, indent=4)
        f.write("\n")
    print("Wrote", JSON_PATH)


if __name__ == "__main__":
    main()
