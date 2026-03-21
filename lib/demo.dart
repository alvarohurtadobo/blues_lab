// PoMaTools — vista mínima del home (sync grid hexagonal).
//
// Uso rápido en otro proyecto:
//   1. flutter create poma_demo && cd poma_demo
//   2. Sustituye todo el contenido de lib/main.dart por este archivo
//      (o renómbralo a main.dart).
//   3. flutter run
//
// Solo depende de `package:flutter/material.dart`. El JSON está embebido;
// replica reglas de clase/tipo del bundle (kind + target + demo de sync/dmax).

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PoMaHomeDemoApp());
}

// ---------------------------------------------------------------------------
// JSON embebido (basado en pairgrids.representative + 2 celdas demo sync/dmax)
// ---------------------------------------------------------------------------

const String _kEmbeddedPairGrids = r'''
{
  "000000009901": [
    {
      "date": 0,
      "cells": [
        {"position": "AA", "orbs": 5, "custom": [0, 0, 0, 0, 0], "kind": "STAT", "target": "STAT_001", "value": 10, "skill": 0, "level": 1},
        {"position": "AB", "orbs": 120, "custom": [0, 0, 0, 0, 0], "kind": "STAT", "target": "STAT_002", "value": 20, "skill": 0, "level": 1},
        {"position": "AC", "orbs": 36, "custom": [0, 0, 0, 0, 0], "kind": "POWERUP", "target": "75", "value": 3, "skill": 0, "level": 1},
        {"position": "AD", "orbs": 60, "custom": [0, 0, 0, 0, 0], "kind": "MODIFIER", "target": "330", "value": 10, "skill": 0, "level": 2},
        {"position": "AE", "orbs": 96, "custom": [0, 0, 0, 0, 0], "kind": "SKILL", "target": "75", "value": 4, "skill": 1704100, "level": 2},
        {"position": "AF", "orbs": 96, "custom": [0, 0, 0, 0, 0], "kind": "SKILL", "target": "PKMN", "value": 3, "skill": 1301210, "level": 3},
        {"position": "AG", "orbs": 0, "custom": [0, 0, 0, 0, 1], "kind": "LEARN", "target": "PKMN", "value": 19082, "skill": 0, "level": 1},
        {"position": "AH", "orbs": 0, "custom": [60, 0, 0, 60, 0], "kind": "SKILL", "target": "PKMN", "value": 0, "skill": 1601420, "level": 1},
        {"position": "AI", "orbs": 0, "custom": [0, 100, 0, 100, 0], "kind": "SKILL", "target": "19082", "value": 1, "skill": 1501360, "level": 1},
        {"position": "AJ", "orbs": 120, "custom": [0, 0, 0, 0, 0], "kind": "SKILL", "target": "10008", "value": 9, "skill": 1704880, "level": 5},
        {"position": "AK", "orbs": 0, "custom": [0, 0, 0, 0, 0], "kind": "SKILL", "target": "PKMN", "value": 5, "skill": 1905550, "level": 5},
        {"position": "AL", "orbs": 48, "custom": [0, 0, 0, 0, 0], "kind": "POWERUP", "target": "DEMO_SN", "value": 5, "skill": 0, "level": 1},
        {"position": "AM", "orbs": 72, "custom": [0, 0, 0, 0, 0], "kind": "SKILL", "target": "7500", "value": 2, "skill": 1, "level": 2}
      ]
    }
  ]
}
''';

// ---------------------------------------------------------------------------
// Modelo mínimo + layout (misma lógica que el sitio: colStart/rowStart = 65)
// ---------------------------------------------------------------------------

enum CellKind { stat, learn, powerup, modifier, skill }

CellKind _parseKind(String s) {
  switch (s) {
    case 'STAT':
      return CellKind.stat;
    case 'LEARN':
      return CellKind.learn;
    case 'POWERUP':
      return CellKind.powerup;
    case 'MODIFIER':
      return CellKind.modifier;
    case 'SKILL':
      return CellKind.skill;
    default:
      throw FormatException('kind desconocido: $s');
  }
}

