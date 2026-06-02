"""Import sync-pair kit/grid text docs into assets/data/sync_pairs.json.

This is intentionally narrow: it supports the "Sync Pair Information" and
"All New Sync Grids + Expand" text dumps currently stored in docs/.
Run from repo root:

    python tools/import_sync_docs.py
"""
from __future__ import annotations

import json
import re
import sys
from datetime import datetime
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")


ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"
JSON_PATH = ROOT / "assets" / "data" / "sync_pairs.json"

KIT_FILES = [
    DOCS / "💸 Sync Pair Information 2.68.0.txt",
    DOCS / "💸 Sync Pair Information 2.69.0.txt",
]
GRID_FILES = [
    DOCS / "grids.txt",
    DOCS / "💠 (2.68.0) All New Sync Grids + Expand.txt",
    DOCS / "💠 (2.69.0) All New Sync Grids + Expand.txt",
]

HEADER_RE = re.compile(r"^No\.\s*(\d+)\s+(.+?)\s*$")
SUMMARY_RE = re.compile(r"^\d+\.\s+No\.\s+")
CELL_RE = re.compile(
    r"^Cell\s+(\d+).*?Cord\s*\(\s*(-?\d+)\s*,\s*(-?\d+)\s*,\s*(-?\d+)\s*\)"
    r".*?Cost:\s*\D*(\d+)\s*Energy.*?(\d+)\s*Sync Orb"
)
GENDER_SUFFIX_RE = re.compile(
    r"\s*\((?:Genderless|Male(?:♂️|â™‚ï¸)?|Female(?:♀️|â™€ï¸)?)\)\s*$"
)

STAT_KEYS = {
    "hp": "hp",
    "attack": "atk",
    "defense": "def",
    "sp.atk": "spa",
    "sp. atk": "spa",
    "sp.attack": "spa",
    "sp.def": "spd",
    "sp. def": "spd",
    "sp.defense": "spd",
    "speed": "spe",
}

ALIASES = {
    "Sygna Suit Lusamine & Necrozma": "Sygna Suit Lusamine & Dusk Mane Necrozma",
    "Cheren (Champion) & Tornadus": "Cheren (Champion) & Tornadus Incarnate Forme",
    "May & Mudkip/Marshtomp/Swampert": "May & Mudkip",
    "Calem (Champion) & Greninja âœ¨": "Calem (Champion) & Shiny Greninja",
    "Calem (Champion) & Greninja ✨": "Calem (Champion) & Shiny Greninja",
    "Sygna Suit Ethan & Lugia": "Sygna Suit Ethan & Lugia",
}


def clean_text(value: str) -> str:
    return value.replace("\u00a0", " ").strip()


def strip_doc_suffix(name: str) -> str:
    name = clean_text(name)
    name = re.sub(r"\s+-\s*Tera Type\b.*$", "", name)
    name = re.sub(r"\s+-\s*Sync Move\b.*$", "", name)
    name = re.sub(r"\s+Cell\s+\d+(?:\s+-\s+\d+)?\s*$", "", name)
    return name.strip()


def display_name(raw_name: str) -> str:
    name = strip_doc_suffix(raw_name)
    return name


def match_name(raw_name: str) -> str:
    name = strip_doc_suffix(raw_name)
    name = GENDER_SUFFIX_RE.sub("", name).strip()
    name = re.sub(r"\s+", " ", name)
    return ALIASES.get(name, name)


def parse_date(line: str) -> str | None:
    m = re.search(r"(\d{1,2})/(\d{1,2})/(\d{4})", line)
    if not m:
        return None
    day, month, year = map(int, m.groups())
    return datetime(year, month, day).strftime("%Y-%m-%d")


def rarity_from_line(line: str) -> int:
    stars = line.count("⭐") + line.count("â­")
    if stars:
        return stars
    m = re.search(r"(\d+)", line)
    return int(m.group(1)) if m else 5


def parse_power(raw: str) -> str:
    raw = clean_text(raw)
    return raw.split("(")[0].strip()


def parse_detail_line(line: str) -> dict[str, str]:
    out = {}
    for part in line.split("|"):
        if ":" not in part:
            continue
        key, value = part.split(":", 1)
        out[clean_text(key).lower()] = parse_power(value)
    return out


