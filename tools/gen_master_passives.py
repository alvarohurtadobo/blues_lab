"""
Generates assets/data/master_passives.json

Extracts master passive (Teamwork/Flag Bearer/etc.) data from sync_pairs.json
descriptions into pre-processed lookup data.
"""
import json, sys, re

sys.stdout.reconfigure(encoding='utf-8')

with open('assets/data/sync_pairs.json', 'r', encoding='utf-8') as f:
    pairs = json.load(f)

output = []

for pair in pairs:
    pair_name = pair['displayName']
    for pas in pair['passives']:
        desc = pas.get('description', '')
        if 'theme you have on your team' not in desc:
            continue

        # Extract theme
        theme_match = re.search(
            r'with the ([A-Za-z]+) theme you have on your team',
            desc, re.IGNORECASE
        )
        if not theme_match:
            continue
        theme = theme_match.group(1)

        lower = desc.lower()

        # Determine category: physical, special, or any
        if 'physical attack moves' in lower:
            category = 'physical'
        elif 'special attack moves' in lower:
            category = 'special'
        else:
            category = 'any'

        # Does it apply to sync moves?
        applies_to_sync = 'sync move' in lower

        # Extract base power-up percentage
        base_match = re.search(
            r'Powers up .*? by (\d+)%',
            desc, re.IGNORECASE
        )
        base_power_up = int(base_match.group(1)) if base_match else 10

        # Extract per-additional-ally percentage
        per_ally_match = re.search(
            r'Each additional sync pair powers up .*? by (\d+)%',
            desc, re.IGNORECASE
        )
        per_additional_ally = int(per_ally_match.group(1)) if per_ally_match else 5

        # Extract max power-up percentage
        max_match = re.search(
            r'The maximum power-up is (\d+)%',
            desc, re.IGNORECASE
        )
        max_power_up = int(max_match.group(1)) if max_match else 20

        output.append({
            'syncPair': pair_name,
            'passiveName': pas['name'],
            'theme': theme,
            'category': category,
            'appliesToSync': applies_to_sync,
            'basePowerUpPct': base_power_up,
            'perAdditionalAllyPct': per_additional_ally,
            'maxPowerUpPct': max_power_up,
        })

output.sort(key=lambda x: (x['syncPair'], x['passiveName']))

with open('assets/data/master_passives.json', 'w', encoding='utf-8') as f:
    json.dump(output, f, indent=2, ensure_ascii=False)
    f.write('\n')

print(f'Generated {len(output)} entries in assets/data/master_passives.json')
