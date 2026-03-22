import 'package:blues_lab/data/datasources/sync_pair_display_catalog_datasource.dart';
import 'package:blues_lab/domain/entities/sync_pair_display_catalog.dart';
import 'package:blues_lab/domain/repositories/sync_pair_display_catalog_repository.dart';

final class SyncPairDisplayCatalogRepositoryImpl
    implements SyncPairDisplayCatalogRepository {
  const SyncPairDisplayCatalogRepositoryImpl(this._source);

  final SyncPairDisplayCatalogDataSource _source;

  @override
  Future<SyncPairDisplayCatalog> loadForLanguage(String languageCode) =>
      _source.loadForLanguage(languageCode);
}
