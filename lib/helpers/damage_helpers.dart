import '../damage/calc.dart';
import '../models/sync_pair_models.dart';
import '../star_level.dart';

String calcScaledPower(String rawPower, int moveLevel, [int saBonus = 0]) {
  final match = RegExp(r'^(\d+)').firstMatch(rawPower);
  if (match == null) return rawPower;
  final base = int.parse(match.group(1)!);
  return '${(base * (100 + (moveLevel - 1) * 5 + saBonus) / 100).floor()}';
}

int calcSaBonus(SyncPairData pair, int saLevel, MoveData move) {
  return pair.hasSuperAwakening
      ? saMovePowerBonus(saLevel, pair.role, isSync: move.isSync)
      : 0;
}

int calcOverviewStat({
  required int baseStat,
  required Map<String, int> potentialBonus,
  required int exBonus,
  required double formMult,
  required String stat,
  required bool hasSA,
  required int saLevel,
  required String role,
}) {
  var base = baseStat;
  if (hasSA && saLevel >= 1) {
    base = (base * 1.1).ceil();
  }
  if (hasSA && role.toLowerCase().trim() == 'support') {
    base += saSupportFlatBonus(saLevel)[stat] ?? 0;
  }
  final beforeForm = base + (potentialBonus[stat] ?? 0) + exBonus;
  if (formMult == 1.0) return beforeForm;
  return (beforeForm * formMult).ceil() - 1;
}

int calcTotalStatCalc(
  String stat,
  int jsonStat,
  int stage, {
  int potential = 0,
  int exBonusVal = 0,
  double formMult = 1.0,
  bool hasSA = false,
  int saLevel = 0,
  String role = '',
  int gear = 0,
  int gridStat = 0,
  double varMult = 1.0,
}) {
  var base = jsonStat;
  if (hasSA && saLevel >= 1) {
    base = (base * 1.1).ceil();
  }
  if (hasSA && role.toLowerCase().trim() == 'support') {
    base += saSupportFlatBonus(saLevel)[stat] ?? 0;
  }
  final rawBase = base + potential + exBonusVal;
  final afterMult = _applyMult(rawBase + gear, formMult, stat);
  final afterVar = varMult == 1.0 ? afterMult : (afterMult * varMult).floor();
  return floorToInt(
    (afterVar + gridStat) * statVariation(stage, isSpeed: stat == 'spe'),
  );
}

int _applyMult(int value, double mult, String stat) {
  if (mult == 1.0) return value;
  return (value * mult).ceil() - 1;
}