class SyncGridCell {
  final String position;
  final int orbs;
  final List<int> custom;
  final CellKind kind;
  final String target;
  final int value;
  final int skill;
  final int level;

  const SyncGridCell({
    required this.position,
    required this.orbs,
    required this.custom,
    required this.kind,
    required this.target,
    required this.value,
    required this.skill,
    required this.level,
  });

  factory SyncGridCell.fromJson(Map<String, dynamic> j) {
    return SyncGridCell(
      position: j['position'] as String,
      orbs: j['orbs'] as int,
      custom: List<int>.from(j['custom'] as List<dynamic>),
      kind: _parseKind(j['kind'] as String),
      target: j['target'] as String,
      value: j['value'] as int,
      skill: j['skill'] as int,
      level: j['level'] as int,
    );
  }

  double get energyCost => orbs < 6 ? 0 : orbs / 12;
}

/// Clases CSS del sitio (determinan color). Incluye `arc` (multi-grid forzado en índices 6–9).
enum TileStyleClass {
  stat,
  learn,
  powerup,
  sync,
  dmax,
  modifier,
  passive,
  arc,
}

extension on TileStyleClass {
  String get label => name;
}

/// Mapeo alineado al `switch` del bundle (sin `moves.json` real: DEMO_SN = sync move).
TileStyleClass resolveTileStyleClass(SyncGridCell c) {
  switch (c.kind) {
    case CellKind.stat:
      return TileStyleClass.stat;
    case CellKind.learn:
      return TileStyleClass.learn;
    case CellKind.modifier:
      return TileStyleClass.powerup;
    case CellKind.powerup:
      if (c.target == 'DEMO_SN') return TileStyleClass.sync;
      // Sin moves.json: 75 y demás se tratan como powerup de movimiento normal.
      return TileStyleClass.powerup;
    case CellKind.skill:
      if (c.target == 'PKMN') return TileStyleClass.passive;
      final u = int.tryParse(c.target) ?? 0;
      if (u > 30000) return TileStyleClass.passive;
      if (u > 6999 && u < 8000) return TileStyleClass.dmax;
      return TileStyleClass.modifier;
  }
}

/// Colores (--bs-tile-* del CSS compilado).
class TilePalette {
  static const stat = Color(0xFF568DD0);
  static const learn = Color(0xFF6AD3F3);
  static const powerup = Color(0xFF4AB797);
  static const sync = Color(0xFF8974C3);
  static const dmax = Color(0xFFE17DB9);
  static const modifier = Color(0xFFE1768A);
  static const passive = Color(0xFFE5CE5E);
  static const arc = Color(0xFFFFF4BC);

  static Color fill(TileStyleClass c) {
    switch (c) {
      case TileStyleClass.stat:
        return stat;
      case TileStyleClass.learn:
        return learn;
      case TileStyleClass.powerup:
        return powerup;
      case TileStyleClass.sync:
        return sync;
      case TileStyleClass.dmax:
        return dmax;
      case TileStyleClass.modifier:
        return modifier;
      case TileStyleClass.passive:
        return passive;
      case TileStyleClass.arc:
        return arc;
    }
  }

  static Color dark(TileStyleClass c) {
    switch (c) {
      case TileStyleClass.stat:
        return const Color(0xFF18529C);
      case TileStyleClass.learn:
        return const Color(0xFF2DA6B7);
      case TileStyleClass.powerup:
        return const Color(0xFF056E50);
      case TileStyleClass.sync:
        return const Color(0xFF432D7F);
      case TileStyleClass.dmax:
        return const Color(0xFFA6186C);
      case TileStyleClass.modifier:
        return const Color(0xFFA7364A);
      case TileStyleClass.passive:
        return const Color(0xFF907500);
      case TileStyleClass.arc:
        return const Color(0xFF7D765A);
    }
  }
}

class PlacedTile {
  final int index;
  final SyncGridCell cell;
  final int gridI;
  final int gridJ;
  final double x;
  final double y;
  final TileStyleClass styleClass;

  PlacedTile({
    required this.index,
    required this.cell,
    required this.gridI,
    required this.gridJ,
    required this.x,
    required this.y,
    required this.styleClass,
  });
}

