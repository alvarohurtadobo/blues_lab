import 'package:blues_lab/domain/repositories/pair_super_awakening_repository.dart';

final class LoadPairSuperAwakeningFlags {
  const LoadPairSuperAwakeningFlags(this._repository);

  final PairSuperAwakeningRepository _repository;

  Future<Map<String, int>> call() => _repository.loadAwakeningSkillByGridId();
}
