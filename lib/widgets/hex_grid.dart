import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/sync_pair_models.dart';

class HexGridView extends StatelessWidget {
  const HexGridView({
    super.key,
    required this.cells,
    required this.pairs,
    required this.activeCells,
    required this.onToggleCell,
    required this.onSelectPair,
    required this.moveLevel,
    this.syncMoveName = '',
  });

  final List<GridCellData> cells;
  final List<SyncPairData> pairs;
  final Set<int> activeCells;
  final ValueChanged<int> onToggleCell;
  final ValueChanged<int> onSelectPair;
  final int moveLevel;
  final String syncMoveName;

  @override
  Widget build(BuildContext context) {
    if (cells.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No sync grid available for this pair.',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.55),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final allCells = cells.any((c) => c.q == 0 && c.r == 0 && c.s == 0)
        ? cells
        : [
            const GridCellData(
              cellNumber: -1,
              q: 0,
              r: 0,
              s: 0,
              energyCost: 0,
              orbCost: 0,
              title: '',
              description: '',
              colorKind: '',
            ),
            ...cells,
          ];

    const normHexW = 1.5;
    final normHexH = math.sqrt(3);
    final normCoords = {
      for (final cell in allCells)
        cell.cellNumber: Offset(
          normHexW * cell.q,
          normHexH * (cell.r + cell.q / 2.0),
        ),
    };
    final ncMinX = normCoords.values.map((o) => o.dx).reduce(math.min);
    final ncMinY = normCoords.values.map((o) => o.dy).reduce(math.min);
    final normSpanW =
        normCoords.values.map((o) => o.dx).reduce(math.max) - ncMinX + 2.0;
    final normSpanH =
        normCoords.values.map((o) => o.dy).reduce(math.max) - ncMinY + normHexH;

    return LayoutBuilder(
      builder: (context, constraints) {
        const double pad = 16.0;
        final availW = constraints.maxWidth - pad * 2;
        final availH = constraints.maxHeight - pad * 2;
        final tileRadius = math.min(availW / normSpanW, availH / normSpanH);
        final tileW = tileRadius * 2;
        final tileH = math.sqrt(3) * tileRadius;
        final contentW = normSpanW * tileRadius;
        final contentH = normSpanH * tileRadius;
        final offsetX = pad + (availW - contentW) / 2;
        final offsetY = pad + (availH - contentH) / 2;

        return Stack(
          children: [
            for (final cell in allCells)
              Positioned(
                left:
                    (normCoords[cell.cellNumber]!.dx - ncMinX) * tileRadius +
                    offsetX,
                top:
                    (normCoords[cell.cellNumber]!.dy - ncMinY) * tileRadius +
                    offsetY,
                child: (cell.q == 0 && cell.r == 0 && cell.s == 0)
                    ? GestureDetector(
                        onTap: () => _showPairPicker(context),
                        child: SizedBox(
                          width: tileW,
                          height: tileH,
                          child: Center(
                            child: Image.asset(
                              'assets/img/sync_icon.png',
                              width: tileW,
                              height: tileH,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      )
                    : HoverTooltip(
                        message: _buildCellTooltip(cell),
                        child: Builder(
                          builder: (_) {
                            final colorKind = _isSyncMoveTile(cell)
                                ? '(sync move)'
                                : cell.colorKind;
                            final (activeC, darkC) = _gridColors(colorKind);
                            return HexTile(
                              radius: tileRadius,
                              activeColor: activeC,
                              darkColor: darkC,
                              active: activeCells.contains(cell.cellNumber),
                              locked: cell.moveLevel > moveLevel,
                              label: _buildCellLabel(
                                cell,
                                syncMoveName: syncMoveName,
                              ),
                              onTap: () => onToggleCell(cell.cellNumber),
                            );
                          },
                        ),
                      ),
              ),
          ],
        );
      },
    );
  }

  void _showPairPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _PairPickerDialog(
        pairs: pairs,
        onSelect: (index) {
          Navigator.of(context).pop();
          onSelectPair(index);
        },
      ),
    );
  }

  static String _buildCellTooltip(GridCellData cell) {
    final buffer = StringBuffer();
    if (cell.title.isNotEmpty) {
      buffer.writeln(cell.title);
    }
    if (cell.description.isNotEmpty) {
      buffer.writeln(cell.description);
    }
    buffer.writeln('⚡ ${cell.energyCost}  🔮 ${cell.orbCost}');
    return buffer.toString().trim();
  }

  static String _buildCellLabel(GridCellData cell, {String syncMoveName = ''}) {
    final title = cell.title.trim();
    if (title.isEmpty) {
      return '${cell.cellNumber}';
    }
    if (syncMoveName.isNotEmpty && title.startsWith(syncMoveName)) {
      final rest = title.substring(syncMoveName.length).trim();
      final match = RegExp(
        r':\s*Power\s+(\d+)',
        caseSensitive: false,
      ).firstMatch(rest);
      if (match != null) return 'Sync Move Power +${match.group(1)}';
    }
    return title
        .replaceAllMapped(
          RegExp(r'Move Gauge Refresh\s+(\d+)', caseSensitive: false),
          (match) => 'MGR${match.group(1)}',
        )
        .replaceAllMapped(
          RegExp(r'MP Refresh\s+(\d+)', caseSensitive: false),
          (match) => 'MPR${match.group(1)}',
        );
  }

  static const _tileColors = <String, (Color active, Color dark)>{
    'stat': (Color(0xFF4A90D9), Color(0xFF18529C)),
    'move boost': (Color(0xFF2ECC71), Color(0xFF056E50)),
    'move effect': (Color(0xFFE74C3C), Color(0xFFA7364A)),
    'sync': (Color(0xFF9B59B6), Color(0xFF432D7F)),
    'passive': (Color(0xFFF1C40F), Color(0xFF907500)),
  };

  static (Color, Color) _gridColors(String kind) {
    final n = kind.toLowerCase();
    if (n.contains('(sync move)')) return _tileColors['sync']!;
    if (n.contains('(stat)')) return _tileColors['stat']!;
    if (n.contains('(move boost)')) return _tileColors['move boost']!;
    if (n.contains('(move effect)')) return _tileColors['move effect']!;
    if (n.contains('(passive)')) return _tileColors['passive']!;
    return _tileColors['passive']!;
  }

  bool _isSyncMoveTile(GridCellData cell) {
    if (syncMoveName.isEmpty) return false;
    return cell.title.startsWith(syncMoveName);
  }
}

class _PairPickerDialog extends StatefulWidget {
  const _PairPickerDialog({required this.pairs, required this.onSelect});
  final List<SyncPairData> pairs;
  final ValueChanged<int> onSelect;
  @override
  State<_PairPickerDialog> createState() => _PairPickerDialogState();
}

class _PairPickerDialogState extends State<_PairPickerDialog> {
  String _query = '';
  String _sortMode = 'Release';
  bool _ascending = false;

  static const _typeColors = <String, Color>{
    'normal': Color(0xFFA8A878),
    'fire': Color(0xFFF08030),
    'water': Color(0xFF6890F0),
    'grass': Color(0xFF78C850),
    'electric': Color(0xFFF8D030),
    'ice': Color(0xFF98D8D8),
    'fighting': Color(0xFFC03028),
    'poison': Color(0xFFA040A0),
    'ground': Color(0xFFE0C068),
    'flying': Color(0xFFA890F0),
    'psychic': Color(0xFFF85888),
    'bug': Color(0xFFA8B820),
    'rock': Color(0xFFB8A038),
    'ghost': Color(0xFF705898),
    'dragon': Color(0xFF7038F8),
    'dark': Color(0xFF705848),
    'steel': Color(0xFFB8B8D0),
    'fairy': Color(0xFFEE99AC),
  };

  static String _cleanName(String name) {
    return name
        .replaceAll(RegExp(r'\s*\((Male|Female)[^)]*\)'), '')
        .replaceAll(RegExp(r'\s*\(Genderless\)'), '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.trim().toLowerCase();
    final filtered = <int>[];
    for (int i = 0; i < widget.pairs.length; i++) {
      final p = widget.pairs[i];
      if (normalizedQuery.isEmpty ||
          p.searchTerms.any((t) => t.toLowerCase().contains(normalizedQuery))) {
        filtered.add(i);
      }
    }
    if (_sortMode == 'Name') {
      filtered.sort((a, b) {
        final cmp = widget.pairs[a].displayName.compareTo(
          widget.pairs[b].displayName,
        );
        return _ascending ? cmp : -cmp;
      });
    } else if (_sortMode == 'Release') {
      filtered.sort((a, b) {
        final da = widget.pairs[a].releaseDate;
        final db = widget.pairs[b].releaseDate;
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return _ascending ? da.compareTo(db) : db.compareTo(da);
      });
    } else if (_sortMode == 'Type') {
      filtered.sort((a, b) {
        final cmp = widget.pairs[a].type.compareTo(widget.pairs[b].type);
        return _ascending ? cmp : -cmp;
      });
    } else if (_sortMode == 'Role') {
      filtered.sort((a, b) {
        final cmp = widget.pairs[a].role.compareTo(widget.pairs[b].role);
        return _ascending ? cmp : -cmp;
      });
    }
    return SimpleDialog(
      title: Row(
        children: [
          const Expanded(child: Text('Select character')),
          DropdownButton<String>(
            value: _sortMode,
            isDense: true,
            underline: const SizedBox(),
            style: const TextStyle(fontSize: 12, color: Colors.black),
            items: const [
              DropdownMenuItem(value: 'Release', child: Text('Release')),
              DropdownMenuItem(value: 'Name', child: Text('Name')),
              DropdownMenuItem(value: 'Type', child: Text('Type')),
              DropdownMenuItem(value: 'Role', child: Text('Role')),
            ],
            onChanged: (v) => setState(() => _sortMode = v!),
          ),
          IconButton(
            icon: Icon(
              _ascending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 18,
            ),
            tooltip: _ascending ? 'Ascending' : 'Descending',
            onPressed: () => setState(() => _ascending = !_ascending),
          ),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search...',
              prefixIcon: Icon(Icons.search, size: 18),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(fontSize: 13),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 400,
          height: 450,
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final index = filtered[i];
              final pair = widget.pairs[index];
              final typeColor = _typeColors[pair.type.toLowerCase()];
              return Container(
                decoration: BoxDecoration(
                  color: typeColor?.withValues(alpha: 0.08),
                  border: Border(
                    bottom: BorderSide(
                      color:
                          typeColor?.withValues(alpha: 0.2) ??
                          Colors.grey.shade200,
                    ),
                  ),
                ),
                child: ListTile(
                  dense: true,
                  title: Text(
                    _cleanName(pair.displayName),
                    style: const TextStyle(fontSize: 13),
                  ),
                  subtitle: Text(
                    [
                      if (pair.role.isNotEmpty) pair.role,
                      if (pair.type.isNotEmpty) pair.type,
                    ].join(' | '),
                    style: TextStyle(
                      fontSize: 11,
                      color: typeColor ?? Colors.grey,
                    ),
                  ),
                  onTap: () => widget.onSelect(index),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class HexTile extends StatelessWidget {
  const HexTile({
    super.key,
    required this.radius,
    required this.activeColor,
    required this.darkColor,
    required this.active,
    required this.label,
    required this.onTap,
    this.locked = false,
  });

  final double radius;
  final Color activeColor;
  final Color darkColor;
  final bool active;
  final String label;
  final VoidCallback onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final width = radius * 2;
    final height = math.sqrt(3) * radius;
    final Color borderColor;
    final Color fillColor;
    if (locked) {
      borderColor = Color.lerp(const Color(0xFF929292), Colors.black, 0.4)!;
      fillColor = Color.lerp(const Color(0xFF929292), Colors.black, 0.5)!;
    } else if (active) {
      borderColor = Color.lerp(activeColor, Colors.black, 0.3)!;
      fillColor = activeColor;
    } else {
      final tinted = Color.lerp(const Color(0xFF929292), activeColor, 0.3)!;
      borderColor = Color.lerp(tinted, Colors.black, 0.3)!;
      fillColor = tinted;
    }
    final borderWidth = math.max(1.5, radius * (5.0 / 60.0));
    final hPad = math.max(3.0, radius * 0.3);
    final vPad = math.max(2.0, radius * (14.0 / 60.0));
    return Listener(
      onPointerDown: (_) => onTap(),
      child: CustomPaint(
        size: Size(width, height),
        painter: HexPainter(
          borderColor: borderColor,
          fillColor: fillColor,
          borderWidth: borderWidth,
        ),
        child: SizedBox(
          width: width,
          height: height,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final safeWidth = constraints.maxWidth;
                final safeHeight = constraints.maxHeight;
                final fontSize = _resolveFontSize(
                  text: label,
                  maxWidth: safeWidth,
                  maxHeight: safeHeight,
                  radius: radius,
                );
                return Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: fontSize,
                      height: 1.05,
                      shadows: const [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 2,
                          color: Colors.black,
                        ),
                        Shadow(
                          offset: Offset(-1, -1),
                          blurRadius: 2,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  double _resolveFontSize({
    required String text,
    required double maxWidth,
    required double maxHeight,
    required double radius,
  }) {
    final maxFont = math.max(6.0, radius * (16.0 / 60.0));
    final minFont = math.max(4.0, radius * (10.0 / 60.0));

    for (double size = maxFont; size >= minFont; size -= 0.25) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: size),
        ),
        maxLines: 4,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxWidth);

      if (!painter.didExceedMaxLines && painter.height <= maxHeight) {
        return size;
      }
    }

    return minFont;
  }
}

class HoverTooltip extends StatefulWidget {
  const HoverTooltip({super.key, required this.message, required this.child});

  final String message;
  final Widget child;

  @override
  State<HoverTooltip> createState() => _HoverTooltipState();
}

class _HoverTooltipState extends State<HoverTooltip> {
  OverlayEntry? _entry;

  void _show(Offset globalPosition) {
    _hide();
    if (widget.message.isEmpty) return;
    _entry = OverlayEntry(
      builder: (_) {
        final screen = MediaQuery.of(context).size;
        const maxW = 300.0;
        var left = globalPosition.dx + 12;
        var top = globalPosition.dy + 12;
        if (left + maxW > screen.width) left = globalPosition.dx - maxW - 12;
        if (top + 80 > screen.height) top = globalPosition.dy - 80;
        return Positioned(
          left: left,
          top: top,
          child: IgnorePointer(
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(4),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    widget.message,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(_entry!);
  }

  void _hide() {
    _entry?.remove();
    _entry = null;
  }

  @override
  void dispose() {
    _hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      hitTestBehavior: HitTestBehavior.translucent,
      onEnter: (e) => _show(e.position),
      onHover: (e) {
        _hide();
        _show(e.position);
      },
      onExit: (_) => _hide(),
      child: widget.child,
    );
  }
}

Path _hexPath(double w, double h) {
  return Path()
    ..moveTo(0, h * 0.5)
    ..lineTo(w * 0.25, 0)
    ..lineTo(w * 0.75, 0)
    ..lineTo(w, h * 0.5)
    ..lineTo(w * 0.75, h)
    ..lineTo(w * 0.25, h)
    ..close();
}

class HexPainter extends CustomPainter {
  HexPainter({
    required this.borderColor,
    required this.fillColor,
    required this.borderWidth,
  });

  final Color borderColor;
  final Color fillColor;
  final double borderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final outerPath = _hexPath(size.width, size.height);
    canvas.drawPath(outerPath, Paint()..color = borderColor);
    final inset = borderWidth;
    final innerW = size.width - inset * 2;
    final innerH = size.height - inset * 2;
    final innerPath = _hexPath(innerW, innerH);
    canvas.save();
    canvas.translate(inset, inset);
    canvas.drawPath(innerPath, Paint()..color = fillColor);
    canvas.restore();
  }

  @override
  bool shouldRepaint(HexPainter oldDelegate) =>
      borderColor != oldDelegate.borderColor ||
      fillColor != oldDelegate.fillColor ||
      borderWidth != oldDelegate.borderWidth;
}
