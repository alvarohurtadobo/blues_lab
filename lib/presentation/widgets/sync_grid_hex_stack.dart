import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:blues_lab/domain/entities/sync_pair_display_catalog.dart';
import 'package:blues_lab/domain/utils/sync_grid_cell_description.dart';
import 'package:blues_lab/domain/utils/sync_grid_cell_effect_label.dart';
import 'package:blues_lab/domain/value_objects/sync_grid_tile_style.dart';
import 'package:blues_lab/presentation/models/placed_sync_tile.dart';
import 'package:blues_lab/presentation/theme/sync_grid_tile_palette.dart';
import 'package:blues_lab/presentation/widgets/sync_grid_hex_hover_popup.dart';

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

/// Dark outline + soft drop shadow so white labels read like Pokémon Masters EX tiles.
const List<Shadow> _kHexTileLabelShadows = [
  Shadow(offset: Offset(-0.75, -0.75), blurRadius: 0, color: Color(0xD9000000)),
  Shadow(offset: Offset(0.75, -0.75), blurRadius: 0, color: Color(0xD9000000)),
  Shadow(offset: Offset(0.75, 0.75), blurRadius: 0, color: Color(0xD9000000)),
  Shadow(offset: Offset(-0.75, 0.75), blurRadius: 0, color: Color(0xD9000000)),
  Shadow(offset: Offset(0, -1), blurRadius: 0, color: Color(0xC0000000)),
  Shadow(offset: Offset(0, 1), blurRadius: 0, color: Color(0xC0000000)),
  Shadow(offset: Offset(-1, 0), blurRadius: 0, color: Color(0xC0000000)),
  Shadow(offset: Offset(1, 0), blurRadius: 0, color: Color(0xC0000000)),
  Shadow(offset: Offset(0, 1.25), blurRadius: 2.2, color: Color(0x73000000)),
];

/// Prefer the same [Overlay] as the route (needed for [LayerLink]); fall back to root/shell.
OverlayState? _syncGridFindOverlay(BuildContext context) {
  final local = Overlay.maybeOf(context);
  if (local != null) return local;
  final root = Overlay.maybeOf(context, rootOverlay: true);
  if (root != null) return root;
  final navRoot = Navigator.maybeOf(context, rootNavigator: true);
  if (navRoot?.overlay != null) return navRoot!.overlay;
  final nav = Navigator.maybeOf(context);
  return nav?.overlay;
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
    required this.displayCatalog,
    this.emptyMessage = 'No tiles',
  });

  final List<PlacedSyncTile> tiles;
  final Set<int> selected;
  final int syncLevel;
  final double energyBudget;
  final bool energyCap;
  final Size viewportSize;
  final void Function(int index) onTileToggle;
  final SyncPairDisplayCatalog displayCatalog;
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
                  displayCatalog: displayCatalog,
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

class SyncGridHexTile extends StatefulWidget {
  const SyncGridHexTile({
    super.key,
    required this.placed,
    required this.displayCatalog,
    required this.selected,
    required this.syncLevel,
    required this.energyBudget,
    required this.energyCap,
    required this.onTap,
  });

  final PlacedSyncTile placed;
  final SyncPairDisplayCatalog displayCatalog;
  final bool selected;
  final int syncLevel;
  final double energyBudget;
  final bool energyCap;
  final VoidCallback onTap;

  @override
  State<SyncGridHexTile> createState() => _SyncGridHexTileState();
}