def parse_move(lines: list[str], start: int, is_sync: bool = False, is_tera: bool = False):
    header = clean_text(lines[start])
    prefix = "Sync Move:" if is_sync else "💎 Tera Move:" if is_tera else None
    if prefix and prefix in header:
        name = clean_text(header.split(prefix, 1)[1])
    elif ":" in header:
        name = clean_text(header.split(":", 1)[1])
    else:
        name = header

    i = start + 1
    move_type = ""
    category = ""
    desc = ""
    details = {}
    while i < len(lines):
        line = clean_text(lines[i])
        if not line:
            i += 1
            continue
        if (
            line.startswith("Move ")
            or line.startswith("Sync Move:")
            or line.startswith("Passive ")
            or "Passive Details" in line
            or "Base Stats" in line
            or line.startswith("Lv. ")
            or line.startswith("💎 Tera Move:")
            or line.startswith("ðŸ’Ž Tera Move:")
        ):
            break
        if line.startswith("Type:"):
            move_type = clean_text(line.split(":", 1)[1])
        elif line.startswith("Category:"):
            category = clean_text(line.split(":", 1)[1])
        elif line.startswith("Description:"):
            desc = clean_text(line.split(":", 1)[1])
        elif line.startswith("Power:"):
            details = parse_detail_line(line)
        i += 1

    return {
        "name": name,
        "type": move_type,
        "category": category,
        "power": details.get("power", "--"),
        "accuracy": details.get("accuracy", "101" if is_sync else "--"),
        "gauge": details.get("gauge", "--"),
        "target": details.get("target", "An opponent" if is_sync else ""),
        "description": desc,
        "isSync": is_sync,
    }, i


def parse_passives(lines: list[str], start: int):
    passives = []
    i = start
    while i < len(lines):
        line = clean_text(lines[i])
        if not line:
            i += 1
            continue
        if "Base Stats" in line or "Tera Details" in line:
            break
        if "Passive:" in line or line.startswith("Passive "):
            name = line.split(":", 1)[1].strip()
            locked = "🏅" in line or "ðŸ…" in line or "Superawakened" in line
            desc_parts = []
            i += 1
            while i < len(lines):
                nxt = clean_text(lines[i])
                if (
                    not nxt
                    or "Passive:" in nxt
                    or nxt.startswith("Passive ")
                    or "Base Stats" in nxt
                    or "Tera Details" in nxt
                ):
                    break
                desc_parts.append(nxt)
                i += 1
            passives.append(
                {
                    "name": name,
                    "description": " ".join(desc_parts).strip(),
                    "locked": locked,
                    "subPassives": [],
                }
            )
            continue
        i += 1
    return passives


def parse_stats(lines: list[str], start: int):
    stats = {}
    i = start
    current = None
    while i < len(lines):
        line = clean_text(lines[i])
        if line.startswith("Lv. "):
            m = re.search(r"Lv\.\s*(\d+)", line)
            current = m.group(1) if m else None
        elif current and line.startswith("HP :"):
            values = {}
            for part in line.split("|"):
                if ":" not in part:
                    continue
                key, raw_val = part.split(":", 1)
                key = clean_text(key).lower()
                stat_key = STAT_KEYS.get(key)
                if stat_key:
                    values[stat_key] = int(re.search(r"\d+", raw_val).group(0))
            stats[current] = values
        elif line.startswith("----") or "Tera Details" in line:
            break
        i += 1
    return stats


def split_pair_blocks(path: Path):
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    blocks = []
    current = None
    for line in lines:
        clean = clean_text(line)
        h = HEADER_RE.match(clean)
        if h and not SUMMARY_RE.match(clean):
            if current:
                blocks.append(current)
            current = [line]
        elif current is not None:
            current.append(line)
    if current:
        blocks.append(current)
    return blocks


