"""Decode all condition codes used in Pomatools powerup fields by sampling descriptions."""
import io, json, re, sys
from collections import defaultdict
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

POMA = Path('legacy/Pomatools')
txt = open(POMA / "201.f24e83a2e7226478.js", encoding='utf-8').read()
m = re.search(r"JSON\.parse\(['\"](\{.+?\})['\"]\)", txt)
poma = json.loads(m.group(1).encode().decode('unicode_escape'))
txt2 = open(POMA / "502.9c377325220e1efb.js", encoding='utf-8').read()
np = re.compile(r'"(\d+)":\s*\{[^{}]*?"NAME":"([^"]+)"[^{}]*?"DESC":"([^"]+)"')
descs = {k: (name, desc) for k, name, desc in np.findall(txt2)}

# Collect all distinct codes
code_examples = defaultdict(list)
for k, v in poma.items():
    for pu in v.get('powerup', []):
        for token in pu:
            if isinstance(token, str) and (token.startswith('SCPM_') or token.startswith('SCTP_') or
                                              token.startswith('WTHR_') or token.startswith('TERR_') or
                                              token.startswith('ZONE_') or token.startswith('DMFD_') or
                                              token in ('SYNC','REVENGE','HP_HALF','HP_PINCH','UNRSD_STAT','BMPS','GAUGE','BRRY','REBUFF_ANY','SC')):
                if len(code_examples[token]) < 3:
                    name, desc = descs.get(k, ('?', ''))
                    code_examples[token].append((k, name, desc[:240]))

for code in sorted(code_examples):
    print(f"\n=== {code} ===")
    for kid, name, desc in code_examples[code]:
        nn = name.encode('ascii','replace').decode('ascii')
        dd = desc.encode('ascii','replace').decode('ascii')
        print(f"  [{kid}] {nn}")
        print(f"     > {dd}")
