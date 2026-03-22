/// Application-wide constants and packaged asset paths.
class AppConstants {
  AppConstants._();

  static const String appName = "Blue's Lab";
  static const String appTagline = "For Pokémon Masters";

  /// Production `pairgrids.json` bundled with the app.
  static const String officialPairGridsAssetPath = 'assets/data/pairgrids.json';

  /// `pairs.json` — used for super awakening availability per grid id.
  static const String officialPairsAssetPath = 'assets/data/pairs.json';
}
