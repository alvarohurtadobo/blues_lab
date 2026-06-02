# Blues Lab - Data Maintenance Guide

> Documentación de los sistemas de datos, problemas encontrados y checklist para futuras actualizaciones.
> Compilado durante el análisis de las versiones 2.63.0 → 2.69.0 (Junio 2026)

---

## Índice

1. [Arquitectura de Datos](#1-arquitectura-de-datos)
2. [Sistema de Damage Passives](#2-sistema-de-damage-passives)
3. [Sistema de Master Passives](#3-sistema-de-master-passives)
4. [Extended Range (isExtendedRange)](#4-extended-range)
5. [Pasivas de Equipo en Weather/Terrain/Zone](#5-pasivas-de-equipo)
6. [Flujo de Cálculo de Daño](#6-flujo-de-cálculo)
7. [Checklist para Futuras Actualizaciones](#7-checklist)

---

## 1. Arquitectura de Datos

### Archivos Clave

| Archivo | Propósito | Formato |
|---------|-----------|---------|
| `assets/data/sync_pairs.json` | Todos los sync pairs, moves, passives, grids (~9.7MB) | JSON comprimido sin espacios |
| `assets/data/damage_passives.json` | Diccionario maestro de efectos de daño pasivos (666 entradas) | JSON indentado |
| `assets/data/master_passives.json` | Diccionario de Master Passives (96 entradas) | JSON indentado |
| `lib/data/sync_pair_repository.dart` | Lógica de carga y parseo | Dart |
| `lib/damage/calc.dart` | Fórmula de daño | Dart |

### Estructura de sync_pairs.json

```json
{
  "number": 75,
  "displayName": "Ethan (Champion) & Raikou (Genderless)",
  "role": "Support",
  "passives": [ /* lista de objetos passive con subPassives */ ],
  "damagePassives": [ /* refs al diccionario */ ],
  "masterPassives": [ /* refs a master_passives */ ],
  "moves": [ /* lista de movimientos */ ]
}
```

---

## 2. Sistema de Damage Passives

### Problema Encontrado

**Referencias rotas:** Cuando se agregan nuevos pares o grid expands, pueden referenciar nombres de pasivas que no existen en `damage_passives.json`. La calculadora simplemente ignora las que no encuentra, resultando en daño incorrecto.

### Solución

Ejecutar después de agregar nuevos pares:

```bash
python tools/fix_damage_passives.py
```

### Estructura de una entrada

```json
{
  "name": "Earth-Shaking Roar (Moves)",
  "type": "powerup",          // "powerup" | "reducer"
  "applies_to": "pokemon_moves",  // "pokemon_moves" | "sync_move" | "moves" | "moves_and_sync"
  "affects": "team",          // "self" | "team"
  "mechanism": "flat_boost",  // "flat_boost" | "stat_is_lowered" | "stat_raised_30pct"
  "value": 2,                 // 2 = 20%, 5 = 50%, 9 = 90%
  "stat": "",
  "stat_target": "",
  "conditions": [["electric_terrain"]],  // Array de arrays
  "move_name": "",
  "sub_passives": []
}
```

### Tipos de `applies_to`

| Valor | Aplica a | Ejemplo |
|-------|----------|---------|
| `pokemon_moves` | Solo movimientos regulares | Power Reserves |
| `sync_move` | Solo sync move | Brainpower |
| `moves` | Movimientos regulares + MAX | Critical Strike |
| `moves_and_sync` | Movimientos regulares + sync + MAX | Haymaker |

### Tipos de `mechanism`

| Mecanismo | Descripción | value es |
|-----------|-------------|----------|
| `flat_boost` | Multiplicador directo (value × 10%) | Entero (2=20%) |
| `stat_is_lowered` | Escala según stats reducidas del target | Entero (9=90%) |
| `stat_raised_30pct` | Escala según stats del usuario | Entero |
| `conditional` | Se activa solo si se cumplen condiciones | - |

### Condiciones más usadas

| Condición | Uso |
|-----------|-----|
| `electric_terrain` | Terreno Eléctrico |
| `grassy_terrain` | Terreno de Hierba |
| `psychic_terrain` | Terreno Psíquico |
| `sunny` | Clima Soleado |
| `rainy` | Clima Lluvioso |
| `sandstorm` | Tormenta de Arena |
| `hail` | Granizo |
| `critical` | Golpe crítico |
| `burned` | Objetivo quemado |
| `paralyzed` | Objetivo paralizado |
| `asleep` | Objetivo dormido |
| `poisoned` | Objetivo envenenado |
| `confused` | Objetivo confuso |
| `trapped` | Objetivo atrapado |
| `flinching` | Objetivo retrocediendo |
| `dragon_zone` | Zona Dragón |
| `normal_zone` | Zona Normal |
| `any_terrain` | Cualquier terreno |
| `any_weather` | Cualquier clima |
| `super_efective` | Super efectivo |
| `theme_THM` | Circle activo (generic) |
| `theme_THMD_5` | Unova Circle (Defensive) |
| `theme_THMP_2` | Johto Circle (Physical) |
| `theme_THMS_2` | Johto Circle (Special) |
| `theme_THMS_4` | Sinnoh Circle (Special) |

---

## 3. Sistema de Master Passives

### Problema Encontrado

El campo `masterPassives[]` en `sync_pairs.json` estaba vacío para casi todos los pares, a pesar de que `master_passives.json` tenía 94 entradas. La causa fue:

1. **Coincidencia exacta de nombre:** `sync_pair_repository.dart` carga con `mpMap[pairName]` donde `pairName` debe coincidir EXACTAMENTE con la key en `master_passives.json`
2. **Nombres faltantes:** Ethan (Champion) y Lyra (Champion) no existían en `master_passives.json`

### Solución (una sola vez)

```bash
python tools/fix_champion_master_passives.py
```

### Cómo funciona la carga en Dart

```dart
// sync_pair_repository.dart ~ línea 245
masterPassives: mpMap[pairName] ?? const [],
```

Donde `mpMap` se construye así:
```dart
// línea 60-78
final mpMap = <String, List<MasterPassiveData>>{};
for (final entry in mpList) {
  mpMap.putIfAbsent(pairName, () => []).add(MasterPassiveData(...));
}
```

### Estructura de master_passives.json

```json
{
  "syncPair": "Ethan (Champion) & Raikou (Genderless)",
  "passiveName": "Johto's Thundering Legend",
  "theme": "Johto",
  "category": "any",
  "appliesToSync": true,
  "basePowerUpPct": 20,
  "perAdditionalAllyPct": 15,
  "maxPowerUpPct": 50
}
```

### Proceso de cálculo en la calculadora

```
_masterPassivePowerUp():
  1. Itera widget.pair.masterPassives
  2. Busca en master_passives.json por passiveName
  3. basePowerUpPct + perAdditionalAllyPct × (aliados con theme - 1)
  4. Cap en maxPowerUpPct
  5. Si category es "physical" o "special", solo aplica si el ataque coincide
  6. Se suma a totalSkillMult en _totalBp()
```

### Reglas por categoría

| category | Aplica a |
|----------|----------|
| `any` | Todo tipo de ataque (Flag Bearer, Legend) |
| `physical` | Solo ataques físicos (Pride) |
| `special` | Solo ataques especiales (Spirit) |

---

## 4. Extended Range (isExtendedRange)

### Problema Encontrado

7 movimientos AoE no tenían `isExtendedRange: true` a pesar de que su descripción dice:
> "The power of this move is not lowered even if there are multiple targets"

Sin esta flag, la calculadora aplica el multiplicador estándar para ataques multi-target:
- ×0.5 contra 3 objetivos
- ×0.666 contra 2 objetivos

### Movimientos Corregidos

| # | Pair | Movimiento |
|---|------|-----------|
| 54 | Hau & Incineroar | Wild Whirlwind Darkest Lariat |
| 66 | Lyra (Champion) & Entei | Entrapping Blaze Flare Blitz |
| 75 | Ethan (Champion) & Raikou | Thunderous Roar Wild Charge |
| 201 | Rika & Great Tusk | Ancient Times Earth Power |
| 204 | Poppy & Iron Treads | Whirly Twirly Iron Head |
| 234 | SS Kieran & Furret | Great Strides Blizzard |
| 245 | Drayton & Archaludon | Steel Flash Dragon Pulse |

### Regla para detectar

**SI** la descripción del movimiento contiene:
- `"the power of this move is not lowered even if there are multiple targets"`
- `"not lowered even if there are multiple"`

**ENTONCES** debe tener `"isExtendedRange": true`

Total en la base: **59 movimientos** con extended range.

### Herramienta

```bash
python tools/fix_extended_range.py
```

---

## 5. Pasivas de Equipo en Weather/Terrain/Zone

### Patrón Identificado

Muchos pares nuevos tienen pasivas que otorgan bonos de daño **a todo el equipo** cuando se cumple una condición de weather/terrain/zone.

### Ejemplo: Earth-Shaking Roar (Ethan Champion)

La pasiva dice:
> "Powers up the moves of all allied sync pairs when the terrain is Electric Terrain. Powers up the sync moves of all allied sync pairs. Reduces attack move damage taken by allies."

Requiere **3 entradas** en `damage_passives.json`:

```json
// 1. Bono a movimientos regulares
{"name": "Earth-Shaking Roar (Moves)", "type": "powerup", "applies_to": "pokemon_moves", "affects": "team", "value": 2, "conditions": [["electric_terrain"]]}

// 2. Bono a sync moves
{"name": "Earth-Shaking Roar (Sync)", "type": "powerup", "applies_to": "sync_move", "affects": "team", "value": 2, "conditions": [["electric_terrain"]]}

// 3. Reducción de daño
{"name": "Earth-Shaking Roar (DR)", "type": "reducer", "applies_to": "pokemon_moves", "affects": "team", "value": 2, "conditions": [["electric_terrain"]]}
```

### Valores Típicos según el texto de la pasiva

| Texto en pasiva | value | Significado |
|----------------|-------|-------------|
| "Powers up moves" | 2 | 20% |
| "Powers up moves... by 20%" | 2 | 20% |
| "Powers up sync moves" | 2 | 20% |
| "Reduces attack move damage" | 2 | DR 20% |
| "Powers up... by 30%" | 3 | 30% |
| "Powers up... by 50%" | 5 | 50% |

---

## 6. Flujo de Cálculo de Daño

### Diagrama de datos

```
sync_pairs.json
    │
    ▼
sync_pair_repository.dart
    │
    ├─ mpMap["displayName"] → masterPassives[]  ← master_passives.json
    │
    ├─ _resolveDamagePassives() → damagePassives[]  ← damage_passives.json
    │
    └─ SyncPair object → UI
            │
            ▼
      calculator_panel.dart
            │
            ├─ _masterPassivePowerUp() → totalSkillMult
            │     • basePct + perAllyPct × allies
            │     • cap maxPct
            │     • filtro category
            │
            ├─ _totalBp()
            │     • Σ damagePassives powerUps
            │     + masterPassive bonus
            │     + Σ skillPowerUps
            │
            └─ calc.dart
                  • Move Power formula
                  • Stat Ratio formula
                  • Battle Conditions
                  • Damage Rolls
```

### Puntos críticos

1. **Coincidencia de nombres:** `mpMap[pairName]` requiere nombre EXACTO
2. **Referencias:** `damagePassives[name]` en sync_pairs debe existir en damage_passives.json
3. **Múltiples objetivos:** `isExtendedRange` evita penalización ×0.5/×0.666
4. **Team passives:** Pasivas de equipo en conditions necesitan entries separadas

---

## 7. Checklist para Futuras Actualizaciones

Al agregar sync pairs de una nueva actualización del juego:

### Fase 1: Importación de datos

- [ ] Ejecutar herramientas de importación desde docs
- [ ] Verificar que no haya errores de parseo en nombres raros (emojis, asteriscos)

### Fase 2: Damage Passives

- [ ] Ejecutar: `python tools/fix_damage_passives.py`
- [ ] Si hay referencias rotas, investigar cada una:
  - ¿Es una pasiva de grid expand?
  - ¿Es una pasiva de equipo en weather/terrain/zone?
  - ¿Es un modifier de sync move?
- [ ] Verificar que las nuevas entradas tengan la estructura correcta (type, applies_to, affects, conditions)
- [ ] Para pasivas de equipo: crear 3 variantes (Moves, Sync, DR)

### Fase 3: Master Passives

- [ ] Si hay nuevos Champion/Arc Suit/Master Fair:
  - Agregar entrada a `master_passives.json`
  - **Importante:** `syncPair` debe coincidir EXACTAMENTE con `displayName`
- [ ] Ejecutar: `python tools/fix_champion_master_passives.py`
- [ ] Verificar que los nuevos pares tengan el campo `masterPassives`

### Fase 4: Extended Range

- [ ] Ejecutar: `python tools/fix_extended_range.py`
- [ ] Verificar 59/59 movimientos con isExtendedRange=true

### Fase 5: Verificación final

- [ ] Ejecutar verificación de referencias:
  ```python
  python -c "
  import json
  with open('assets/data/damage_passives.json') as f: dp = json.load(f)
  with open('assets/data/sync_pairs.json') as f: pairs = json.load(f)
  names = {e['name'] for e in dp}
  refs = set()
  for p in pairs:
      for d in p.get('damagePassives', []): refs.add(d['name'])
  missing = refs - names
  print(f'OK: {len(refs)} refs, {len(missing)} missing')
  for m in sorted(missing): print(f'  MISSING: {m}')
  "
  ```
- [ ] Verificar que `0 missing`

### Fase 6: Commit

- [ ] `git add assets/data/ tools/`
- [ ] `git commit -m "Update to vX.XX: sync pairs, damage passives, master passives, extended range"`

---

## Historial de Correcciones

| Fecha | Versión | Archivos modificados | Cambios |
|------|---------|---------------------|---------|
| Jun 2026 | 2.63-2.69 | `damage_passives.json` | +5 entradas nuevas para referencias rotas |
| Jun 2026 | 2.63-2.69 | `sync_pairs.json` | +98 masterPassives conectados |
| Jun 2026 | 2.63-2.69 | `master_passives.json` | +2 entradas (Ethan Champion, Lyra Champion) |
| Jun 2026 | 2.66-2.69 | `sync_pairs.json` | +7 isExtendedRange flags |
| Jun 2026 | 2.69 | `damage_passives.json` | +3 Earth-Shaking Roar entries |
| Jun 2026 | 2.69 | `sync_pairs.json` | +3 damagePassives a Ethan Champion |