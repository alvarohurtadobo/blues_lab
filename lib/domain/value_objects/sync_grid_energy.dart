/// Energy cost shown in the sync grid UI (same formula as the web app).
///
/// Original bundle: `orbs < 6 ? 0 : orbs / 12`.
double gridTileEnergyFromOrbs(int orbs) => orbs < 6 ? 0 : orbs / 12;