class _SyncGridHexTileState extends State<SyncGridHexTile> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  Timer? _showTimer;
  Timer? _hideTimer;

  @override
  void dispose() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _onHoverEnter() {
    _hideTimer?.cancel();
    _showTimer?.cancel();
    _showTimer = Timer(const Duration(milliseconds: 200), _insertOverlay);
  }

  void _onHoverExit() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 280), () {
      if (mounted) _removeOverlay();
    });
  }

  String _footerLine() {
    final c = widget.placed.cell;
    final e = c.energyCost;
    final energyStr =
        e == e.roundToDouble() ? '${e.toInt()}' : e.toStringAsFixed(1);
    return 'Energy: $energyStr - Orbs: ${c.orbs}';
  }

  void _insertOverlay() {
    if (!mounted || _overlayEntry != null) return;
    final overlay = _syncGridFindOverlay(context);
    if (overlay == null) return;

    final c = widget.placed.cell;
    final title = syncGridCellEffectLabel(c, widget.displayCatalog);
    final rawDesc = syncGridCellDescription(c, widget.displayCatalog);
    final description = rawDesc.trim().isNotEmpty && rawDesc.trim() != title.trim()
        ? rawDesc
        : '';
    final footer = _footerLine();

    _overlayEntry = OverlayEntry(
      opaque: false,
      builder: (ctx) {
        // Let pointer events reach hexes that sit *under* the popup (same column below).
        // Otherwise the overlay tooltip steals hover and lower cells never open a popup.
        return IgnorePointer(
          ignoring: true,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            followerAnchor: Alignment.topCenter,
            targetAnchor: Alignment.bottomCenter,
            offset: const Offset(0, 6),
            child: Material(
              type: MaterialType.transparency,
              child: SyncGridHexHoverPopup(
                title: title,
                description: description,
                energyOrbsLine: footer,
                styleClass: widget.placed.styleClass,
                caretPointsUp: true,
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_overlayEntry!);
  }

  String _fallbackTooltipMessage() {
    final c = widget.placed.cell;
    final title = syncGridCellEffectLabel(c, widget.displayCatalog);
    final rawDesc = syncGridCellDescription(c, widget.displayCatalog);
    final desc = rawDesc.trim().isNotEmpty && rawDesc.trim() != title.trim()
        ? '\n\n$rawDesc'
        : '';
    return '$title$desc\n\n${_footerLine()}\n${c.kind.wire} · pos ${c.position} · Lv.${c.level}';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.placed.cell;
    final locked = c.level > widget.syncLevel;
    final overEnergy = widget.energyCap &&
        !widget.selected &&
        c.energyCost > widget.energyBudget &&
        c.energyCost > 0;
    final effectLabel = syncGridCellEffectLabel(c, widget.displayCatalog);
    final overlayAvailable = _syncGridFindOverlay(context) != null;

    Widget tileCore = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: CustomPaint(
        painter: _SyncGridHexPainter(
          fill: SyncGridTilePalette.fill(widget.placed.styleClass),
          stroke: SyncGridTilePalette.dark(widget.placed.styleClass),
          selected: widget.selected,
          locked: locked,
          dimmed: overEnergy,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
          child: Stack(
            alignment: Alignment.center,
            children: [
              IgnorePointer(
                child: Icon(
                  syncGridHexIconFor(widget.placed.styleClass),
                  size: 30,
                  color: locked
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.22),
                ),
              ),
              Text(
                effectLabel,
                textAlign: TextAlign.center,
                softWrap: true,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 6.5,
                  height: 1.14,
                  letterSpacing: -0.05,
                  fontWeight: FontWeight.w700,
                  color: locked
                      ? Colors.white.withValues(alpha: 0.45)
                      : Colors.white,
                  shadows: _kHexTileLabelShadows,
                ),
              ),
              if (locked)
                const Positioned(
                  bottom: -1,
                  child: Text(
                    '🔒',
                    style: TextStyle(fontSize: 7, height: 1),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (overlayAvailable) {
      tileCore = MouseRegion(
        onEnter: (_) => _onHoverEnter(),
        onExit: (_) => _onHoverExit(),
        child: tileCore,
      );
    } else {
      tileCore = Tooltip(
        message: _fallbackTooltipMessage(),
        waitDuration: const Duration(milliseconds: 400),
        showDuration: const Duration(seconds: 12),
        child: tileCore,
      );
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: tileCore,
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
