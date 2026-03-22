// PoMaTools — vista mínima del home (sync grid hexagonal).
//
// Los datos de demo viven en `assets/data/demo/`; el resto de JSON en `assets/data/`
// del sitio original está en `assets/data/` e `assets/i18n/`.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:blues_lab/core/constants/app_constants.dart';
import 'package:blues_lab/data/datasources/pair_grids_asset_datasource.dart';
import 'package:blues_lab/domain/entities/sync_grid_cell.dart';
import 'package:blues_lab/domain/entities/sync_grid_cell_kind.dart';
import 'package:blues_lab/domain/value_objects/sync_grid_tile_style.dart';
import 'package:blues_lab/presentation/models/placed_sync_tile.dart';
import 'package:blues_lab/presentation/theme/sync_grid_tile_palette.dart';

const int _kColStart = 65;
const int _kRowStart = 65;

/// Primera revisión del primer par del mapa cargado, proyectada al layout hex.
Future<List<PlacedSyncTile>> loadDemoPlacedTiles() async {
  const ds = PairGridsAssetDataSource();
  final map = await ds.loadMap(AppConstants.pairGridsDemoAssetPath);
  if (map.isEmpty) return [];
  final revisions = map.values.first;
  if (revisions.isEmpty) return [];
  final cells = revisions.first.cells;

  final out = <PlacedSyncTile>[];
  for (var i = 0; i < cells.length; i++) {
    final c = cells[i];
    if (c.position.length != 2) continue;
    final gi = c.position.codeUnitAt(0) - _kColStart;
    final gj = c.position.codeUnitAt(1) - _kRowStart;
    final x = 46.0 * gi;
    final y = 52.0 * gj + (gi.isOdd ? 26.0 : 0.0);
    final cls = resolveSyncGridTileStyleClass(c);
    out.add(
      PlacedSyncTile(
        index: i,
        cell: c,
        gridI: gi,
        gridJ: gj,
        x: x,
        y: y,
        styleClass: cls,
      ),
    );
  }
  return out;
}

/// Cuatro hexágonos estilo `arc` (multi-grid en el sitio fuerza clase arc en índices 6–9).
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

// ---------------------------------------------------------------------------
// Pintura hex (mismos puntos relativos que el SVG 60×52 del sitio)
// ---------------------------------------------------------------------------

Path hexPath(Size size) {
  const srcW = 60.0;
  const srcH = 52.0;
  const pts = <Offset>[
    Offset(1, 26),
    Offset(15, 51),
    Offset(45, 51),
    Offset(59, 26),
    Offset(45, 1),
    Offset(15, 1),
  ];
  final sx = size.width / srcW;
  final sy = size.height / srcH;
  final p = Path()..moveTo(pts[0].dx * sx, pts[0].dy * sy);
  for (var k = 1; k < pts.length; k++) {
    p.lineTo(pts[k].dx * sx, pts[k].dy * sy);
  }
  p.close();
  return p;
}

