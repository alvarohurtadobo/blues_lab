/// Web-friendly path segments (aligned with `docs/rules.md` examples: `/`, `/login`).
abstract final class AppRoutePaths {
  static const String home = '/';
  static const String login = '/login';

  /// Full-screen PoMa hex demo (no main shell / drawer).
  static const String pomaDemo = '/demo';
}

/// [GoRoute.name] values for `context.pushNamed` / deep links.
abstract final class AppRouteNames {
  static const String home = 'home';
  static const String login = 'login';
  static const String pomaDemo = 'poma_demo';
}
