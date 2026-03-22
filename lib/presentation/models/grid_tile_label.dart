/// Etiqueta de texto posicionada sobre una casilla del grid (equivalente a la salida
/// de `_setLabels` en el cliente web).
class GridTileLabel {
  const GridTileLabel({
    required this.text,
    required this.dy,
  });

  final String text;

  /// Desplazamiento vertical en coordenadas del layout SVG/grid.
  final double dy;
}