List<PlacedTile> loadDemoTiles() {
  const colStart = 65;
  const rowStart = 65;
  final root = jsonDecode(_kEmbeddedPairGrids) as Map<String, dynamic>;
  final pair = root.values.first as List<dynamic>;
  final revision = pair.first as Map<String, dynamic>;
  final cells = revision['cells'] as List<dynamic>;

  final out = <PlacedTile>[];
  for (var i = 0; i < cells.length; i++) {
    final c = SyncGridCell.fromJson(cells[i] as Map<String, dynamic>);
    if (c.position.length != 2) continue;
    final gi = c.position.codeUnitAt(0) - colStart;
    final gj = c.position.codeUnitAt(1) - rowStart;
    final x = 46.0 * gi;
    final y = 52.0 * gj + (gi.isOdd ? 26.0 : 0.0);
    final cls = resolveTileStyleClass(c);
    out.add(PlacedTile(
      index: i,
      cell: c,
      gridI: gi,
      gridJ: gj,
      x: x,
      y: y,
      styleClass: cls,
    ));
  }
  return out;
}

/// Cuatro hexágonos estilo `arc` (multi-grid en el sitio fuerza clase arc en índices 6–9).
List<PlacedTile> arcOverlayTiles(List<PlacedTile> base) {
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
      kind: CellKind.skill,
      target: 'PKMN',
      value: 0,
      skill: 0,
      level: 1,
    );
    return PlacedTile(
      index: 1000 + k,
      cell: dummy,
      gridI: gi,
      gridJ: -1,
      x: x,
      y: y,
      styleClass: TileStyleClass.arc,
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
  late final List<PlacedTile> _tiles;
  final Set<int> _selected = {};
  double _syncLevel = 3;
  double _energyBudget = 24;
  bool _energyCap = true;
  bool _showArcDemo = true;

  @override
  void initState() {
    super.initState();
    _tiles = loadDemoTiles();
  }

  List<PlacedTile> get _visibleTiles {
    final list = List<PlacedTile>.from(_tiles);
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
            child: LayoutBuilder(
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

  final List<PlacedTile> tiles;
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

    final scale = math.min(
      viewportSize.width / contentW,
      viewportSize.height / contentH,
    ).clamp(0.45, 1.8);

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

  final PlacedTile placed;
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
      message: '${c.kind.name.toUpperCase()} · ${placed.styleClass.label}\n'
          'pos ${c.position} · lvl ${c.level} · orbs ${c.orbs} · energía ${c.energyCost.toStringAsFixed(1)}',
      child: GestureDetector(
        onTap: onTap,
        child: CustomPaint(
          painter: _HexPainter(
            fill: TilePalette.fill(placed.styleClass),
            stroke: TilePalette.dark(placed.styleClass),
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
                  color: locked ? Colors.white54 : Colors.white.withOpacity(0.95),
                ),
                const SizedBox(height: 2),
                Text(
                  c.position,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: locked ? Colors.white38 : Colors.white.withOpacity(1),
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

IconData _iconFor(TileStyleClass c) {
  switch (c) {
    case TileStyleClass.stat:
      return Icons.bar_chart_rounded;
    case TileStyleClass.learn:
      return Icons.menu_book_rounded;
    case TileStyleClass.powerup:
      return Icons.bolt_rounded;
    case TileStyleClass.sync:
      return Icons.auto_awesome;
    case TileStyleClass.dmax:
      return Icons.hub_rounded;
    case TileStyleClass.modifier:
      return Icons.tune_rounded;
    case TileStyleClass.passive:
      return Icons.pets_rounded;
    case TileStyleClass.arc:
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
      ..color = locked ? fill.withOpacity(0.35) : fill;
    if (dimmed) {
      paintFill.color = paintFill.color.withOpacity(paintFill.color.opacity * 0.45);
    }
    canvas.drawPath(path, paintFill);

    final paintStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 3 : 1.5
      ..color = selected ? Colors.white : stroke.withOpacity(0.9);
    canvas.drawPath(path, paintStroke);

    if (locked) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.black.withOpacity(0.45),
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