// ---------------------------------------------------------------------------
// App
// ---------------------------------------------------------------------------

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
      debugPrint('Error cargando ${AppConstants.pairGridsDemoAssetPath}: $e\n$st');
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
                    'Sync grid (hex). Toca casillas. Ajusta nivel sync y energía como en el home.',
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
                Text('Nivel sync: ${_syncLevel.round()}'),
                Slider(
                  value: _syncLevel,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: '${_syncLevel.round()}',
                  onChanged: (v) => setState(() => _syncLevel = v),
                ),
                Text('Presupuesto energía: ${_energyBudget.toStringAsFixed(1)}'),
                Slider(
                  value: _energyBudget,
                  min: 0,
                  max: 40,
                  onChanged: (v) => setState(() => _energyBudget = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Oscurecer si supera límite de energía (como ENERGY_CAP)'),
                  value: _energyCap,
                  onChanged: (v) => setState(() => _energyCap = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mostrar slots “arc” (índices 6–9, multi-grid)'),
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
                        'No se pudo cargar el JSON de demo.\n'
                        'Ejecuta `flutter pub get` y comprueba que exista ${AppConstants.pairGridsDemoAssetPath}.\n\n$_loadError',
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
                        child: _GridLayer(
                          tiles: _visibleTiles,
                          selected: _selected,
                          syncLevel: _syncLevel.round(),
                          energyBudget: _energyBudget,
                          energyCap: _energyCap,
                          viewportSize: Size(constraints.maxWidth, constraints.maxHeight),
                          onToggle: _toggle,
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

class _GridLayer extends StatelessWidget {
  const _GridLayer({
    required this.tiles,
    required this.selected,
    required this.syncLevel,
    required this.energyBudget,
    required this.energyCap,
    required this.viewportSize,
    required this.onToggle,
  });

  final List<PlacedSyncTile> tiles;
  final Set<int> selected;
  final int syncLevel;
  final double energyBudget;
  final bool energyCap;
  final Size viewportSize;
  final void Function(int index) onToggle;

  @override
  Widget build(BuildContext context) {
    if (tiles.isEmpty) {
      return const Center(child: Text('Sin celdas'));
    }

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;
    const hexW = 60.0;
    const hexH = 52.0;
    for (final t in tiles) {
      minX = math.min(minX, t.x);
      minY = math.min(minY, t.y);
      maxX = math.max(maxX, t.x + hexW);
      maxY = math.max(maxY, t.y + hexH);
    }
    final contentW = maxX - minX + 80;
    final contentH = maxY - minY + 80;
    final padL = 40 - minX;
    final padT = 40 - minY;

    final scale = math
        .min(
          math.min(viewportSize.width / contentW, viewportSize.height / contentH),
          1.8,
        )
        .clamp(0.45, 1.8);

    return Center(
      child: SizedBox(
        width: contentW * scale,
        height: contentH * scale,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (final t in tiles)
              Positioned(
                left: (padL + t.x) * scale,
                top: (padT + t.y) * scale,
                width: hexW * scale,
                height: hexH * scale,
                child: _HexTile(
                  placed: t,
                  selected: selected.contains(t.index),
                  syncLevel: syncLevel,
                  energyBudget: energyBudget,
                  energyCap: energyCap,
                  onTap: () => onToggle(t.index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HexTile extends StatelessWidget {
  const _HexTile({
    required this.placed,
    required this.selected,
    required this.syncLevel,
    required this.energyBudget,
    required this.energyCap,
    required this.onTap,
  });

  final PlacedSyncTile placed;
  final bool selected;
  final int syncLevel;
  final double energyBudget;
  final bool energyCap;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = placed.cell;
    final locked = c.level > syncLevel;
    final overEnergy = energyCap && !selected && c.energyCost > energyBudget && c.energyCost > 0;

    return Tooltip(
      message: '${c.kind.wire} · ${placed.styleClass.label}\n'
          'pos ${c.position} · lvl ${c.level} · orbs ${c.orbs} · energía ${c.energyCost.toStringAsFixed(1)}',
      child: GestureDetector(
        onTap: onTap,
        child: CustomPaint(
          painter: _HexPainter(
            fill: SyncGridTilePalette.fill(placed.styleClass),
            stroke: SyncGridTilePalette.dark(placed.styleClass),
            selected: selected,
            locked: locked,
            dimmed: overEnergy,
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _iconFor(placed.styleClass),
                  size: 18,
                  color: locked ? Colors.white54 : Colors.white.withValues(alpha: 0.95),
                ),
                const SizedBox(height: 2),
                Text(
                  c.position,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: locked ? Colors.white38 : Colors.white.withValues(alpha: 1),
                    shadows: const [Shadow(blurRadius: 2, color: Colors.black45)],
                  ),
                ),
                if (locked)
                  const Text(
                    '🔒',
                    style: TextStyle(fontSize: 10),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData _iconFor(SyncGridTileStyleClass c) {
  switch (c) {
    case SyncGridTileStyleClass.stat:
      return Icons.bar_chart_rounded;
    case SyncGridTileStyleClass.learn:
      return Icons.menu_book_rounded;
    case SyncGridTileStyleClass.powerup:
      return Icons.bolt_rounded;
    case SyncGridTileStyleClass.sync:
      return Icons.auto_awesome;
    case SyncGridTileStyleClass.dmax:
      return Icons.hub_rounded;
    case SyncGridTileStyleClass.modifier:
      return Icons.tune_rounded;
    case SyncGridTileStyleClass.passive:
      return Icons.pets_rounded;
    case SyncGridTileStyleClass.arc:
      return Icons.star_outline_rounded;
  }
}

class _HexPainter extends CustomPainter {
  _HexPainter({
    required this.fill,
    required this.stroke,
    required this.selected,
    required this.locked,
    required this.dimmed,
  });

  final Color fill;
  final Color stroke;
  final bool selected;
  final bool locked;
  final bool dimmed;

  @override
  void paint(Canvas canvas, Size size) {
    final path = hexPath(size);
    final paintFill = Paint()
      ..style = PaintingStyle.fill
      ..color = locked ? fill.withValues(alpha: 0.35) : fill;
    if (dimmed) {
      paintFill.color =
          paintFill.color.withValues(alpha: paintFill.color.a * 0.45);
    }
    canvas.drawPath(path, paintFill);

    final paintStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 3 : 1.5
      ..color = selected ? Colors.white : stroke.withValues(alpha: 0.9);
    canvas.drawPath(path, paintStroke);

    if (locked) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.black.withValues(alpha: 0.45),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HexPainter oldDelegate) {
    return oldDelegate.fill != fill ||
        oldDelegate.selected != selected ||
        oldDelegate.locked != locked ||
        oldDelegate.dimmed != dimmed;
  }
}
