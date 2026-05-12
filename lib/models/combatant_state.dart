import 'sync_pair_models.dart';

class CombatantState {
  static const List<String> statLabels = ['hp', 'atk', 'def', 'spa', 'spd', 'spe'];

  static const List<String> circleRegions = [
    'Kanto', 'Johto', 'Hoenn', 'Sinnoh', 'Unova',
    'Kalos', 'Alola', 'Galar', 'Paldea', 'Pasio',
  ];

  static const List<String> allTypes = [
    'Normal', 'Fire', 'Water', 'Grass', 'Electric', 'Ice',
    'Fighting', 'Poison', 'Ground', 'Flying', 'Psychic', 'Bug',
    'Rock', 'Ghost', 'Dragon', 'Dark', 'Steel', 'Fairy',
  ];

  static const Map<String, int> enemyDefaults = {
    'hp': 1958000,
    'atk': 5400,
    'def': 95,
    'spa': 5400,
    'spd': 95,
    'spe': 72,
    'acc': 0,
    'eva': 0,
  };

  // Core pair data (null for enemy without an assigned pair)
  SyncPairData? pair;

  // Ally identity / form
  String charLevel;
  String starLevel;
  bool hasExRole;
  int formIndex;

  // Battle state — both sides
  Map<String, int> stages;
  String statusCondition;
  Map<String, bool> volatileStatus;
  int hpPercent;
  int syncBoosts;

  // Side-specific field effect
  bool moveGaugeAccel;

  // Ally-only: move damage modifiers
  bool isCriticalMove;
  int physicalBoostNext;
  int specialBoostNext;
  bool superEffectiveNext;
  bool physicalBreak;
  bool specialBreak;
  int syncMoveBoostNext;

  // Ally-only: equipment and circles
  Map<String, int> gear;
  Map<String, Map<String, bool>> circleActive;
  Map<String, int> circleAllyCount;
  Map<String, int> masterPassiveAllyCount;

  // Ally-only: selected lucky skill (damage-modifying passive from lucky cookies)
  DamagePassive? luckySkill;

  // Ally-only: cheer multiplier (×1.5 on final damage)
  bool cheer;

  // Ally-only: user-side type rebuffs (-3 to +3 per type)
  Map<String, int> userTypeRebuffs;

  // Enemy-only: manual stats and damage reduction
  Map<String, int> manualStats;
  String weakness;
  Map<String, int> typeRebuffs;
  int stellarRebuff;
  Map<String, int> mitigations;

  // Enemy-only: active damage field (type name, e.g. 'Poison', or empty)
  String damageField;

  CombatantState({
    this.pair,
    this.charLevel = '200',
    this.starLevel = '5★ EX',
    this.hasExRole = true,
    this.formIndex = 0,
    Map<String, int>? stages,
    this.statusCondition = '',
    Map<String, bool>? volatileStatus,
    this.hpPercent = 100,
    this.syncBoosts = 0,
    this.moveGaugeAccel = false,
    this.isCriticalMove = true,
    this.physicalBoostNext = 0,
    this.specialBoostNext = 0,
    this.superEffectiveNext = false,
    this.physicalBreak = false,
    this.specialBreak = false,
    this.syncMoveBoostNext = 0,
    Map<String, int>? gear,
    Map<String, Map<String, bool>>? circleActive,
    Map<String, int>? circleAllyCount,
    Map<String, int>? masterPassiveAllyCount,
    this.cheer = false,
    Map<String, int>? userTypeRebuffs,
    Map<String, int>? manualStats,
    this.weakness = '',
    Map<String, int>? typeRebuffs,
    this.stellarRebuff = 0,
    Map<String, int>? mitigations,
    this.damageField = '',
  })  : stages = stages ?? {for (final s in statLabels) s: 0},
        volatileStatus = volatileStatus ??
            {'confused': false, 'flinching': false, 'trapped': false, 'restrained': false},
        gear = gear ?? {},
        circleActive = circleActive ?? {},
        circleAllyCount = circleAllyCount ?? {},
        masterPassiveAllyCount = masterPassiveAllyCount ?? {},
        manualStats = manualStats ?? {...enemyDefaults},
        userTypeRebuffs = userTypeRebuffs ?? {for (final t in allTypes) t: 0},
        typeRebuffs = typeRebuffs ?? {for (final t in allTypes) t: 0},
        mitigations = mitigations ?? {'atk': 5, 'def': 5, 'spa': 5, 'spd': 5, 'spe': 5};

  factory CombatantState.ally(SyncPairData pair) => CombatantState(
        pair: pair,
        stages: {
          'hp': 0, 'atk': 6, 'def': 6, 'spa': 6, 'spd': 6,
          'spe': 6, 'acc': 6, 'eva': 6, 'crit': 3,
        },
        gear: {for (final s in statLabels) s: 100},
        circleActive: {
          for (final r in circleRegions)
            r: {'physical': false, 'special': false, 'defensive': false},
        },
        circleAllyCount: {for (final r in circleRegions) r: 0},
        masterPassiveAllyCount: {},
        manualStats: {},
      );

  factory CombatantState.enemy() => CombatantState(
        isCriticalMove: false,
        stages: {
          'hp': 0, 'atk': -6, 'def': -6, 'spa': -6,
          'spd': -6, 'spe': -6, 'acc': -6, 'eva': -6,
        },
      );
}
