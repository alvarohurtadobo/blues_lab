/// Web-friendly path segments (aligned with `docs/rules.md` examples: `/`, `/login`).
abstract final class AppRoutePaths {
  static const String home = '/';
  static const String login = '/login';
}

/// [GoRoute.name] values for `context.pushNamed` / deep links.
abstract final class AppRouteNames {
  static const String home = 'home';
  static const String login = 'login';
}
