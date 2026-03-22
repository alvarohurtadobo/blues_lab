/// Application-wide constants and packaged asset paths.
class AppConstants {
  AppConstants._();

  static const String appName = "Blue's Lab";
  static const String appTagline = "For Pokémon Masters";

  /// Demo sync grid JSON (small subset including sync/dmax test nodes).
  static const String pairGridsDemoAssetPath = 'assets/data/demo/pairgrids_demo.json';

  /// Production `pairgrids.json` bundled with the app.
  static const String officialPairGridsAssetPath = 'assets/data/pairgrids.json';
}
