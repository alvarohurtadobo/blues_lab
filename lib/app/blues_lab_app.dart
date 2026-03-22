import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:blues_lab/core/router/app_router.dart';
import 'package:blues_lab/data/datasources/pair_grids_asset_datasource.dart';
import 'package:blues_lab/data/datasources/pair_super_awakening_asset_datasource.dart';
import 'package:blues_lab/data/datasources/sync_pair_display_catalog_datasource.dart';
import 'package:blues_lab/data/repositories/pair_grids_repository_impl.dart';
import 'package:blues_lab/data/repositories/pair_super_awakening_repository_impl.dart';
import 'package:blues_lab/data/repositories/sync_pair_display_catalog_repository_impl.dart';
import 'package:blues_lab/domain/repositories/pair_grids_repository.dart';
import 'package:blues_lab/domain/repositories/pair_super_awakening_repository.dart';
import 'package:blues_lab/domain/repositories/sync_pair_display_catalog_repository.dart';
import 'package:blues_lab/domain/usecases/load_official_pair_grids.dart';
import 'package:blues_lab/domain/usecases/load_pair_super_awakening_flags.dart';
import 'package:blues_lab/presentation/cubits/pair_grids_cubit.dart';

/// Lets scrollables and nested viewers react to mouse / trackpad drag (web-first).
final class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class BluesLabApp extends StatelessWidget {
  const BluesLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<PairGridsRepository>(
          create: (_) =>
              const PairGridsRepositoryImpl(PairGridsAssetDataSource()),
        ),
        RepositoryProvider<SyncPairDisplayCatalogRepository>(
          create: (_) => const SyncPairDisplayCatalogRepositoryImpl(
            SyncPairDisplayCatalogDataSource(),
          ),
        ),
        RepositoryProvider<PairSuperAwakeningRepository>(
          create: (_) => const PairSuperAwakeningRepositoryImpl(
            PairSuperAwakeningAssetDataSource(),
          ),
        ),
      ],
      child: BlocProvider(
        create: (context) => PairGridsCubit(
          loadOfficialPairGrids: LoadOfficialPairGrids(
            context.read<PairGridsRepository>(),
          ),
          displayCatalogRepository:
              context.read<SyncPairDisplayCatalogRepository>(),
          loadPairSuperAwakeningFlags: LoadPairSuperAwakeningFlags(
            context.read<PairSuperAwakeningRepository>(),
          ),
        )..load(),
        child: MaterialApp.router(
          title: "Blue's Lab",
          debugShowCheckedModeBanner: false,
          scrollBehavior: const _AppScrollBehavior(),
          routerConfig: appRouter,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
        ),
      ),
    );
  }
}
