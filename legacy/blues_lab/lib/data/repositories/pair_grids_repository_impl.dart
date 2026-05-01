import 'package:blues_lab/core/constants/app_constants.dart';
import 'package:blues_lab/data/datasources/pair_grids_asset_datasource.dart';
import 'package:blues_lab/domain/entities/pair_grids_map.dart';
import 'package:blues_lab/domain/repositories/pair_grids_repository.dart';

final class PairGridsRepositoryImpl implements PairGridsRepository {
  const PairGridsRepositoryImpl(this._dataSource);

  final PairGridsAssetDataSource _dataSource;

  @override
  Future<PairGridsMap> loadOfficialPairGrids() {
    return _dataSource.loadMap(AppConstants.officialPairGridsAssetPath);
  }
}
