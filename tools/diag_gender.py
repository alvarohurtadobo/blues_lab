"""Diagnose the gender-suffix mismatch between master_passives.json and sync_pairs.json."""
import io, json, sys
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets" / "data"

sp = json.load(open(ASSETS / "sync_pairs.json", encoding="utf-8"))
mp = json.load(open(ASSETS / "master_passives.json", encoding="utf-8"))

# Pick one mismatched name from MP
target_mp = next((e['syncPair'] for e in mp if 'Arc Suit Brock & Onix (Male' in e.get('syncPair','')), None)
print(f"MP target raw bytes: {target_mp.encode('utf-8')}")
print(f"MP codepoints: {[hex(ord(c)) for c in target_mp]}")

# Look for variants in sync_pairs
print("\nSync pair candidates with 'Brock & Onix':")
for p in sp:
    n = p.get('displayName','')
    if 'Brock & Onix' in n:
        print(f"  {n.encode('ascii','replace').decode('ascii')}")
        print(f"    bytes: {n.encode('utf-8')}")
        print(f"    codepoints: {[hex(ord(c)) for c in n]}")
