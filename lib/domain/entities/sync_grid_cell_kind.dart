/// Categoría de una casilla del sync grid en el formato de datos de PoMaTools.
///
/// El valor en JSON y en el bundle Angular compilado es la cadena [wire]
/// (`STAT`, `LEARN`, etc.). El `switch` del componente de grid en el sitio
/// original ramifica según este tipo y el campo `target` de la celda.
enum SyncGridCellKind {
  /// Mejora de estadística (objetivo tipo `STAT_00n`).
  stat('STAT'),

  /// Nodo de aprendizaje de movimiento.
  learn('LEARN'),

  /// Potenciador de movimiento (id de movimiento en `target`).
  powerup('POWERUP'),

  /// Nodo de habilidad pasiva u otra skill (id en `skills.json` vía `skill`).
  skill('SKILL'),

  /// Modificador (p. ej. target numérico como id de efecto).
  modifier('MODIFIER');

  const SyncGridCellKind(this.wire);

  /// Valor tal como aparece en `pairgrids.json` y en eventos `syncTile`.
  final String wire;

  /// Parsea la cadena del JSON; lanza [FormatException] si no es reconocida.
  static SyncGridCellKind fromWire(String s) {
    return SyncGridCellKind.values.firstWhere(
      (e) => e.wire == s,
      orElse: () => throw FormatException('SyncGridCellKind desconocido: $s'),
    );
  }
}
