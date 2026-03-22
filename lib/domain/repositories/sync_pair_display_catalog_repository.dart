import 'package:blues_lab/domain/entities/sync_pair_display_catalog.dart';

abstract interface class SyncPairDisplayCatalogRepository {
  Future<SyncPairDisplayCatalog> loadForLanguage(String languageCode);
}
