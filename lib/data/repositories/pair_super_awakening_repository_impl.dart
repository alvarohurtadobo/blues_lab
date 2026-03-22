import 'package:blues_lab/data/datasources/pair_super_awakening_asset_datasource.dart';
import 'package:blues_lab/domain/repositories/pair_super_awakening_repository.dart';

final class PairSuperAwakeningRepositoryImpl
    implements PairSuperAwakeningRepository {
  const PairSuperAwakeningRepositoryImpl(this._source);

  final PairSuperAwakeningAssetDataSource _source;

  @override
  Future<Map<String, int>> loadAwakeningSkillByGridId() =>
      _source.loadAwakeningSkillByGridId();
}
