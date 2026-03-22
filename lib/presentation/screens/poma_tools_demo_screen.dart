// PoMaTools — minimal home-style sync grid (hex layout).
//
// Demo data: `assets/data/demo/`. Production JSON: `assets/data/` and `assets/i18n/`.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:blues_lab/core/constants/app_constants.dart';
import 'package:blues_lab/data/datasources/pair_grids_asset_datasource.dart';
import 'package:blues_lab/domain/entities/sync_grid_cell.dart';
import 'package:blues_lab/domain/entities/sync_grid_cell_kind.dart';
import 'package:blues_lab/domain/value_objects/sync_grid_tile_style.dart';
import 'package:blues_lab/presentation/models/placed_sync_tile.dart';
import 'package:blues_lab/presentation/sync_grid/sync_grid_hex_layout.dart';
import 'package:blues_lab/presentation/widgets/sync_grid_hex_stack.dart';

/// First pair / first revision from the demo asset, laid out as hex tiles.
Future<List<PlacedSyncTile>> loadDemoPlacedTiles() async {
  const ds = PairGridsAssetDataSource();
  final map = await ds.loadMap(AppConstants.pairGridsDemoAssetPath);
  if (map.isEmpty) return [];
  final revisions = map.values.first;
  if (revisions.isEmpty) return [];
  return SyncGridHexLayout.tilesFromRevision(revisions.first);
}

/// Four `arc`-style hex tiles (multi-grid on web forces arc class at indices 6–9).
List<PlacedSyncTile> arcOverlayTiles(List<PlacedSyncTile> base) {
  if (base.isEmpty) return const [];
  var maxY = 0.0;
  var minX = double.infinity;
  for (final t in base) {
    maxY = math.max(maxY, t.y);
    minX = math.min(minX, t.x);
  }
  const dy = 70.0;
  final y0 = maxY + dy;
  final x0 = minX;
  return List.generate(4, (k) {
    final gi = k;
    final x = x0 + 46.0 * gi;
    final y = y0 + (gi.isOdd ? 26.0 : 0.0);
    final dummy = SyncGridCell(
      position: 'N${String.fromCharCode(48 + k)}',
      orbs: 0,
      custom: [0, 0, 0, 0, 0],
      kind: SyncGridCellKind.skill,
      target: 'PKMN',
      value: 0,
      skill: 0,
      level: 1,
    );
    return PlacedSyncTile(
      index: 1000 + k,
      cell: dummy,
      gridI: gi,
      gridJ: -1,
      x: x,
      y: y,
      styleClass: SyncGridTileStyleClass.arc,
    );
  });
}

/// Standalone app shell for the PoMa hex demo (optional entry).
class PoMaHomeDemoApp extends StatelessWidget {
  const PoMaHomeDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PoMa Grid demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF4855)),
        useMaterial3: true,
      ),
      home: const PoMaHomePage(),
    );
  }
}

class PoMaHomePage extends StatefulWidget {
  const PoMaHomePage({super.key});

  @override
  State<PoMaHomePage> createState() => _PoMaHomePageState();
}

class _PoMaHomePageState extends State<PoMaHomePage> {
  List<PlacedSyncTile> _tiles = [];
  Object? _loadError;
  final Set<int> _selected = {};
  double _syncLevel = 3;
  double _energyBudget = 24;
  bool _energyCap = true;
  bool _showArcDemo = true;

  @override
  void initState() {
    super.initState();
    _loadTiles();
  }

  Future<void> _loadTiles() async {
    try {
      final tiles = await loadDemoPlacedTiles();
      if (!mounted) return;
      setState(() {
        _tiles = tiles;
        _loadError = null;
      });
    } catch (e, st) {
      debugPrint('Failed to load ${AppConstants.pairGridsDemoAssetPath}: $e\n$st');
      if (!mounted) return;
      setState(() => _loadError = e);
    }
  }

  List<PlacedSyncTile> get _visibleTiles {
    final list = List<PlacedSyncTile>.from(_tiles);
    if (_showArcDemo) list.addAll(arcOverlayTiles(_tiles));
    return list;
  }

  void _toggle(int index) {
    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
      } else {
        _selected.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PoMaTools · demo grid'),
        backgroundColor: const Color(0xFFFF4855),
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.catching_pokemon, size: 40),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sync grid (hex). Tap tiles. Adjust sync level and energy like the home screen.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sync level: ${_syncLevel.round()}'),
                Slider(
                  value: _syncLevel,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: '${_syncLevel.round()}',
                  onChanged: (v) => setState(() => _syncLevel = v),
                ),
                Text('Energy budget: ${_energyBudget.toStringAsFixed(1)}'),
                Slider(
                  value: _energyBudget,
                  min: 0,
                  max: 40,
                  onChanged: (v) => setState(() => _energyBudget = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Dim tiles that exceed energy budget (ENERGY_CAP-style)'),
                  value: _energyCap,
                  onChanged: (v) => setState(() => _energyCap = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Show “arc” slots (indices 6–9, multi-grid)'),
                  value: _showArcDemo,
                  onChanged: (v) => setState(() => _showArcDemo = v),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loadError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Could not load demo JSON.\n'
                        'Run `flutter pub get` and ensure ${AppConstants.pairGridsDemoAssetPath} exists.\n\n$_loadError',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return InteractiveViewer(
                        boundaryMargin: const EdgeInsets.all(120),
                        minScale: 0.35,
                        maxScale: 3.5,
                        child: SyncGridHexStack(
                          tiles: _visibleTiles,
                          selected: _selected,
                          syncLevel: _syncLevel.round(),
                          energyBudget: _energyBudget,
                          energyCap: _energyCap,
                          viewportSize: Size(constraints.maxWidth, constraints.maxHeight),
                          onTileToggle: _toggle,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