def parse_kit_block(lines: list[str]):
    h = HEADER_RE.match(clean_text(lines[0]))
    if not h:
        return None
    number = int(h.group(1))
    raw_name = h.group(2)
    name = display_name(raw_name)

    role = ex_role = pair_type = weakness = ""
    rarity = 5
    has_ex = False
    has_sa = False
    release = None
    moves = []
    tera_move = None
    passives = []
    stats = {}
    has_tera = any("Tera Type" in clean_text(ln) for ln in lines[:8])

    i = 1
    while i < len(lines):
        line = clean_text(lines[i])
        if line.startswith("Role:"):
            role_part = clean_text(line.split(":", 1)[1])
            if "| EX Role" in role_part:
                role, ex_role = [clean_text(x) for x in role_part.split("| EX Role", 1)]
                ex_role = ex_role.split(":", 1)[-1].strip()
            else:
                role = role_part
        elif line.startswith("Type:"):
            left, right = line.split("|", 1)
            pair_type = clean_text(left.split(":", 1)[1])
            weakness = clean_text(right.split(":", 1)[1])
        elif line.startswith("Rarity:"):
            rarity = rarity_from_line(line)
        elif line.startswith("EX Color"):
            has_ex = "Yes" in line or "Yesâ" in line or "✅" in line
        elif line.startswith("Sync Pair Available:"):
            release = parse_date(line)
        elif line.startswith("Superawakened Available:"):
            has_sa = True
        elif re.match(r"^Move\s+\d+:", line):
            mv, i = parse_move(lines, i)
            moves.append(mv)
            continue
        elif line.startswith("Sync Move:"):
            mv, i = parse_move(lines, i, is_sync=True)
            moves.append(mv)
            continue
        elif "Passive Details" in line:
            passives = parse_passives(lines, i + 1)
        elif "Base Stats" in line:
            stats = parse_stats(lines, i + 1)
        elif "Tera Move:" in line:
            tera_move, i = parse_move(lines, i, is_tera=True)
            continue
        i += 1

    sync_name = next((m["name"] for m in moves if m.get("isSync")), "")
    return {
        "number": number,
        "displayName": name,
        "role": role,
        "exRole": ex_role,
        "type": pair_type,
        "weakness": weakness,
        "rarity": rarity,
        "hasEx": has_ex,
        "hasSuperAwakening": has_sa,
        "syncMoveName": sync_name,
        "releaseDate": release,
        "moves": moves,
        "passives": passives,
        "hasTera": has_tera,
        "teraMove": tera_move,
        "teraPassives": [],
        "stats": stats,
        "teraStatMultiplier": {},
        "megaStatMultiplier": {},
        "megaStats": {},
        "variations": [],
        "cells": [],
        "damagePassives": [],
    }


def compute_bonus(title: str):
    stat_bonus, power_bonus = {}, {}
    low = title.lower()
    m = re.search(r"(\d+)$", title)
    if not m:
        return stat_bonus, power_bonus
    val = int(m.group(1))
    if low.startswith("hp "):
        stat_bonus["hp"] = val
    elif low.startswith("sp. atk") or low.startswith("sp.atk") or low.startswith("sp.attack"):
        stat_bonus["spa"] = val
    elif low.startswith("attack"):
        stat_bonus["atk"] = val
    elif low.startswith("defense"):
        stat_bonus["def"] = val
    elif low.startswith("sp. def") or low.startswith("sp.def") or low.startswith("sp.defense"):
        stat_bonus["spd"] = val
    elif low.startswith("speed"):
        stat_bonus["spe"] = val
    elif ": power" in low:
        power_bonus[title.split(":")[0].strip()] = val
    return stat_bonus, power_bonus


def color_kind(line: str) -> str:
    raw = clean_text(line.split(":", 1)[1])
    m = re.search(r"([A-Za-z][A-Za-z ]+\(.+\)|[A-Za-z][A-Za-z ]+)$", raw)
    return clean_text(m.group(1)) if m else raw


def parse_cell(block: list[str]):
    head = clean_text(block[0])
    h = CELL_RE.match(head)
    if not h:
        return None
    cell_num, q, r, s, energy, orb = map(int, h.groups())
    move_level = 1
    color = ""
    title = ""
    desc = ""
    is_expand = False
    body = [clean_text(x) for x in block[1:]]
    for idx, line in enumerate(body):
        if not line:
            continue
        ml = re.search(r"Move level must be (\d+)", line)
        if ml:
            move_level = int(ml.group(1))
            continue
        if line.startswith("Grid Expand Unlock"):
            is_expand = True
            continue
        if line.startswith("Requirements:"):
            continue
        if line.startswith("Color Grid:"):
            color = color_kind(line)
            continue
        if not title:
            title = line
            for nxt in body[idx + 1 :]:
                if not nxt:
                    continue
                if nxt.startswith(("Requirements:", "Color Grid:", "Grid Expand Unlock")):
                    continue
                desc = "" if nxt == title else nxt
                break

    stat_bonus, power_bonus = compute_bonus(title)
    cell = {
        "cellNumber": cell_num,
        "q": q,
        "r": r,
        "s": s,
        "energyCost": energy,
        "orbCost": orb,
        "title": title,
        "description": desc,
        "colorKind": color,
        "moveLevel": move_level,
        "statBonus": stat_bonus,
        "powerBonus": power_bonus,
    }
    if is_expand:
        cell["isExpand"] = True
    return cell


