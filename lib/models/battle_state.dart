import 'combatant_state.dart';
import 'field_state.dart';
import 'sync_pair_models.dart';

class BattleState {
  CombatantState ally;
  CombatantState enemy;
  FieldState field;

  BattleState({
    required this.ally,
    required this.enemy,
    required this.field,
  });

  factory BattleState.initial(SyncPairData pair) => BattleState(
        ally: CombatantState.ally(pair),
        enemy: CombatantState.enemy(),
        field: FieldState(),
      );
}
