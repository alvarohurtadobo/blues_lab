/// Text label positioned on a grid tile (same role as `_setLabels` output on web).
class GridTileLabel {
  const GridTileLabel({
    required this.text,
    required this.dy,
  });

  final String text;

  /// Vertical offset in SVG/grid layout coordinates.
  final double dy;
}