def parse_grid_file(path: Path):
    grids = {}
    for lines in split_pair_blocks(path):
        h = HEADER_RE.match(clean_text(lines[0]))
        if not h:
            continue
        name = match_name(h.group(2))
        cells = []
        current = []
        for line in lines[1:]:
            if clean_text(line).startswith("Cell "):
                if current:
                    cell = parse_cell(current)
                    if cell:
                        cells.append(cell)
                current = [line]
            elif current:
                current.append(line)
        if current:
            cell = parse_cell(current)
            if cell:
                cells.append(cell)
        if cells:
            grids.setdefault(name, {})
            for cell in cells:
                grids[name][cell["cellNumber"]] = cell
    return grids


def merge_damage_passives(pair: dict):
    existing = {
        (d.get("name"), d.get("source"), d.get("cellNumber"))
        for d in pair.get("damagePassives", [])
    }
    for cell in pair.get("cells", []):
        title = cell.get("title", "")
        desc = cell.get("description", "")
        text = f"{title} {desc}".lower()
        if (
            "power" in text
            and "power ↓" not in text
            and (
                "powers up" in text
                or "power up" in text
                or "strike" in title.lower()
                or "sync" in title.lower()
            )
            and not cell.get("powerBonus")
        ):
            key = (title, "grid_skill", cell.get("cellNumber"))
            if key not in existing:
                pair.setdefault("damagePassives", []).append(
                    {
                        "name": title,
                        "source": "grid_skill",
                        "cellNumber": cell.get("cellNumber"),
                    }
                )
                existing.add(key)


def main():
    pairs = json.loads(JSON_PATH.read_text(encoding="utf-8"))
    by_match = {match_name(p["displayName"]): p for p in pairs}

    added_pairs = []
    updated_pairs = []
    for path in KIT_FILES:
        for block in split_pair_blocks(path):
            parsed = parse_kit_block(block)
            if not parsed:
                continue
            key = match_name(parsed["displayName"])
            if key in by_match:
                pair = by_match[key]
                for field in (
                    "role",
                    "exRole",
                    "type",
                    "weakness",
                    "rarity",
                    "hasEx",
                    "hasSuperAwakening",
                    "syncMoveName",
                    "releaseDate",
                    "moves",
                    "passives",
                    "hasTera",
                    "teraMove",
                    "stats",
                ):
                    pair[field] = parsed[field]
                updated_pairs.append(pair["displayName"])
            else:
                pairs.append(parsed)
                by_match[key] = parsed
                added_pairs.append(parsed["displayName"])

    grids = {}
    for path in GRID_FILES:
        if not path.exists():
            continue
        parsed = parse_grid_file(path)
        for name, cells in parsed.items():
            grids.setdefault(name, {}).update(cells)

    grid_updates = []
    missing_grid_roster = []
    for name, cells_by_num in grids.items():
        pair = by_match.get(name)
        if not pair:
            missing_grid_roster.append(name)
            continue
        current = {c["cellNumber"]: c for c in pair.get("cells", [])}
        before = len(current)
        for num, cell in cells_by_num.items():
            if num in current and current[num].get("isExpand") and not cell.get("isExpand"):
                cell["isExpand"] = True
            current[num] = cell
        pair["cells"] = [current[n] for n in sorted(current)]
        merge_damage_passives(pair)
        if len(current) != before:
            grid_updates.append(f"{pair['displayName']}: {before}->{len(current)}")

    pairs.sort(key=lambda p: (p.get("releaseDate") or "0000-00-00", p.get("number", 0), p.get("displayName", "")))
    JSON_PATH.write_text(json.dumps(pairs, ensure_ascii=False, indent=4) + "\n", encoding="utf-8")

    print(f"Added pairs: {len(added_pairs)}")
    for name in added_pairs:
        print(f"  + {name}")
    print(f"Updated existing pairs from docs: {len(updated_pairs)}")
    print(f"Grid count changes: {len(grid_updates)}")
    for item in grid_updates:
        print(f"  * {item}")
    if missing_grid_roster:
        print(f"Grid docs without roster match: {len(missing_grid_roster)}")
        for name in sorted(set(missing_grid_roster)):
            print(f"  ! {name}")


if __name__ == "__main__":
    main()
