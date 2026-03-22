/// `gridId` keys match `pairgrids.json` and the selected pair id in the grids UI.
abstract interface class PairSuperAwakeningRepository {
  /// [awakeningSkill] from `pairs.json`; `0` when the pair has no super awakening.
  Future<Map<String, int>> loadAwakeningSkillByGridId();
}
