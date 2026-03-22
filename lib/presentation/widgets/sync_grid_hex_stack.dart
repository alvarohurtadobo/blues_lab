import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:blues_lab/domain/value_objects/sync_grid_tile_style.dart';
import 'package:blues_lab/presentation/models/placed_sync_tile.dart';
import 'package:blues_lab/presentation/theme/sync_grid_tile_palette.dart';

/// Hex path (60×52 SVG control points from PoMaTools).
Path syncGridHexPath(Size size) {
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

IconData syncGridHexIconFor(SyncGridTileStyleClass c) {
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

/// Interactive scaled stack of hex tiles (pan/zoom handled by an [InteractiveViewer] parent).
class SyncGridHexStack extends StatelessWidget {
  const SyncGridHexStack({
    super.key,
    required this.tiles,
    required this.selected,
    required this.syncLevel,
    required this.energyBudget,
    required this.energyCap,
    required this.viewportSize,
    required this.onTileToggle,
    this.emptyMessage = 'No tiles',
  });

  final List<PlacedSyncTile> tiles;
  final Set<int> selected;
  final int syncLevel;
  final double energyBudget;
  final bool energyCap;
  final Size viewportSize;
  final void Function(int index) onTileToggle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (tiles.isEmpty) {
      return Center(child: Text(emptyMessage));
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
                child: SyncGridHexTile(
                  placed: t,
                  selected: selected.contains(t.index),
                  syncLevel: syncLevel,
                  energyBudget: energyBudget,
                  energyCap: energyCap,
                  onTap: () => onTileToggle(t.index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SyncGridHexTile extends StatelessWidget {
  const SyncGridHexTile({
    super.key,
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
    final overEnergy =
        energyCap && !selected && c.energyCost > energyBudget && c.energyCost > 0;

    return Tooltip(
      message: '${c.kind.wire} · ${placed.styleClass.label}\n'
          'pos ${c.position} · lvl ${c.level} · orbs ${c.orbs} · energy ${c.energyCost.toStringAsFixed(1)}',
      child: GestureDetector(
        onTap: onTap,
        child: CustomPaint(
          painter: _SyncGridHexPainter(
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
                  syncGridHexIconFor(placed.styleClass),
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

class _SyncGridHexPainter extends CustomPainter {
  _SyncGridHexPainter({
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
    final path = syncGridHexPath(size);
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
  bool shouldRepaint(covariant _SyncGridHexPainter oldDelegate) {
    return oldDelegate.fill != fill ||
        oldDelegate.selected != selected ||
        oldDelegate.locked != locked ||
        oldDelegate.dimmed != dimmed;
  }
}
