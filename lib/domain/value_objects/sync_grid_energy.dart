/// Coste de energía mostrado en la UI del sync grid (misma fórmula que el sitio web).
///
/// En el bundle original: `orbs < 6 ? 0 : orbs / 12`.
double gridTileEnergyFromOrbs(int orbs) => orbs < 6 ? 0 : orbs / 12;
