import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:blues_lab/data/datasources/pair_grids_asset_datasource.dart';
import 'package:blues_lab/data/repositories/pair_grids_repository_impl.dart';
import 'package:blues_lab/domain/repositories/pair_grids_repository.dart';
import 'package:blues_lab/domain/usecases/load_official_pair_grids.dart';
import 'package:blues_lab/presentation/cubits/pair_grids_cubit.dart';
import 'package:blues_lab/presentation/screens/blues_lab_home.dart';

class BluesLabApp extends StatelessWidget {
  const BluesLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<PairGridsRepository>(
      create: (_) => const PairGridsRepositoryImpl(PairGridsAssetDataSource()),
      child: BlocProvider(
        create: (context) => PairGridsCubit(
          loadOfficialPairGrids: LoadOfficialPairGrids(
            context.read<PairGridsRepository>(),
          ),
        )..load(),
        child: MaterialApp(
          title: "Blue's Lab",
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          home: const BluesLabHome(),
        ),
      ),
    );
  }
}
